import Foundation

enum NoteExportStore {
    static func writeMarkdownPackage(title: String, body: String) -> URL? {
        let baseName = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "PaperTodo-note" : title
        let safeName = sanitizeFileName(baseName)
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeName)-\(UUID().uuidString.prefix(8))", isDirectory: true)
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

    private static func sanitizeFileName(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "- _"))
        let filtered = String(value.unicodeScalars.map { allowed.contains($0) ? Character(String($0)) : "-" })
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let limited = String(filtered.prefix(80))
        return limited.isEmpty ? "PaperTodo-note" : limited
    }
}
