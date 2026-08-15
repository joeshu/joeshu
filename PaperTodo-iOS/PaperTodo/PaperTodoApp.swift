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
                    await ReminderNotificationService.requestAuthorization()
                    let mainContext = container.mainContext
                    await MainActor.run {
                        SharedContainer.seedCalendarEvents(in: mainContext)
                    }
                    let calendarEvents = (try? mainContext.fetch(FetchDescriptor<CalendarEvent>())) ?? []
                    let scheduledTodos = (try? mainContext.fetch(FetchDescriptor<TodoItem>())) ?? []
                    for event in calendarEvents {
                        await ReminderNotificationService.schedule(event: event)
                    }
                    for item in scheduledTodos {
                        await ReminderNotificationService.schedule(todo: item)
                    }
                    let noteBodies = (try? mainContext.fetch(FetchDescriptor<Paper>()))?
                        .filter { $0.kind == .note }
                        .map(\.body) ?? []
                    Task.detached(priority: .utility) {
                        Self.cleanupOrphanedImages(noteBodies: noteBodies)
                    }
                }
        }
        .modelContainer(container)
    }

    private nonisolated static func cleanupOrphanedImages(noteBodies: [String]) {
        let referenced = noteBodies.reduce(into: Set<String>()) { result, body in
            result.formUnion(NoteImageStore.referencedNames(in: body))
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
