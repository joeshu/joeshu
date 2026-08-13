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
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
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
}
