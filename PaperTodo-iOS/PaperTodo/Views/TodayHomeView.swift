import SwiftUI
import SwiftData
import WidgetKit

struct TodayHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CalendarEvent.startTime) private var events: [CalendarEvent]
    @State private var schedulingItem: TodoItem?
    @State private var isReviewPresented = false
    let papers: [Paper]
    let theme: PaperPalette
    let onQuickCapture: () -> Void

    private let calendar = Calendar.current

    private var today: Date {
        calendar.startOfDay(for: Date())
    }

    private var pendingTodos: [TodoItem] {
        papers.flatMap(\.todoItems)
            .filter { !$0.isDone }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var scheduledTodos: [TodoItem] {
        pendingTodos.filter { item in
            guard let start = item.scheduledStart else { return false }
            return calendar.isDate(start, inSameDayAs: today)
        }
            .sorted { ($0.scheduledStart ?? .distantFuture) < ($1.scheduledStart ?? .distantFuture) }
    }

    private var unscheduledTodos: [TodoItem] {
        pendingTodos.filter { $0.scheduledStart == nil }
    }

    private var scheduledMinutes: Int {
        scheduledTodos.reduce(0) { total, item in
            total + (item.estimatedMinutes ?? 0)
        }
    }

    private var todayEvents: [CalendarEvent] {
        events.filter { event in
            let day = calendar.startOfDay(for: event.startTime)
            let endDay = calendar.startOfDay(for: event.endTime)
            return today >= day && today <= endDay
        }
    }

    private var completedCount: Int {
        papers.flatMap(\.todoItems).filter(\.isDone).count
    }

    private var totalCount: Int {
        papers.flatMap(\.todoItems).count
    }

    private var completion: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                planningCard
                if !todayEvents.isEmpty || !scheduledTodos.isEmpty {
                    timelineSection
                }
                taskSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 28)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(theme.backgroundGradient.ignoresSafeArea())
        .sheet(isPresented: $isReviewPresented) {
            DailyReviewSheet(
                completedCount: completedCount,
                totalCount: totalCount,
                scheduledMinutes: scheduledMinutes,
                pendingCount: pendingTodos.count,
                theme: theme
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(today.formatted(.dateTime.weekday(.wide)))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.active)
                    Text(today.formatted(.dateTime.month(.wide).day()))
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.text)
                }
                Spacer()
                Image(systemName: completion >= 1 ? "checkmark.seal.fill" : "sun.max.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(completion >= 1 ? theme.active : theme.accent)
            }
            Text(pendingTodos.isEmpty ? "今天的清单已经清空" : "还有 \(pendingTodos.count) 项值得专注")
                .font(.subheadline)
                .foregroundStyle(theme.weakText)
        }
    }

    private var planningCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("今日进度", systemImage: "chart.bar.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.text)
                Spacer()
                Text("\(completedCount)/\(totalCount)")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(theme.active)
            }
            ProgressView(value: completion)
                .tint(theme.active)
            HStack(spacing: 14) {
                Label("已安排 \(scheduledMinutes) 分钟", systemImage: "clock")
                Label("未安排 \(unscheduledTodos.count) 项", systemImage: "tray")
            }
            .font(.caption)
            .foregroundStyle(theme.weakText)
            HStack(spacing: 10) {
                Button(action: onQuickCapture) {
                    Label("快速记录", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TodayActionButton(theme: theme, filled: true))

                Button {
                    onQuickCapture()
                } label: {
                    Label("添加任务", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TodayActionButton(theme: theme, filled: false))

                Button {
                    isReviewPresented = true
                } label: {
                    Label("今日回顾", systemImage: "checkmark.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TodayActionButton(theme: theme, filled: false))
            }
        }
        .padding(16)
        .background(theme.surfaceGradient, in: RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous).stroke(theme.paperBorder.opacity(0.6), lineWidth: 1))
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("日程", symbol: "calendar")
            ForEach(todayEvents) { event in
                HStack(spacing: 12) {
                    Circle()
                        .fill(event.category.ringColor)
                        .frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(event.title)
                            .font(.body.weight(.medium))
                            .foregroundStyle(theme.text)
                        Text("\(event.startTime.formatted(date: .omitted, time: .shortened)) - \(event.endTime.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(theme.weakText)
                    }
                    Spacer()
                    Text(event.category.displayName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(event.category.tagText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(event.category.tagBackground, in: Capsule())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(theme.paper.opacity(0.52), in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
            }
            ForEach(scheduledTodos) { item in
                Button {
                    complete(item)
                } label: {
                    HStack(spacing: 12) {
                        AnimatedCheckCircle(isDone: false, tint: theme.active)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.text)
                                .font(.body.weight(.medium))
                                .foregroundStyle(theme.text)
                                .multilineTextAlignment(.leading)
                            Text(scheduleText(for: item))
                                .font(.caption)
                                .foregroundStyle(theme.weakText)
                        }
                        Spacer()
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.weakText)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(theme.active.opacity(0.1), in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
                .contextMenu {
                    Button {
                        schedulingItem = item
                    } label: {
                        Label("调整时间", systemImage: "clock.badge.plus")
                    }
                }
            }
        }
    }

    private var taskSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("未完成任务", symbol: "checklist")
            if unscheduledTodos.isEmpty {
                Text("没有待处理任务，给自己留一点空白。")
                    .font(.subheadline)
                    .foregroundStyle(theme.weakText)
                    .padding(.vertical, 12)
            } else {
                ForEach(unscheduledTodos) { item in
                    Button {
                        item.isDone = true
                        item.paper?.updatedAt = Date()
                        try? modelContext.save()
                    } label: {
                        HStack(spacing: 12) {
                            AnimatedCheckCircle(isDone: false, tint: theme.active)
                            Text(item.text)
                                .font(.body)
                                .foregroundStyle(theme.text)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(theme.weakText)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(theme.paper.opacity(0.52), in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
                    .contextMenu {
                        Button {
                            schedulingItem = item
                        } label: {
                            Label("安排时间", systemImage: "clock.badge.plus")
                        }
                    }
                }
            }
        }
        .sheet(item: $schedulingItem) { item in
            TaskScheduleSheet(item: item, theme: theme) {
                try? modelContext.save()
            }
        }
    }

    private func sectionTitle(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.headline.weight(.semibold))
            .foregroundStyle(theme.text)
    }

    private func scheduleText(for item: TodoItem) -> String {
        guard let start = item.scheduledStart else { return "未安排时间" }
        let time = start.formatted(date: .omitted, time: .shortened)
        if let minutes = item.estimatedMinutes, minutes > 0 {
            return "今天 \(time) · 预计 \(minutes) 分钟"
        }
        return "今天 \(time)"
    }

    private func complete(_ item: TodoItem) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            item.isDone = true
            item.paper?.updatedAt = Date()
            try? modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

}

private struct TodayActionButton: ButtonStyle {
    let theme: PaperPalette
    let filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(filled ? .white : theme.active)
            .padding(.vertical, 11)
            .background(filled ? AnyShapeStyle(theme.accentGradient) : AnyShapeStyle(theme.paper.opacity(0.7)), in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
            .overlay {
                if !filled {
                    RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous)
                        .stroke(theme.active.opacity(0.35), lineWidth: 1)
                }
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct QuickCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var kind: PaperKind = .todo
    let papers: [Paper]
    let theme: PaperPalette
    let onSave: (PaperKind, String) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                TextField("写下一件事或一个想法", text: $text, axis: .vertical)
                    .font(.system(.title3, design: .rounded))
                    .lineLimit(3...6)
                    .padding(14)
                    .background(theme.paper.opacity(0.7), in: RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous).stroke(theme.paperBorder.opacity(0.7), lineWidth: 1))

                Picker("类型", selection: $kind) {
                    Text("任务").tag(PaperKind.todo)
                    Text("笔记").tag(PaperKind.note)
                }
                .pickerStyle(.segmented)

                HStack(spacing: 10) {
                    Image(systemName: kind == .todo ? "tray" : "note.text")
                        .foregroundStyle(theme.active)
                    Text(kind == .todo ? "保存到收件箱，稍后再安排" : "创建一张新的笔记纸片")
                        .font(.subheadline)
                        .foregroundStyle(theme.weakText)
                }
                Spacer()
            }
            .padding(20)
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("快速记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(kind, text)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct DailyReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let completedCount: Int
    let totalCount: Int
    let scheduledMinutes: Int
    let pendingCount: Int
    let theme: PaperPalette

    private var completion: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("今天完成了多少")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.text)
                    Text(completion == 1 ? "计划完成，给自己留一点余地。" : "保留未完成项，明天继续推进。")
                        .font(.subheadline)
                        .foregroundStyle(theme.weakText)
                }

                HStack(spacing: 10) {
                    reviewMetric("已完成", value: "\(completedCount)", symbol: "checkmark.circle.fill")
                    reviewMetric("剩余", value: "\(pendingCount)", symbol: "circle.dashed")
                    reviewMetric("排期", value: "\(scheduledMinutes)m", symbol: "clock.fill")
                }

                ProgressView(value: completion)
                    .tint(theme.active)
                Text("完成率 \(Int(completion * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.active)
                Spacer()
            }
            .padding(20)
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("今日回顾")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func reviewMetric(_ label: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(theme.active)
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(theme.text)
            Text(label)
                .font(.caption)
                .foregroundStyle(theme.weakText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(theme.paper.opacity(0.55), in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
    }
}
