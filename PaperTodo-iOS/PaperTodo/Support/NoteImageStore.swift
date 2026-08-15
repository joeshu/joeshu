import SwiftUI
import UIKit
import ImageIO
import UniformTypeIdentifiers

enum NoteImageStore {
    static let maxInputBytes = 50 * 1024 * 1024
    private static let maxNoteBytes = 50 * 1024 * 1024
    private static let maxStoredImageBytes = 3 * 1024 * 1024
    private static let maxInputPixels = 12_000_000
    private static let maxDimension: CGFloat = 2048
    private static let jpegQuality: CGFloat = 0.76
    private static let imageRegex = try? NSRegularExpression(pattern: #"!\[[^\]]*\]\(([^)]+)\)"#)
    private static let imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 32
        cache.totalCostLimit = 32 * 2048 * 2048 * 4
        return cache
    }()

    private static let storedImageNamePattern = try? NSRegularExpression(
        pattern: #"^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[1-5][0-9A-Fa-f]{3}-[89ABab][0-9A-Fa-f]{3}-[0-9A-Fa-f]{12}\.jpg$"#
    )

    private static var assetsDir: URL {
        let dir = URL.documentsDirectory.appendingPathComponent("note-assets", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func isValidStoredImageName(_ name: String) -> Bool {
        guard let regex = storedImageNamePattern else { return false }
        let range = NSRange(location: 0, length: (name as NSString).length)
        return regex.firstMatch(in: name, range: range) != nil
    }

    static func save(image: UIImage) -> String? {
        guard let cgImage = image.cgImage else { return nil }
        return save(cgImage: cgImage)
    }

    static func save(data: Data, referencedNames: Set<String> = []) -> String? {
        guard data.count <= maxInputBytes else { return nil }
        guard let image = thumbnail(data: data, maxDimension: maxDimension) else { return nil }
        return save(cgImage: image, referencedNames: referencedNames)
    }

    private static func save(cgImage: CGImage, referencedNames: Set<String> = []) -> String? {
        let name = "\(UUID().uuidString).jpg"
        let url = assetsDir.appendingPathComponent(name)
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { return nil }
        CGImageDestinationAddImage(destination, cgImage, [
            kCGImageDestinationLossyCompressionQuality: jpegQuality
        ] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        let encodedData = output as Data
        guard encodedData.count <= maxStoredImageBytes else { return nil }
        let referencedBytes = referencedNames.reduce(0) { total, name in
            guard isValidStoredImageName(name) else { return total }
            let fileURL = assetsDir.appendingPathComponent(name)
            let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey])
            return total + (values?.fileSize ?? 0)
        }
        guard referencedBytes + encodedData.count <= maxNoteBytes else { return nil }
        do {
            try encodedData.write(to: url, options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    static func image(named: String, maxPixelSize: CGFloat = 2048) -> UIImage? {
        guard isValidStoredImageName(named) else { return nil }
        let cacheKey = named as NSString
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }
        let url = assetsDir.appendingPathComponent(named)
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions as CFDictionary) else { return nil }
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else { return nil }
        let result = UIImage(cgImage: image)
        imageCache.setObject(result, forKey: cacheKey, cost: image.bytesPerRow * image.height)
        return result
    }

    static func delete(named: String) {
        guard isValidStoredImageName(named) else { return }
        imageCache.removeObject(forKey: named as NSString)
        let url = assetsDir.appendingPathComponent(named)
        try? FileManager.default.removeItem(at: url)
    }

    static func referencedNames(in markdown: String) -> Set<String> {
        guard let regex = imageRegex else { return [] }
        var names = Set<String>()
        var inFence = false
        for line in markdown.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                inFence.toggle()
                continue
            }
            guard !inFence else { continue }
            let range = NSRange(location: 0, length: (line as NSString).length)
            for match in regex.matches(in: line, range: range) {
                let name = (line as NSString).substring(with: match.range(at: 1))
                if isValidStoredImageName(name) {
                    names.insert(name)
                }
            }
        }
        return names
    }

    static func deleteReferenced(in markdown: String, preserving preservedNames: Set<String> = []) {
        referencedNames(in: markdown)
            .subtracting(preservedNames)
            .forEach(delete(named:))
    }

    static func cleanupOrphans(referencedNames: Set<String>) {
        let validReferencedNames = referencedNames.filter(isValidStoredImageName)
        guard let files = try? FileManager.default.contentsOfDirectory(at: assetsDir, includingPropertiesForKeys: nil) else { return }
        for file in files where file.pathExtension.lowercased() == "jpg"
                && isValidStoredImageName(file.lastPathComponent)
                && !validReferencedNames.contains(file.lastPathComponent) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    static func copy(named: String, to directory: URL) -> Bool {
        guard isValidStoredImageName(named) else { return false }
        let source = assetsDir.appendingPathComponent(named)
        let destination = directory.appendingPathComponent(named)
        do {
            try FileManager.default.copyItem(at: source, to: destination)
            return true
        } catch {
            return false
        }
    }

    private static func thumbnail(data: Data, maxDimension: CGFloat) -> CGImage? {
        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else { return nil }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0,
              height > 0,
              width <= maxInputPixels / height else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return image
    }

}

actor NoteImageImportQueue {
    static let shared = NoteImageImportQueue()

    func save(data: Data) -> String? {
        NoteImageStore.save(data: data)
    }

    func save(data: Data, referencedNames: Set<String>) -> String? {
        NoteImageStore.save(data: data, referencedNames: referencedNames)
    }
}
