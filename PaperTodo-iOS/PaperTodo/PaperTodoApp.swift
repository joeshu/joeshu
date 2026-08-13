import SwiftUI
import SwiftData

@main
struct PaperTodoApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try SharedContainer.makeModelContainer()
        } catch {
            fatalError("无法初始化数据容器: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
