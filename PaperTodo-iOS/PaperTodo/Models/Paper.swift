import Foundation
import SwiftData

enum PaperKind: String, Codable, CaseIterable, Identifiable {
    case todo
    case note
    var id: String { rawValue }
}

@Model
final class Paper {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var title: String
    var body: String
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date
    var isCollapsed: Bool

    @Relationship(deleteRule: .cascade, inverse: \TodoItem.paper)
    var todoItems: [TodoItem]

    var kind: PaperKind {
        get { PaperKind(rawValue: kindRaw) ?? .note }
        set { kindRaw = newValue.rawValue }
    }

    var pendingTodos: [TodoItem] {
        todoItems.filter { !$0.isDone }.sorted { $0.sortIndex < $1.sortIndex }
    }

    init(
        id: UUID = UUID(),
        kind: PaperKind = .note,
        title: String = "",
        body: String = "",
        isPinned: Bool = false
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.title = title
        self.body = body
        self.isPinned = isPinned
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isCollapsed = false
        self.todoItems = []
    }
}

@Model
final class TodoItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var isDone: Bool
    var sortIndex: Int
    var createdAt: Date
    var paper: Paper?

    init(id: UUID = UUID(), text: String = "", isDone: Bool = false, sortIndex: Int = 0) {
        self.id = id
        self.text = text
        self.isDone = isDone
        self.sortIndex = sortIndex
        self.createdAt = Date()
    }
}
