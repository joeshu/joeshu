import WidgetKit
import SwiftUI
import SwiftData

struct PaperTodoEntry: TimelineEntry {
    let date: Date
    let pendingCount: Int
    let doneCount: Int
    let todayPendingCount: Int
    let scheduledMinutes: Int
    let nextTask: String?
}

struct Provider: TimelineProvider {
    @MainActor
    func placeholder(in context: Context) -> PaperTodoEntry {
        PaperTodoEntry(date: Date(), pendingCount: 3, doneCount: 1, todayPendingCount: 2, scheduledMinutes: 60, nextTask: "整理项目文档")
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
            return PaperTodoEntry(date: Date(), pendingCount: 0, doneCount: 0, todayPendingCount: 0, scheduledMinutes: 0, nextTask: nil)
        }
        let descriptor = FetchDescriptor<TodoItem>()
        let items = (try? container.mainContext.fetch(descriptor)) ?? []
        let pending = items.filter { !$0.isDone }.count
        let done = items.count - pending
        let todayPending = items.filter { item in
            guard !$0.isDone, let start = item.scheduledStart else { return false }
            return Calendar.current.isDateInToday(start)
        }
        let scheduledMinutes = todayPending.reduce(0) { $0 + ($1.estimatedMinutes ?? 0) }
        let nextTask = todayPending
            .sorted { ($0.scheduledStart ?? .distantFuture) < ($1.scheduledStart ?? .distantFuture) }
            .first?.text
        return PaperTodoEntry(
            date: Date(),
            pendingCount: pending,
            doneCount: done,
            todayPendingCount: todayPending.count,
            scheduledMinutes: scheduledMinutes,
            nextTask: nextTask
        )
    }
}

struct PaperTodoWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    let entry: PaperTodoEntry

    private var progress: Double {
        let total = entry.pendingCount + entry.doneCount
        return total == 0 ? 0 : Double(entry.doneCount) / Double(total)
    }

    private var tint: Color {
        colorScheme == .dark
            ? Color(red: 230/255, green: 223/255, blue: 211/255)
            : Color(red: 120/255, green: 92/255, blue: 48/255)
    }

    private var paperColor: Color {
        colorScheme == .dark
            ? Color(red: 33/255, green: 31/255, blue: 28/255)
            : Color(red: 255/255, green: 249/255, blue: 234/255)
    }

    private var textColor: Color {
        colorScheme == .dark
            ? Color(red: 231/255, green: 224/255, blue: 212/255)
            : Color(red: 51/255, green: 41/255, blue: 30/255)
    }

    private var weakColor: Color {
        colorScheme == .dark
            ? Color(red: 146/255, green: 137/255, blue: 123/255)
            : Color(red: 138/255, green: 122/255, blue: 99/255)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "checklist")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint)
                Text("PaperTodo")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(textColor)
            }

            switch family {
            case .systemSmall:
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(tint.opacity(0.2), lineWidth: 6)
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(tint, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.easeOut(duration: 0.6), value: progress)
                            Text("\(entry.pendingCount)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(textColor)
                        }
                        .frame(width: 56, height: 56)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.todayPendingCount == 0 ? "今日完成" : "今日待办")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(textColor)
                            Text(entry.scheduledMinutes == 0 ? "暂无排期" : "已排 \(entry.scheduledMinutes) 分钟")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(weakColor)
                        }
                    }
                }
            default:
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(entry.pendingCount)")
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .foregroundStyle(textColor)
                            Text("待办")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(weakColor)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(entry.doneCount)")
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .foregroundStyle(textColor)
                            Text("完成")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(weakColor)
                        }
                        Spacer()
                    }
                    ProgressView(value: progress)
                        .tint(tint)
                    if let nextTask = entry.nextTask {
                        Label(nextTask, systemImage: "arrow.right.circle")
                            .font(.system(.caption2, design: .rounded).weight(.medium))
                            .foregroundStyle(textColor)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(paperColor)
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
