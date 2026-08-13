import WidgetKit
import SwiftUI
import SwiftData

struct PaperTodoEntry: TimelineEntry {
    let date: Date
    let pendingCount: Int
    let doneCount: Int
}

struct Provider: TimelineProvider {
    @MainActor
    func placeholder(in context: Context) -> PaperTodoEntry {
        PaperTodoEntry(date: Date(), pendingCount: 3, doneCount: 1)
    }

    @MainActor
    func getSnapshot(in context: Context, completion: @escaping (PaperTodoEntry) -> Void) {
        completion(loadEntry())
    }

    @MainActor
    func getTimeline(in context: Context, completion: @escaping (Timeline<PaperTodoEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    @MainActor
    private func loadEntry() -> PaperTodoEntry {
        guard let container = try? SharedContainer.makeModelContainer() else {
            return PaperTodoEntry(date: Date(), pendingCount: 0, doneCount: 0)
        }
        let descriptor = FetchDescriptor<TodoItem>()
        let items = (try? container.mainContext.fetch(descriptor)) ?? []
        let pending = items.filter { !$0.isDone }.count
        let done = items.count - pending
        return PaperTodoEntry(date: Date(), pendingCount: pending, doneCount: done)
    }
}

struct PaperTodoWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PaperTodoEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checklist")
                    .font(.headline)
                Text("PaperTodo")
                    .font(.headline)
            }
            .foregroundStyle(.orange)

            switch family {
            case .systemSmall:
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(entry.pendingCount)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    Text(entry.pendingCount == 0 ? "全部完成" : "件待办")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            default:
                HStack(alignment: .firstTextBaseline, spacing: 24) {
                    statView(count: entry.pendingCount, label: "待办", color: .orange)
                    statView(count: entry.doneCount, label: "完成", color: .green)
                }
                ProgressView(value: progress)
                    .tint(.orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    private var progress: Double {
        let total = entry.pendingCount + entry.doneCount
        return total == 0 ? 0 : Double(entry.doneCount) / Double(total)
    }

    private func statView(count: Int, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(count)")
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct PaperTodoWidget: Widget {
    let kind: String = "PaperTodoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PaperTodoWidgetView(entry: entry)
        }
        .configurationDisplayName("待办概览")
        .description("显示尚未完成的待办事项数量。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
