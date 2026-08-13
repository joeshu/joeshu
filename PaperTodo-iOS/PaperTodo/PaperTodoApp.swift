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
                .preferredColorScheme(settings.appearance.colorScheme)
                .task {
                    cleanupOrphanedImages()
                }
        }
        .modelContainer(container)
    }

    private func cleanupOrphanedImages() {
        let papers = (try? container.mainContext.fetch(FetchDescriptor<Paper>())) ?? []
        let referenced = papers.reduce(into: Set<String>()) { result, paper in
            if paper.kind == .note {
                result.formUnion(NoteImageStore.referencedNames(in: paper.body))
            }
        }
        NoteImageStore.cleanupOrphans(referencedNames: referenced)
    }
}

private extension AppearanceMode {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
