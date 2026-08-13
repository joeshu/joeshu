import SwiftUI
import SwiftData

@main
struct PaperTodoApp: App {
    let container: ModelContainer
    @State private var settings = AppSettings()

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
                .environment(settings)
        }
        .modelContainer(container)
    }
}
