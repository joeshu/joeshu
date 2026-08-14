import Foundation
import SwiftData

enum SharedContainer {
    static let appGroupID = "group.com.papertodo"

    static func storeURL() -> URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return url.appendingPathComponent("PaperTodo.store")
        }
        return URL.documentsDirectory.appendingPathComponent("PaperTodo.store")
    }

    static func makeModelContainer() throws -> ModelContainer {
        let schema = Schema([Paper.self, TodoItem.self, CalendarEvent.self])
        let configuration = ModelConfiguration(schema: schema, url: storeURL())
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func seedCalendarEvents(in context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<CalendarEvent>())) ?? []
        guard existing.isEmpty else { return }

        let calendar = Calendar.current
        let day = calendar.startOfDay(for: Date())
        let samples: [(String, Int, Int, EventCategory)] = [
            ("晨跑", 7 * 60, 8 * 60, .daily),
            ("种花", 8 * 60, 8 * 60 + 45, .personal),
            ("回邮件", 9 * 60, 10 * 60, .work),
            ("和客户沟通方案", 10 * 60, 11 * 60, .work),
            ("去超市买东西", 11 * 60, 12 * 60 + 45, .shopping),
            ("写日记", 13 * 60, 15 * 60, .personal),
            ("学习短视频拍摄", 15 * 60, 16 * 60 + 30, .leisure),
            ("订机票", 17 * 60, 17 * 60 + 45, .travel),
            ("拿快递", 19 * 60, 20 * 60, .errand)
        ]

        for sample in samples {
            guard let start = calendar.date(byAdding: .minute, value: sample.1, to: day),
                  let end = calendar.date(byAdding: .minute, value: sample.2, to: day) else { continue }
            context.insert(CalendarEvent(title: sample.0, startTime: start, endTime: end, category: sample.3))
        }
        try? context.save()
    }
}
