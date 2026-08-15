import Foundation
import SwiftData
import SwiftUI
import UIKit

enum PaperKind: String, Codable, CaseIterable, Identifiable {
    case todo
    case note
    var id: String { rawValue }
}

enum EventCategory: String, Codable, CaseIterable, Identifiable {
    case personal, work, errand, important, leisure, daily, shopping, travel

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .personal: return "个人"
        case .work: return "工作"
        case .errand: return "杂事"
        case .important: return "重要"
        case .leisure: return "休闲"
        case .daily: return "日常"
        case .shopping: return "购物"
        case .travel: return "出行"
        }
    }
    var tagBackground: Color {
        switch self {
        case .personal: return .adaptive(light: "FFD1DC", dark: "5C2F3C")
        case .work: return .adaptive(light: "B8D4F0", dark: "2B4560")
        case .errand: return .adaptive(light: "C8E6C9", dark: "2E4A35")
        case .important: return .adaptive(light: "FFF9C4", dark: "4A4420")
        case .leisure: return .adaptive(light: "E8DAEF", dark: "413152")
        case .daily: return .adaptive(light: "D6EAF8", dark: "2B4660")
        case .shopping: return .adaptive(light: "D4EDDA", dark: "2D4835")
        case .travel: return .adaptive(light: "FFE0B2", dark: "4A3820")
        }
    }

    var tagText: Color {
        switch self {
        case .personal: return .adaptive(light: "8B4557", dark: "FFB3C4")
        case .work: return .adaptive(light: "2E5A87", dark: "A8CDF0")
        case .errand: return .adaptive(light: "2D6A4F", dark: "A8E0BD")
        case .important: return .adaptive(light: "8B7355", dark: "F0D9A8")
        case .leisure: return .adaptive(light: "6B4C9A", dark: "D0B8EE")
        case .daily: return .adaptive(light: "4A6FA5", dark: "A8CDEE")
        case .shopping: return .adaptive(light: "4A7C59", dark: "A8DDBB")
        case .travel: return .adaptive(light: "8B6914", dark: "E8C688")
        }
    }

    var ringColor: Color {
        switch self {
        case .personal: return .adaptive(light: "FF6B8A", dark: "FF8FA7")
        case .work, .daily, .travel: return .adaptive(light: "5B9BD5", dark: "7CB8E8")
        case .errand: return .adaptive(light: "5B9BD5", dark: "7CB8E8")
        case .shopping: return .adaptive(light: "4CD964", dark: "6FE58A")
        case .important: return .adaptive(light: "FFCC00", dark: "FFD633")
        case .leisure: return .adaptive(light: "AF52DE", dark: "C77EEC")
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

enum Quadrant: String, Codable, CaseIterable, Identifiable {
    case urgentImportant
    case importantNotUrgent
    case urgentNotImportant
    case notUrgentNotImportant

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .urgentImportant: return "重要且紧急"
        case .importantNotUrgent: return "重要不紧急"
        case .urgentNotImportant: return "不重要但紧急"
        case .notUrgentNotImportant: return "不重要不紧急"
        }
    }

    var subtitle: String {
        switch self {
        case .urgentImportant: return "立即处理"
        case .importantNotUrgent: return "安排计划"
        case .urgentNotImportant: return "尽快委派"
        case .notUrgentNotImportant: return "适度安排"
        }
    }

    var color: Color {
        switch self {
        case .urgentImportant: return .adaptive(light: "4A7BF7", dark: "6C96FF")
        case .importantNotUrgent: return .adaptive(light: "5B9BD5", dark: "7CB8E8")
        case .urgentNotImportant: return .adaptive(light: "FFB04A", dark: "FFBF73")
        case .notUrgentNotImportant: return .adaptive(light: "4CD964", dark: "6FE58A")
        }
    }
}

@Model
final class TodoItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var isDone: Bool
    var sortIndex: Int
    var createdAt: Date
    var estimatedMinutes: Int?
    var scheduledStart: Date?
    var scheduledEnd: Date?
    var isAllDay: Bool
    var quadrantRaw: String = ""
    var paper: Paper?

    var quadrant: Quadrant? {
        get { Quadrant(rawValue: quadrantRaw) }
        set { quadrantRaw = newValue?.rawValue ?? "" }
    }

    init(id: UUID = UUID(), text: String = "", isDone: Bool = false, sortIndex: Int = 0) {
        self.id = id
        self.text = text
        self.isDone = isDone
        self.sortIndex = sortIndex
        self.createdAt = Date()
        self.estimatedMinutes = nil
        self.scheduledStart = nil
        self.scheduledEnd = nil
        self.isAllDay = false
    }
}

@Model
final class CalendarEvent {
    @Attribute(.unique) var id: UUID
    var title: String
    var startTime: Date
    var endTime: Date
    var isAllDay: Bool
    var categoryRaw: String
    var isCompleted: Bool
    var note: String?

    var category: EventCategory {
        get { EventCategory(rawValue: categoryRaw) ?? .daily }
        set { categoryRaw = newValue.rawValue }
    }

    init(title: String, startTime: Date, endTime: Date, category: EventCategory, note: String? = nil, isAllDay: Bool = false) {
        self.id = UUID()
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.isAllDay = isAllDay
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

    static func adaptive(light: String, dark: String) -> Color {
        Color(UIColor { trait in
            let hex = trait.userInterfaceStyle == .dark ? dark : light
            let value = UInt64(hex, radix: 16) ?? 0
            return UIColor(
                red: CGFloat((value >> 16) & 0xff) / 255,
                green: CGFloat((value >> 8) & 0xff) / 255,
                blue: CGFloat(value & 0xff) / 255,
                alpha: 1
            )
        })
    }
}
