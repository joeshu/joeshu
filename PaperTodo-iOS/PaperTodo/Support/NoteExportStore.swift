import Foundation

enum NoteExportStore {
    static func writeMarkdown(title: String, body: String) -> URL? {
        let baseName = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "PaperTodo-note" : title
        let safeName = baseName.replacingOccurrences(of: "/", with: "-") + ".md"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(safeName)
        do {
            try Data(body.utf8).write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
