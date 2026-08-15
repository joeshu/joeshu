import Foundation
import SwiftData

enum SharedContainer {
    static let appGroupID = "group.com.papertodo"

    static func storeURL() -> URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return url.appendingPathComponent("PaperTodo.store")
        }
        return localStoreURL()
    }

    static func makeModelContainer() throws -> ModelContainer {
        let schema = Schema([Paper.self, TodoItem.self, CalendarEvent.self])
        let urls = [storeURL(), localStoreURL()]
            .reduce(into: [URL]()) { result, url in
                if !result.contains(url) {
                    result.append(url)
                }
            }

        for url in urls {
            do {
                try FileManager.default.createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                let configuration = ModelConfiguration(schema: schema, url: url)
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                continue
            }
        }

        let memoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [memoryConfiguration])
    }

    private static func localStoreURL() -> URL {
        URL.applicationSupportDirectory
            .appendingPathComponent("PaperTodo", isDirectory: true)
            .appendingPathComponent("PaperTodo.store")
    }

    static func seedCalendarEvents(in context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<CalendarEvent>())) ?? []
        guard existing.isEmpty else { return }

        let calendar = Calendar.current
        let day = calendar.startOfDay(for: Date())
        let samples: [(String, Int, Int, EventCategory)] = [
            ("晨跑", 7 * 60, 8 * 60, .personal),
            ("种花", 8 * 60, 8 * 60 + 45, .shopping),
            ("回邮件", 9 * 60, 10 * 60, .daily),
            ("和客户沟通方案", 10 * 60, 11 * 60, .work),
            ("去超市买东西", 11 * 60, 12 * 60 + 45, .shopping),
            ("写日记", 13 * 60, 15 * 60, .leisure),
            ("学习短视频拍摄", 15 * 60, 16 * 60 + 30, .work),
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
