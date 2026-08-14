import Foundation
import SwiftData
import SwiftUI

enum PaperKind: String, Codable, CaseIterable, Identifiable {
    case todo
    case note
    var id: String { rawValue }
}

enum EventCategory: String, Codable, CaseIterable, Identifiable {
    case personal, work, errand, important, leisure, daily, shopping, travel

    var id: String { rawValue }
    var tagBackground: Color {
        switch self {
        case .personal: return Color(hex: "FFD1DC")
        case .work: return Color(hex: "B8D4F0")
        case .errand: return Color(hex: "C8E6C9")
        case .important: return Color(hex: "FFF9C4")
        case .leisure: return Color(hex: "E8DAEF")
        case .daily: return Color(hex: "D6EAF8")
        case .shopping: return Color(hex: "D4EDDA")
        case .travel: return Color(hex: "FFE0B2")
        }
    }

    var tagText: Color {
        switch self {
        case .personal: return Color(hex: "8B4557")
        case .work: return Color(hex: "2E5A87")
        case .errand: return Color(hex: "2D6A4F")
        case .important: return Color(hex: "8B7355")
        case .leisure: return Color(hex: "6B4C9A")
        case .daily: return Color(hex: "4A6FA5")
        case .shopping: return Color(hex: "4A7C59")
        case .travel: return Color(hex: "8B6914")
        }
    }

    var ringColor: Color {
        switch self {
        case .personal: return Color(hex: "FF6B8A")
        case .work, .daily, .travel: return Color(hex: "5B9BD5")
        case .errand: return Color(hex: "5B9BD5")
        case .shopping: return Color(hex: "4CD964")
        case .important: return Color(hex: "FFCC00")
        case .leisure: return Color(hex: "AF52DE")
        }
    }
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

@Model
final class CalendarEvent {
    @Attribute(.unique) var id: UUID
    var title: String
    var startTime: Date
    var endTime: Date
    var categoryRaw: String
    var isCompleted: Bool
    var note: String?

    var category: EventCategory {
        get { EventCategory(rawValue: categoryRaw) ?? .daily }
        set { categoryRaw = newValue.rawValue }
    }

    init(title: String, startTime: Date, endTime: Date, category: EventCategory, note: String? = nil) {
        self.id = UUID()
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.categoryRaw = category.rawValue
        self.isCompleted = false
        self.note = note
    }
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xff) / 255,
            green: Double((value >> 8) & 0xff) / 255,
            blue: Double(value & 0xff) / 255
        )
    }
}
