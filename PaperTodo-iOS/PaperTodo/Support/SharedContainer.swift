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
        let schema = Schema([Paper.self, TodoItem.self])
        let configuration = ModelConfiguration(schema: schema, url: storeURL())
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
