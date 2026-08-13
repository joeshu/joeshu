import SwiftUI
import UIKit
import ImageIO

enum NoteImageStore {
    private static var assetsDir: URL {
        let dir = URL.documentsDirectory.appendingPathComponent("note-assets", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func save(image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 1) else { return nil }
        return save(data: data)
    }

    static func save(data: Data) -> String? {
        let name = "\(UUID().uuidString).jpg"
        let url = assetsDir.appendingPathComponent(name)
        guard let prepared = thumbnail(data: data, maxDimension: 2048) else { return nil }
        guard let data = prepared.jpegData(compressionQuality: 0.78) else { return nil }
        do {
            try data.write(to: url)
            return name
        } catch {
            return nil
        }
    }

    static func image(named: String) -> UIImage? {
        let url = assetsDir.appendingPathComponent(named)
        return UIImage(contentsOfFile: url.path)
    }

    static func delete(named: String) {
        let url = assetsDir.appendingPathComponent(named)
        try? FileManager.default.removeItem(at: url)
    }

    static func referencedNames(in markdown: String) -> Set<String> {
        let pattern = #"!\[[^\]]*\]\(([^)]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
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
                names.insert((line as NSString).substring(with: match.range(at: 1)))
            }
        }
        return names
    }

    static func deleteReferenced(in markdown: String) {
        referencedNames(in: markdown).forEach(delete(named:))
    }

    static func cleanupOrphans(referencedNames: Set<String>) {
        guard let files = try? FileManager.default.contentsOfDirectory(at: assetsDir, includingPropertiesForKeys: nil) else { return }
        for file in files where file.pathExtension.lowercased() == "jpg" && !referencedNames.contains(file.lastPathComponent) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    static func copy(named: String, to directory: URL) -> Bool {
        let source = assetsDir.appendingPathComponent(named)
        let destination = directory.appendingPathComponent(named)
        do {
            try FileManager.default.copyItem(at: source, to: destination)
            return true
        } catch {
            return false
        }
    }

    private static func thumbnail(data: Data, maxDimension: CGFloat) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }

}

actor NoteImageImportQueue {
    static let shared = NoteImageImportQueue()

    func save(data: Data) -> String? {
        NoteImageStore.save(data: data)
    }
}
