import Foundation

enum NoteExportStore {
    static func writeMarkdownPackage(title: String, body: String) -> URL? {
        let baseName = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "PaperTodo-note" : title
        let safeName = baseName.replacingOccurrences(of: "/", with: "-")
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(safeName, isDirectory: true)
        let markdownURL = directory.appendingPathComponent("note.md")
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Data(body.utf8).write(to: markdownURL, options: .atomic)
            for name in NoteImageStore.referencedNames(in: body) {
                _ = NoteImageStore.copy(named: name, to: directory)
            }
            return directory
        } catch {
            return nil
        }
    }
}
