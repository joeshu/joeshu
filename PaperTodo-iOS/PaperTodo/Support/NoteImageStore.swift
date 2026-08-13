import SwiftUI
import UIKit

enum NoteImageStore {
    private static var assetsDir: URL {
        let dir = URL.documentsDirectory.appendingPathComponent("note-assets", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func save(image: UIImage) -> String? {
        let name = "\(UUID().uuidString).jpg"
        let url = assetsDir.appendingPathComponent(name)
        let prepared = resized(image, maxDimension: 2048)
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
        let range = NSRange(location: 0, length: (markdown as NSString).length)
        return Set(regex.matches(in: markdown, range: range).map {
            (markdown as NSString).substring(with: $0.range(at: 1))
        })
    }

    static func deleteReferenced(in markdown: String) {
        referencedNames(in: markdown).forEach(delete(named:))
    }

    private static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > maxDimension else { return image }
        let scale = maxDimension / longestSide
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }
}
