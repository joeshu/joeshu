import SwiftUI
import SwiftData
import CoreTransferable
import UniformTypeIdentifiers

private enum CalendarDisplayMode: String, CaseIterable, Identifiable {
    case month = "月视图"
    case week = "周视图"
    case agenda = "日程"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .month: return "calendar"
        case .week: return "calendar.badge.clock"
        case .agenda: return "list.bullet"
        }
    }
}

private enum CalendarCompletionFilter: String, CaseIterable, Identifiable {
    case all = "全部状态"
    case pending = "未完成"
    case completed = "已完成"

    var id: String { rawValue }
}

private enum CalendarAllDayFilter: String, CaseIterable, Identifiable {
    case all = "全天与定时"
    case timed = "仅定时"
    case allDay = "仅全天"

    var id: String { rawValue }
}

private struct CalendarFilterState {
    var eventCategories = Set(EventCategory.allCases)
    var showTodos = true
    var completion: CalendarCompletionFilter = .all
    var allDay: CalendarAllDayFilter = .all

    var isActive: Bool {
        eventCategories.count != EventCategory.allCases.count || !showTodos || completion != .all || allDay != .all
    }
}

private struct CalendarConflictSummary {
    let overlapCount: Int
    let plannedMinutes: Int

    var hasWarning: Bool { overlapCount > 0 || plannedMinutes > 480 }
    var message: String {
        if overlapCount > 0 && plannedMinutes > 480 { return "有 \(overlapCount) 处时间冲突，计划时长超过 8 小时" }
        if overlapCount > 0 { return "有 \(overlapCount) 处时间冲突" }
        return "计划时长超过 8 小时"
    }

    static func forDate(_ date: Date, events: [CalendarEvent], todos: [TodoItem], calendar: Calendar) -> Self {
        guard let day = calendar.dateInterval(of: .day, for: date) else { return Self(overlapCount: 0, plannedMinutes: 0) }
        var intervals: [(Date, Date)] = []
        for event in events where !event.isAllDay && event.covers(date, calendar: calendar) {
            let start = event.occurrenceStart(on: date, calendar: calendar) ?? event.startTime
            let end = start.addingTimeInterval(event.endTime.timeIntervalSince(event.startTime))
            intervals.append((max(start, day.start), min(end, day.end)))
        }
        for item in todos where !item.isAllDay && item.covers(date, calendar: calendar) {
            guard let originalStart = item.scheduledStart else { continue }
            let start = item.scheduledOccurrenceStart(on: date, calendar: calendar) ?? originalStart
            let duration = item.scheduledEnd?.timeIntervalSince(originalStart) ?? Double((item.estimatedMinutes ?? 30) * 60)
            intervals.append((max(start, day.start), min(start.addingTimeInterval(duration), day.end)))
        }
        let sorted = intervals.filter { $0.1 > $0.0 }.sorted { $0.0 < $1.0 }
        var activeEnd: Date?
        var overlapCount = 0
        var plannedMinutes = 0
        for interval in sorted {
            plannedMinutes += max(1, Int(interval.1.timeIntervalSince(interval.0) / 60))
            if let activeEnd, interval.0 < activeEnd { overlapCount += 1 }
            if activeEnd == nil || interval.1 > activeEnd! { activeEnd = interval.1 }
        }
        return Self(overlapCount: overlapCount, plannedMinutes: plannedMinutes)
    }
}

struct CalendarHomeView: View {
    @Environment(\.modelContext) private var modelContext
    let theme: PaperPalette
    @Query(sort: \CalendarEvent.startTime) private var events: [CalendarEvent]
    @Query private var papers: [Paper]
    @State private var month = Date()
    @State private var selectedDate = Date()
    @State private var appeared = false
    @State private var isPresentingForm = false
    @State private var editingEvent: CalendarEvent?
    @State private var schedulingTodo: TodoItem?
    @State private var saveErrorMessage: String?
    @State private var displayMode: CalendarDisplayMode = .month
    @State private var filters = CalendarFilterState()
    @State private var isPresentingNaturalLanguage = false

    private let calendar = Calendar.current
    private let weekdayLabels = ["日", "一", "二", "三", "四", "五", "六"]

    private var weekdays: [String] {
        let first = calendar.firstWeekday - 1
        return (0..<7).map { weekdayLabels[(first + $0) % 7] }
    }

    private var monthTitle: String {
        month.formatted(.dateTime.year().month(.wide))
    }

    private var days: [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let first = calendar.dateInterval(of: .weekOfYear, for: interval.start),
              let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end),
              let last = calendar.dateInterval(of: .weekOfYear, for: lastDay) else { return [] }
        var result: [Date] = []
        var date = first.start
        while date < last.end {
            result.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? last.end
        }
        return result
    }

    private var selectedEvents: [CalendarEvent] {
        filteredEvents.filter { eventCoversDate($0, selectedDate) }
            .sorted { $0.startTime < $1.startTime }
    }

    private var filteredEvents: [CalendarEvent] {
        events.filter { event in
            filters.eventCategories.contains(event.category) && matchesCompletion(event.isCompleted) && matchesAllDay(event.isAllDay)
        }
    }

    private var filteredTodos: [TodoItem] {
        guard filters.showTodos else { return [] }
        return papers.flatMap(\.todoItems).filter { matchesCompletion($0.isDone) && matchesAllDay($0.isAllDay) }
    }

    private func matchesCompletion(_ completed: Bool) -> Bool {
        switch filters.completion {
        case .all: return true
        case .pending: return !completed
        case .completed: return completed
        }
    }

    private func matchesAllDay(_ isAllDay: Bool) -> Bool {
        switch filters.allDay {
        case .all: return true
        case .timed: return !isAllDay
        case .allDay: return isAllDay
        }
    }

    private var selectedScheduledTodos: [TodoItem] {
        filteredTodos
            .filter { item in
                scheduledTodoCoversDate(item, selectedDate)
            }
            .sorted { ($0.scheduledStart ?? .distantFuture) < ($1.scheduledStart ?? .distantFuture) }
    }

    private func scheduledTodoCoversDate(_ item: TodoItem, _ date: Date) -> Bool {
        item.covers(date, calendar: calendar)
    }

    private func eventCoversDate(_ event: CalendarEvent, _ date: Date) -> Bool {
        event.covers(date, calendar: calendar)
    }

    private func eventOccurrenceStart(_ event: CalendarEvent, on date: Date) -> Date {
        event.occurrenceStart(on: date, calendar: calendar) ?? event.startTime
    }

    private func todoOccurrenceStart(_ item: TodoItem, on date: Date) -> Date {
        item.scheduledOccurrenceStart(on: date, calendar: calendar) ?? item.scheduledStart ?? date
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let width = geo.size.width
                ZStack(alignment: .topLeading) {
                    CalendarBackdrop(theme: theme)

                    if width < 720 {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 16) {
                                CalendarContextToolbar(
                                    monthTitle: monthTitle,
                                    selectedDate: selectedDate,
                                     eventCount: selectedEvents.count + selectedScheduledTodos.count,
                                    isCurrentMonth: calendar.isDate(month, equalTo: Date(), toGranularity: .month),
                                    displayMode: $displayMode,
                                    filters: $filters,
                                    theme: theme,
                                    onToday: { shiftMonth(0) },
                                    onPrevious: { shiftMonth(-1) },
                                    onNext: { shiftMonth(1) },
                                    onNaturalLanguage: { isPresentingNaturalLanguage = true },
                                    onAdd: addEvent
                                )
                                compactCalendarContent
                            }
                            .padding(.horizontal, 12)
                            .padding(.top, 20)
                            .padding(.bottom, 16)
                            .frame(maxWidth: 560)
                            .frame(maxWidth: .infinity)
                        }
                        .offset(y: appeared ? 0 : 40)
                        .animation(.spring(response: 0.6, dampingFraction: 0.86), value: appeared)
                    } else {
                        VStack(spacing: 0) {
                            CalendarContextToolbar(
                                monthTitle: monthTitle,
                                selectedDate: selectedDate,
                                    eventCount: selectedEvents.count + selectedScheduledTodos.count,
                                 isCurrentMonth: calendar.isDate(month, equalTo: Date(), toGranularity: .month),
                                 displayMode: $displayMode,
                                 filters: $filters,
                                 theme: theme,
                                onToday: { shiftMonth(0) },
                                onPrevious: { shiftMonth(-1) },
                                 onNext: { shiftMonth(1) },
                                 onNaturalLanguage: { isPresentingNaturalLanguage = true },
                                 onAdd: addEvent
                            )
                            .padding(.horizontal, 12)
                            .padding(.top, 16)

                            wideCalendarContent
                                .padding(.horizontal, 12)
                                .padding(.top, 20)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .offset(y: appeared ? 0 : 40)
                    }
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.86), value: appeared)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
        .background(theme.backgroundGradient.ignoresSafeArea())
        .sheet(isPresented: $isPresentingForm) {
            CalendarEventFormView(event: editingEvent, date: selectedDate) {
                saveEvents()
            }
        }
        .sheet(item: $schedulingTodo) { item in
            TaskScheduleSheet(item: item, theme: theme) {
                saveEvents()
            }
        }
        .sheet(isPresented: $isPresentingNaturalLanguage) {
            NaturalLanguageScheduleSheet(
                input: "",
                papers: papers,
                referenceDate: selectedDate,
                theme: theme,
                onCreateEvent: createEventFromDraft,
                onCreateTodo: createTodoFromDraft
            )
        }
        .alert("保存失败", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("好", role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? "无法保存更改。")
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.86)) { appeared = true }
        }
    }

    private func saveEvents() {
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func shiftMonth(_ offset: Int) {
        if offset == 0 {
            let today = Date()
            month = today
            selectedDate = today
        } else {
            month = calendar.date(byAdding: .month, value: offset, to: month) ?? month
            selectedDate = calendar.dateInterval(of: .month, for: month)?.start ?? month
        }
    }

    private func selectDate(_ date: Date) {
        selectedDate = date
        if !calendar.isDate(date, equalTo: month, toGranularity: .month) {
            month = date
        }
    }

    private func openEvent(_ event: CalendarEvent) {
        editingEvent = event
        isPresentingForm = true
    }

    private func addEvent() {
        editingEvent = nil
        isPresentingForm = true
    }

    private func createEventFromDraft(_ draft: NaturalLanguageScheduleDraft) {
        let event = CalendarEvent(title: draft.title, startTime: draft.start, endTime: draft.end, category: draft.category, isAllDay: draft.isAllDay)
        event.reminderMinutes = draft.reminderMinutes
        modelContext.insert(event)
        do {
            try modelContext.save()
            Task { await ReminderNotificationService.requestAuthorization(); await ReminderNotificationService.schedule(event: event) }
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func createTodoFromDraft(_ draft: NaturalLanguageScheduleDraft, _ paper: Paper) {
        let nextIndex = (paper.todoItems.map(\.sortIndex).max() ?? -1) + 1
        let item = TodoItem(text: draft.title, sortIndex: nextIndex)
        item.scheduledStart = draft.start
        item.scheduledEnd = draft.end
        item.isAllDay = draft.isAllDay
        item.estimatedMinutes = draft.isAllDay ? nil : max(1, Int(draft.end.timeIntervalSince(draft.start) / 60))
        item.reminderMinutes = draft.reminderMinutes
        item.paper = paper
        paper.updatedAt = Date()
        modelContext.insert(item)
        do {
            try modelContext.save()
            Task { await ReminderNotificationService.requestAuthorization(); await ReminderNotificationService.schedule(todo: item) }
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func toggleEventCompletion(_ event: CalendarEvent) {
        event.isCompleted.toggle()
        do {
            try modelContext.save()
            Task { await ReminderNotificationService.schedule(event: event) }
        } catch {
            event.isCompleted.toggle()
            saveErrorMessage = error.localizedDescription
        }
    }

    private func completeTodo(_ item: TodoItem) {
        item.isDone.toggle()
        item.paper?.updatedAt = Date()
        do {
            try modelContext.save()
            Task { await ReminderNotificationService.schedule(todo: item) }
        } catch {
            item.isDone.toggle()
            saveErrorMessage = error.localizedDescription
        }
    }

    private func editTodoSchedule(_ item: TodoItem) {
        schedulingTodo = item
    }

    private func moveEvent(_ event: CalendarEvent, to slot: CalendarTimeSlot) {
        let duration = event.endTime.timeIntervalSince(event.startTime)
        let oldStart = event.startTime
        let oldEnd = event.endTime
        event.startTime = slot.dateValue(using: calendar)
        event.endTime = event.startTime.addingTimeInterval(max(duration, 60))
        saveCalendarChange(onFailure: {
            event.startTime = oldStart
            event.endTime = oldEnd
        }, onSuccess: {
            Task { await ReminderNotificationService.schedule(event: event) }
        })
    }

    private func moveTodo(_ item: TodoItem, to slot: CalendarTimeSlot) {
        guard let oldStart = item.scheduledStart else { return }
        let oldEnd = item.scheduledEnd
        let duration = oldEnd?.timeIntervalSince(oldStart) ?? Double((item.estimatedMinutes ?? 30) * 60)
        item.scheduledStart = slot.dateValue(using: calendar)
        item.scheduledEnd = item.scheduledStart?.addingTimeInterval(max(duration, 60))
        saveCalendarChange(onFailure: {
            item.scheduledStart = oldStart
            item.scheduledEnd = oldEnd
        }, onSuccess: {
            Task { await ReminderNotificationService.schedule(todo: item) }
        })
    }

    private func saveCalendarChange(onFailure: () -> Void, onSuccess: () -> Void = {}) {
        do {
            try modelContext.save()
            onSuccess()
        } catch {
            onFailure()
            saveErrorMessage = error.localizedDescription
        }
    }

    @ViewBuilder
    private var compactCalendarContent: some View {
        switch displayMode {
        case .month:
            MonthCard(
                month: month,
                title: monthTitle,
                days: days,
                weekdays: weekdays,
                events: filteredEvents,
                scheduledTodos: filteredTodos,
                selectedDate: selectedDate,
                calendar: calendar,
                theme: theme,
                onSelect: selectDate
            )

            DayTimelineCard(
                monthTitle: monthTitle,
                selectedDate: selectedDate,
                events: selectedEvents,
                calendar: calendar,
                theme: theme,
                onSelect: selectDate,
                onOpen: openEvent,
                onAdd: addEvent,
                onToggleCompletion: toggleEventCompletion,
                scheduledTodos: selectedScheduledTodos,
                onCompleteTodo: completeTodo,
                onEditTodo: editTodoSchedule
            )

        case .week:
            WeekCalendarCard(
                selectedDate: selectedDate,
                events: filteredEvents,
                scheduledTodos: filteredTodos,
                calendar: calendar,
                theme: theme,
                onSelect: selectDate,
                onOpen: openEvent,
                onAdd: addEvent,
                onToggleCompletion: toggleEventCompletion,
                onToggleTodo: completeTodo,
                onEditTodo: editTodoSchedule,
                onMoveEvent: moveEvent,
                onMoveTodo: moveTodo
            )

        case .agenda:
            DayTimelineCard(
                monthTitle: monthTitle,
                selectedDate: selectedDate,
                events: selectedEvents,
                calendar: calendar,
                theme: theme,
                onSelect: selectDate,
                onOpen: openEvent,
                onAdd: addEvent,
                onToggleCompletion: toggleEventCompletion,
                scheduledTodos: selectedScheduledTodos,
                onCompleteTodo: completeTodo,
                onEditTodo: editTodoSchedule
            )
        }
    }

    @ViewBuilder
    private var wideCalendarContent: some View {
        switch displayMode {
        case .month:
            HStack(alignment: .top, spacing: 16) {
                MonthCard(
                    month: month,
                    title: monthTitle,
                    days: days,
                    weekdays: weekdays,
                    events: filteredEvents,
                    scheduledTodos: filteredTodos,
                    selectedDate: selectedDate,
                    calendar: calendar,
                    theme: theme,
                    onSelect: selectDate
                )
                .frame(maxWidth: .infinity)

                DayTimelineCard(
                    monthTitle: monthTitle,
                    selectedDate: selectedDate,
                    events: selectedEvents,
                    calendar: calendar,
                    theme: theme,
                    onSelect: selectDate,
                    onOpen: openEvent,
                    onAdd: addEvent,
                    onToggleCompletion: toggleEventCompletion,
                    scheduledTodos: selectedScheduledTodos,
                    onCompleteTodo: completeTodo,
                    onEditTodo: editTodoSchedule
                )
                .frame(maxWidth: .infinity)
            }
        case .week:
            WeekCalendarCard(
                selectedDate: selectedDate,
                events: filteredEvents,
                scheduledTodos: filteredTodos,
                calendar: calendar,
                theme: theme,
                onSelect: selectDate,
                onOpen: openEvent,
                onAdd: addEvent,
                onToggleCompletion: toggleEventCompletion,
                onToggleTodo: completeTodo,
                onEditTodo: editTodoSchedule,
                onMoveEvent: moveEvent,
                onMoveTodo: moveTodo
            )
            .frame(maxWidth: 920)

        case .agenda:
            DayTimelineCard(
                monthTitle: monthTitle,
                selectedDate: selectedDate,
                events: selectedEvents,
                calendar: calendar,
                theme: theme,
                onSelect: selectDate,
                onOpen: openEvent,
                onAdd: addEvent,
                onToggleCompletion: toggleEventCompletion,
                scheduledTodos: selectedScheduledTodos,
                onCompleteTodo: completeTodo,
                onEditTodo: editTodoSchedule
            )
            .frame(maxWidth: 620)
        }
    }
}

private struct CalendarContextToolbar: View {
    let monthTitle: String
    let selectedDate: Date
    let eventCount: Int
    let isCurrentMonth: Bool
    @Binding var displayMode: CalendarDisplayMode
    @Binding var filters: CalendarFilterState
    let theme: PaperPalette
    let onToday: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onAdd: () -> Void
    let onNaturalLanguage: () -> Void

    private var selectedDateTitle: String {
        Calendar.current.isDateInToday(selectedDate)
            ? "今天"
            : selectedDate.formatted(.dateTime.weekday(.wide).month().day())
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                contextSummary
                Spacer(minLength: 8)
                navigationControls
                viewMenu
                filterMenu
                naturalLanguageButton
                addButton
            }
            VStack(alignment: .leading, spacing: 12) {
                contextSummary
                HStack {
                    navigationControls
                    viewMenu
                    filterMenu
                    naturalLanguageButton
                    Spacer()
                    addButton
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous))
        .background(theme.surfaceGradient, in: RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                .stroke(theme.paperBorder.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: theme.shadow.opacity(0.25), radius: 14, y: 7)
    }

    private var contextSummary: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("日历")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(theme.text)
            HStack(spacing: 6) {
                Text(monthTitle)
                    .font(.subheadline.weight(.semibold))
                Text("·")
                    .foregroundStyle(theme.weakText)
                Text(selectedDateTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.accent)
            }
            .foregroundStyle(theme.weakText)
            Text(eventCount == 0 ? "当天暂无安排" : "已安排 \(eventCount) 项日程")
                .font(.caption2.weight(.medium))
                .foregroundStyle(theme.weakText)
        }
    }

    private var navigationControls: some View {
        HStack(spacing: 4) {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("上个月")

            Button(action: onToday) {
                Text("今天")
                    .font(.caption.weight(.bold))
                    .frame(minWidth: 44)
            }
            .foregroundStyle(isCurrentMonth ? theme.weakText : theme.accent)
            .background(
                (isCurrentMonth ? theme.paper : theme.accent.opacity(0.12)),
                in: Capsule()
            )
            .accessibilityLabel("回到今天")

            Button(action: onNext) {
                Image(systemName: "chevron.right")
            }
            .accessibilityLabel("下个月")
        }
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(theme.text)
        .padding(4)
        .background(theme.paper.opacity(0.58), in: Capsule())
        .overlay(Capsule().stroke(theme.paperBorder.opacity(0.6), lineWidth: 1))
    }

    private var addButton: some View {
        Button(action: onAdd) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .bold))
                .frame(width: 44, height: 44)
                .foregroundStyle(theme.paper)
                .background(theme.accent, in: Circle())
                .shadow(color: theme.accent.opacity(0.25), radius: 8, y: 4)
        }
        .accessibilityLabel("新建日程")
    }

    private var naturalLanguageButton: some View {
        Button(action: onNaturalLanguage) {
            Image(systemName: "text.badge.plus")
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 44, height: 44)
                .foregroundStyle(theme.text)
                .background(theme.paper.opacity(0.58), in: Circle())
                .overlay(Circle().stroke(theme.paperBorder.opacity(0.6), lineWidth: 1))
        }
        .accessibilityLabel("自然语言快速创建")
    }

    private var viewMenu: some View {
        Menu {
            Picker("日历视图", selection: $displayMode) {
                ForEach(CalendarDisplayMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.symbolName)
                        .tag(mode)
                }
            }
        } label: {
            Label(displayMode.rawValue, systemImage: displayMode.symbolName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.text)
                .padding(.horizontal, 10)
                .frame(minHeight: 44)
                .background(theme.paper.opacity(0.58), in: Capsule())
                .overlay(Capsule().stroke(theme.paperBorder.opacity(0.6), lineWidth: 1))
        }
        .accessibilityLabel("切换日历视图")
    }

    private var filterMenu: some View {
        Menu {
            Section("事件分类") {
                ForEach(EventCategory.allCases) { category in
                    Button {
                        if filters.eventCategories.contains(category) {
                            filters.eventCategories.remove(category)
                        } else {
                            filters.eventCategories.insert(category)
                        }
                    } label: {
                        Label(category.displayName, systemImage: filters.eventCategories.contains(category) ? "checkmark" : "circle")
                    }
                }
            }
            Toggle("显示待办", isOn: $filters.showTodos)
            Picker("完成状态", selection: $filters.completion) {
                ForEach(CalendarCompletionFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            Picker("时间类型", selection: $filters.allDay) {
                ForEach(CalendarAllDayFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            Button("重置筛选") {
                filters = CalendarFilterState()
            }
        } label: {
            Image(systemName: filters.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 44, height: 44)
                .foregroundStyle(theme.text)
                .background(theme.paper.opacity(0.58), in: Circle())
                .overlay(Circle().stroke(theme.paperBorder.opacity(0.6), lineWidth: 1))
        }
        .accessibilityLabel("筛选日历")
    }
}

private struct CalendarBackdrop: View {
    let theme: PaperPalette

    var body: some View {
        ZStack {
            theme.backgroundGradient
            Canvas { context, size in
                let step: CGFloat = 48
                var path = Path()
                stride(from: 0, through: size.width, by: step).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                stride(from: 0, through: size.height, by: step).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(theme.paperBorder.opacity(0.12)), lineWidth: 1)
            }
        }
    }
}

private struct CalendarConflictBanner: View {
    let summary: CalendarConflictSummary
    let theme: PaperPalette

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: summary.overlapCount > 0 ? "exclamationmark.triangle.fill" : "clock.badge.exclamationmark")
                .foregroundStyle(theme.accent)
            Text(summary.message)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.text)
            Spacer(minLength: 0)
            Text("\(summary.plannedMinutes) 分钟")
                .font(.caption2.weight(.medium))
                .foregroundStyle(theme.weakText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(theme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
    }
}

private struct WeekCalendarCard: View {
    let selectedDate: Date
    let events: [CalendarEvent]
    let scheduledTodos: [TodoItem]
    let calendar: Calendar
    let theme: PaperPalette
    let onSelect: (Date) -> Void
    let onOpen: (CalendarEvent) -> Void
    let onAdd: () -> Void
    let onToggleCompletion: (CalendarEvent) -> Void
    let onToggleTodo: (TodoItem) -> Void
    let onEditTodo: (TodoItem) -> Void
    let onMoveEvent: (CalendarEvent, CalendarTimeSlot) -> Void
    let onMoveTodo: (TodoItem, CalendarTimeSlot) -> Void

    private var weekDates: [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("本周安排")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.text)
                    Text(weekRangeTitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(theme.weakText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text("\(weekEventCount) 项")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.accent)
                    Text("完成 \(completedEventCount)/\(weekEventCount)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(theme.weakText)
                }
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .frame(width: 36, height: 36)
                        .foregroundStyle(theme.paper)
                        .background(theme.accent, in: Circle())
                }
                .accessibilityLabel("新建本周日程")
            }

            WeekAllDayStrip(
                weekDates: weekDates,
                events: events,
                scheduledTodos: scheduledTodos,
                calendar: calendar,
                theme: theme,
                onToggleEvent: onToggleCompletion,
                onToggleTodo: onToggleTodo
            )

            let conflict = CalendarConflictSummary.forDate(selectedDate, events: events, todos: scheduledTodos, calendar: calendar)
            if conflict.hasWarning {
                CalendarConflictBanner(summary: conflict, theme: theme)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(weekDates, id: \.self) { date in
                        weekColumn(for: date)
                    }
                }
                .padding(.bottom, 2)
            }

            WeekTimeGrid(
                weekDates: weekDates,
                events: events,
                scheduledTodos: scheduledTodos,
                calendar: calendar,
                theme: theme,
                onSelectDate: onSelect,
                onMoveEvent: onMoveEvent,
                onMoveTodo: onMoveTodo
            )
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: PaperRadius.shell, style: .continuous))
        .background(theme.surfaceGradient, in: RoundedRectangle(cornerRadius: PaperRadius.shell, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PaperRadius.shell, style: .continuous)
                .stroke(theme.paperBorder.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: theme.shadow.opacity(0.28), radius: 18, y: 9)
    }

    private var weekEventCount: Int {
        weekDates.reduce(0) { $0 + events(on: $1).count + todos(on: $1).count }
    }

    private var completedEventCount: Int {
        weekDates.reduce(0) { total, date in
            total + events(on: date).filter(\.isCompleted).count + todos(on: date).filter(\.isDone).count
        }
    }

    private var weekRangeTitle: String {
        guard let first = weekDates.first, let last = weekDates.last else { return "" }
        return "\(first.formatted(.dateTime.month().day())) - \(last.formatted(.dateTime.month().day()))"
    }

    private func weekColumn(for date: Date) -> some View {
        let dayEvents = events(on: date)
        let dayTodos = todos(on: date)
        let selected = calendar.isDate(date, inSameDayAs: selectedDate)
        let today = calendar.isDateInToday(date)
        return VStack(alignment: .leading, spacing: 8) {
            Button { onSelect(date) } label: {
                VStack(spacing: 5) {
                    Text(date.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(selected || today ? theme.accent : theme.weakText)
                    Text(date.formatted(.dateTime.day()))
                        .font(.system(size: 18, weight: selected ? .bold : .semibold, design: .rounded))
                        .foregroundStyle(selected ? theme.paper : theme.text)
                        .frame(width: 36, height: 36)
                        .background(selected ? theme.accent : (today ? theme.accent.opacity(0.12) : .clear), in: Circle())
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 64)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(date.formatted(.dateTime.month().day()))，\(dayEvents.count + dayTodos.count) 项安排")

            if dayEvents.isEmpty && dayTodos.isEmpty {
                Button {
                    onSelect(date)
                    onAdd()
                } label: {
                    Label("空闲", systemImage: "plus")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(theme.accent)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .topLeading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("在此日期新建日程")
            } else {
                ForEach(dayEvents) { event in
                    Button { onOpen(event) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(timeSummary(for: event, on: date))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(event.category.ringColor)
                            Text(event.title)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(event.isCompleted ? theme.weakText : theme.text)
                                .strikethrough(event.isCompleted)
                                .lineLimit(3)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(event.category.tagBackground.opacity(0.72), in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(event.category.ringColor)
                                .frame(width: 3)
                        }
                    }
                    .buttonStyle(.plain)
                    .draggable(CalendarDropPayload.event(event.id))
                    .contextMenu {
                        Button { onToggleCompletion(event) } label: {
                            Label(event.isCompleted ? "标记为未完成" : "标记为已完成", systemImage: event.isCompleted ? "arrow.uturn.backward" : "checkmark")
                        }
                    }
                }
                ForEach(dayTodos) { item in
                    Button { onSelect(date) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(todoTimeSummary(for: item))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(theme.active)
                            Text(item.text)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(item.isDone ? theme.weakText : theme.text)
                                .strikethrough(item.isDone)
                                .lineLimit(3)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.active.opacity(0.12), in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .draggable(CalendarDropPayload.todo(item.id))
                    .contextMenu {
                        Button { onToggleTodo(item) } label: {
                            Label(item.isDone ? "标记为未完成" : "标记为已完成", systemImage: item.isDone ? "arrow.uturn.backward" : "checkmark")
                        }
                        Button { onEditTodo(item) } label: {
                            Label("编辑排期", systemImage: "pencil")
                        }
                    }
                }
            }
        }
        .padding(8)
        .frame(width: 112, alignment: .topLeading)
        .background(selectedDateBackground(selected: selected), in: RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous))
    }

    private func events(on date: Date) -> [CalendarEvent] {
        return events.filter { !$0.isAllDay && $0.covers(date, calendar: calendar) }
        .sorted { $0.startTime < $1.startTime }
    }

    private func todos(on date: Date) -> [TodoItem] {
        return scheduledTodos.filter { !$0.isAllDay && $0.covers(date, calendar: calendar) }
        .sorted { ($0.scheduledStart ?? .distantFuture) < ($1.scheduledStart ?? .distantFuture) }
    }

    private func todoTimeSummary(for item: TodoItem) -> String {
        guard let start = item.scheduledStart else { return "已安排" }
        guard let end = item.scheduledEnd else { return "从 \(start.formatted(.dateTime.hour().minute())) 开始" }
        return "\(start.formatted(.dateTime.hour().minute())) - \(end.formatted(.dateTime.hour().minute()))"
    }

    private func timeSummary(for event: CalendarEvent, on date: Date) -> String {
        let day = calendar.startOfDay(for: date)
        let startDay = calendar.startOfDay(for: event.startTime)
        let endDay = calendar.startOfDay(for: event.endTime)
        if startDay == day && endDay == day {
            return "\(event.startTime.formatted(.dateTime.hour().minute())) - \(event.endTime.formatted(.dateTime.hour().minute()))"
        }
        if startDay < day && endDay > day { return "跨日 · 全天" }
        if startDay < day { return "延续至 \(event.endTime.formatted(.dateTime.hour().minute()))" }
        return "从 \(event.startTime.formatted(.dateTime.hour().minute())) 开始"
    }

    private func selectedDateBackground(selected: Bool) -> Color {
        selected ? theme.accent.opacity(0.1) : theme.paper.opacity(0.26)
    }
}

private struct WeekAllDayStrip: View {
    let weekDates: [Date]
    let events: [CalendarEvent]
    let scheduledTodos: [TodoItem]
    let calendar: Calendar
    let theme: PaperPalette
    let onToggleEvent: (CalendarEvent) -> Void
    let onToggleTodo: (TodoItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("全天安排")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.weakText)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 6) {
                    ForEach(weekDates, id: \.self) { date in
                        let dayEvents = allDayEvents(on: date)
                        let dayTodos = allDayTodos(on: date)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(theme.weakText)
                            ForEach(dayEvents) { event in
                                allDayChip(event.title, tint: event.category.ringColor, isDone: event.isCompleted) {
                                    onToggleEvent(event)
                                }
                            }
                            ForEach(dayTodos) { item in
                                allDayChip(item.text, tint: theme.active, isDone: item.isDone) {
                                    onToggleTodo(item)
                                }
                            }
                            if dayEvents.isEmpty && dayTodos.isEmpty {
                                Text("-")
                                    .font(.caption2)
                                    .foregroundStyle(theme.weakText.opacity(0.5))
                            }
                        }
                        .frame(width: 92, alignment: .leading)
                    }
                }
            }
        }
        .padding(10)
        .background(theme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
    }

    private func allDayEvents(on date: Date) -> [CalendarEvent] {
        events.filter { $0.isAllDay && $0.covers(date, calendar: calendar) }
    }

    private func allDayTodos(on date: Date) -> [TodoItem] {
        scheduledTodos.filter { $0.isAllDay && $0.covers(date, calendar: calendar) }
    }

    private func allDayChip(_ title: String, tint: Color, isDone: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isDone ? theme.weakText : theme.text)
                .strikethrough(isDone)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct CalendarTimeSlot: Identifiable, Hashable {
    let date: Date
    let hour: Int

    var id: String { "\(date.timeIntervalSinceReferenceDate)-\(hour)" }

    func dateValue(using calendar: Calendar) -> Date {
        calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
    }
}

private struct CalendarDropPayload: Codable, Transferable {
    enum Kind: String, Codable {
        case event
        case todo
    }

    let kind: Kind
    let id: UUID

    static func event(_ id: UUID) -> Self { Self(kind: .event, id: id) }
    static func todo(_ id: UUID) -> Self { Self(kind: .todo, id: id) }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .calendarDropPayload)
    }
}

private extension UTType {
    static let calendarDropPayload = UTType(exportedAs: "com.papertodo.calendar-drop")
}

private struct WeekTimeGrid: View {
    let weekDates: [Date]
    let events: [CalendarEvent]
    let scheduledTodos: [TodoItem]
    let calendar: Calendar
    let theme: PaperPalette
    let onSelectDate: (Date) -> Void
    let onMoveEvent: (CalendarEvent, CalendarTimeSlot) -> Void
    let onMoveTodo: (TodoItem, CalendarTimeSlot) -> Void

    private let hours = Array(7..<23)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("时间网格")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.weakText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    timeLabels
                    ForEach(weekDates, id: \.self) { date in
                        dayColumn(for: date)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.top, 4)
    }

    private var timeLabels: some View {
        VStack(spacing: 0) {
            Color.clear.frame(width: 42, height: 34)
            ForEach(hours, id: \.self) { hour in
                Text(String(format: "%02d:00", hour))
                    .font(.system(size: 9, weight: .medium).monospacedDigit())
                    .foregroundStyle(theme.weakText)
                    .frame(width: 42, height: 42, alignment: .topTrailing)
                    .padding(.trailing, 5)
            }
        }
    }

    private func dayColumn(for date: Date) -> some View {
        VStack(spacing: 0) {
            Button { onSelectDate(date) } label: {
                VStack(spacing: 2) {
                    Text(date.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.system(size: 9, weight: .semibold))
                    Text(date.formatted(.dateTime.day()))
                        .font(.system(size: 12, weight: .bold).monospacedDigit())
                }
                .foregroundStyle(calendar.isDateInToday(date) ? theme.accent : theme.weakText)
                .frame(width: 86, height: 34)
            }
            .buttonStyle(.plain)

            ForEach(hours, id: \.self) { hour in
                let slot = CalendarTimeSlot(date: date, hour: hour)
                Button { onSelectDate(slot.dateValue(using: calendar)) } label: {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(theme.paper.opacity(0.22))
                        .frame(width: 84, height: 40)
                        .overlay {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .stroke(theme.paperBorder.opacity(0.42), lineWidth: 0.5)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(date.formatted(.dateTime.month().day())) \(hour) 点时间槽")
                .dropDestination(for: CalendarDropPayload.self) { payloads, _ in
                    guard let payload = payloads.first else { return false }
                    switch payload.kind {
                    case .event:
                        guard let event = events.first(where: { $0.id == payload.id }) else { return false }
                        onMoveEvent(event, slot)
                        return true
                    case .todo:
                        guard let todo = scheduledTodos.first(where: { $0.id == payload.id }) else { return false }
                        onMoveTodo(todo, slot)
                        return true
                    }
                }
            }
        }
    }
}

private struct MonthCard: View {
    let month: Date
    let title: String
    let days: [Date]
    let weekdays: [String]
    let events: [CalendarEvent]
    let scheduledTodos: [TodoItem]
    let selectedDate: Date
    let calendar: Calendar
    let theme: PaperPalette
    let onSelect: (Date) -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.text)
                    Text("月视图")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(theme.accent)
                }
                Spacer()
                 Text("\(monthEventCount) 项")
                     .font(.caption2.weight(.semibold))
                     .foregroundStyle(theme.accent)
                     .padding(.horizontal, 9)
                     .padding(.vertical, 6)
                     .background(theme.accent.opacity(0.11), in: Capsule())
             }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(day == "日" || day == "六" ? theme.accent : theme.weakText)
                }
                ForEach(days, id: \.self) { date in
                    monthDay(date)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: PaperRadius.shell, style: .continuous))
        .background(theme.surfaceGradient, in: RoundedRectangle(cornerRadius: PaperRadius.shell, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PaperRadius.shell, style: .continuous)
                .stroke(theme.paperBorder.opacity(0.55), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: PaperRadius.shell, style: .continuous)
                .stroke(theme.accent.opacity(0.22), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .shadow(color: theme.shadow.opacity(0.35), radius: 20, y: 12)
    }

    private var monthEventCount: Int {
        let eventCount = events.filter { event in
            guard let interval = calendar.dateInterval(of: .month, for: month) else { return false }
            let start = calendar.startOfDay(for: event.startTime)
            let end = calendar.startOfDay(for: event.endTime)
            return end >= interval.start && start < interval.end
        }.count
        let todoCount = scheduledTodos.filter { item in
            guard let start = item.scheduledStart,
                  let interval = calendar.dateInterval(of: .month, for: month) else { return false }
            let end = item.scheduledEnd ?? start
            return end >= interval.start && start < interval.end
        }.count
        return eventCount + todoCount
    }

    private func monthDay(_ date: Date) -> some View {
        let inMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)
        let selected = calendar.isDate(date, inSameDayAs: selectedDate)
        let dayEvents = events.filter { eventCoversDate($0, date) }
        let dayTodos = scheduledTodos.filter { todoCoversDate($0, date) }
        let itemCount = dayEvents.count + dayTodos.count
        let visibleEvents = Array(dayEvents.prefix(3))
        return Button { onSelect(date) } label: {
            VStack(alignment: .leading, spacing: 1.5) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: selected ? 14 : (inMonth ? 14 : 13), weight: selected ? .bold : .medium))
                    .foregroundStyle(selected ? theme.paper : (inMonth ? theme.text : theme.weakText.opacity(0.5)))
                    .frame(width: 34, height: 34)
                    .background(selected ? theme.accent : .clear, in: Circle())
                    .overlay {
                        if calendar.isDateInToday(date) && !selected {
                            Circle().stroke(theme.accent, lineWidth: 1.5)
                        }
                    }
                    .shadow(color: selected ? theme.accent.opacity(0.25) : .clear, radius: 6, y: 3)
                HStack(spacing: 3) {
                    ForEach(visibleEvents) { event in
                        Circle()
                            .fill(event.category.ringColor)
                            .frame(width: 5, height: 5)
                            .accessibilityHidden(true)
                    }
                    if dayTodos.count > 0 {
                        Circle()
                            .fill(theme.active)
                            .frame(width: 5, height: 5)
                            .accessibilityHidden(true)
                    }
                    if itemCount > visibleEvents.count + (dayTodos.isEmpty ? 0 : 1) {
                        Text("+\(itemCount - visibleEvents.count - (dayTodos.isEmpty ? 0 : 1))")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(theme.weakText)
                    }
                }
                .frame(height: 16, alignment: .leading)
            }
            .frame(minHeight: 68, alignment: .top)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(date.formatted(.dateTime.month().day()))，\(itemCount) 项安排")
    }

    private func eventCoversDate(_ event: CalendarEvent, _ date: Date) -> Bool {
        event.covers(date, calendar: calendar)
    }

    private func todoCoversDate(_ item: TodoItem, _ date: Date) -> Bool {
        item.covers(date, calendar: calendar)
    }
}

private struct DayTimelineCard: View {
    let monthTitle: String
    let selectedDate: Date
    let events: [CalendarEvent]
    let calendar: Calendar
    let theme: PaperPalette
    let onSelect: (Date) -> Void
    let onOpen: (CalendarEvent) -> Void
    let onAdd: () -> Void
    let onToggleCompletion: (CalendarEvent) -> Void
    let scheduledTodos: [TodoItem]
    let onCompleteTodo: (TodoItem) -> Void
    let onEditTodo: (TodoItem) -> Void

    private enum TimelineItem: Identifiable {
        case event(CalendarEvent)
        case todo(TodoItem)
        case now(Date)

        var id: UUID {
            switch self {
            case .event(let event): event.id
            case .todo(let item): item.id
            case .now: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
            }
        }

        var startTime: Date {
            switch self {
            case .event(let event): event.startTime
            case .todo(let item): item.scheduledStart ?? .distantFuture
            case .now(let date): date
            }
        }
    }

    private var timelineItems: [TimelineItem] {
        let scheduleItems = events.filter { !$0.isAllDay }.map(TimelineItem.event)
            + scheduledTodos.filter { !$0.isAllDay }.map(TimelineItem.todo)
        guard calendar.isDateInToday(selectedDate) else {
            return scheduleItems.sorted { $0.startTime < $1.startTime }
        }
        return (scheduleItems + [.now(Date())]).sorted { $0.startTime < $1.startTime }
    }

    private var scheduleCount: Int {
        events.count + scheduledTodos.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(theme.accent)
                VStack(alignment: .leading, spacing: 1) {
                    Text(monthTitle)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(theme.weakText)
                    Text(calendar.isDateInToday(selectedDate) ? "今天" : selectedDate.formatted(.dateTime.month().day()))
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.text)
                }
                Spacer()
                Text("\(scheduleCount) 项")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.weakText)
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(theme.text)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                        .background(theme.paper.opacity(0.5), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("新建日程")
            }
            .foregroundStyle(theme.text)

            weekStrip
            AllDayTimelineStrip(
                selectedDate: selectedDate,
                events: events,
                scheduledTodos: scheduledTodos,
                calendar: calendar,
                theme: theme
            )
            TimelineStatusStrip(
                selectedDate: selectedDate,
                events: events,
                scheduledTodos: scheduledTodos,
                theme: theme
            )
            let conflict = CalendarConflictSummary.forDate(selectedDate, events: events, todos: scheduledTodos, calendar: calendar)
            if conflict.hasWarning {
                CalendarConflictBanner(summary: conflict, theme: theme)
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    if timelineItems.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 28, weight: .light))
                                .foregroundStyle(theme.accent)
                            Text("当天暂无日程")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.text)
                            Button("新建日程", action: onAdd)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(theme.accent)
                        }
                        .frame(maxWidth: .infinity, minHeight: 180)
                    } else {
                        ForEach(timelineItems) { item in
                            switch item {
                            case .event(let event):
                                TimelineEventRow(
                                    event: event,
                                    selectedDate: selectedDate,
                                    theme: theme,
                                    onOpen: { onOpen(event) },
                                    onToggleCompletion: { onToggleCompletion(event) }
                                )
                            case .todo(let todo):
                                ScheduledTodoTimelineRow(
                                    item: todo,
                                    selectedDate: selectedDate,
                                    theme: theme,
                                    onComplete: { onCompleteTodo(todo) },
                                    onEdit: { onEditTodo(todo) }
                                )
                            case .now(let date):
                                TimelineNowMarker(date: date, theme: theme)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .background(.thinMaterial, in: UnevenRoundedRectangle(topLeadingRadius: PaperRadius.shell, bottomLeadingRadius: PaperRadius.shell, bottomTrailingRadius: PaperRadius.block, topTrailingRadius: PaperRadius.block))
        .background(theme.surfaceGradient, in: UnevenRoundedRectangle(topLeadingRadius: PaperRadius.shell, bottomLeadingRadius: PaperRadius.shell, bottomTrailingRadius: PaperRadius.block, topTrailingRadius: PaperRadius.block))
        .overlay(
            UnevenRoundedRectangle(topLeadingRadius: PaperRadius.shell, bottomLeadingRadius: PaperRadius.shell, bottomTrailingRadius: PaperRadius.block, topTrailingRadius: PaperRadius.block)
                .stroke(theme.paperBorder.opacity(0.55), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            UnevenRoundedRectangle(topLeadingRadius: PaperRadius.shell, bottomLeadingRadius: PaperRadius.shell, bottomTrailingRadius: PaperRadius.block, topTrailingRadius: PaperRadius.block)
                .stroke(theme.accent.opacity(0.3), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .shadow(color: theme.shadow.opacity(0.4), radius: 24, x: -8, y: 8)
    }

    private var weekStrip: some View {
        let firstWeekday = calendar.firstWeekday
        let weekdayIndex = (calendar.component(.weekday, from: selectedDate) - firstWeekday + 7) % 7
        let weekStart = calendar.date(byAdding: .day, value: -weekdayIndex, to: selectedDate) ?? selectedDate
        let week = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
        let labels = ["日", "一", "二", "三", "四", "五", "六"]
        let orderedLabels = (0..<7).map { labels[(firstWeekday - 1 + $0) % 7] }
        return HStack(spacing: 3) {
            ForEach(week, id: \.self) { date in
                let selected = calendar.isDate(date, inSameDayAs: selectedDate)
                let weekdayIndex = (calendar.component(.weekday, from: date) - firstWeekday + 7) % 7
                Button { onSelect(date) } label: {
                    VStack(spacing: 3) {
                        Text(orderedLabels[weekdayIndex])
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(weekdayIndex == 0 || weekdayIndex == 6 ? theme.accent : theme.weakText)
                        ZStack {
                            Circle().fill(theme.accent)
                                .frame(width: 30, height: 30)
                                .scaleEffect(selected ? 1.0 : 0.5)
                                .opacity(selected ? 1 : 0)
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selected)
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 13, weight: selected ? .bold : .regular))
                                .foregroundStyle(selected ? theme.paper : theme.text)
                        }
                        .frame(width: 30, height: 30)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct AllDayTimelineStrip: View {
    let selectedDate: Date
    let events: [CalendarEvent]
    let scheduledTodos: [TodoItem]
    let calendar: Calendar
    let theme: PaperPalette

    private var allDayEvents: [CalendarEvent] {
        let day = calendar.startOfDay(for: selectedDate)
        return events.filter { event in
            event.isAllDay && day >= calendar.startOfDay(for: event.startTime) && day < calendar.startOfDay(for: event.endTime)
        }
    }

    private var allDayTodos: [TodoItem] {
        let day = calendar.startOfDay(for: selectedDate)
        return scheduledTodos.filter { item in
            guard item.isAllDay, let start = item.scheduledStart, let end = item.scheduledEnd else { return false }
            return day >= calendar.startOfDay(for: start) && day < calendar.startOfDay(for: end)
        }
    }

    var body: some View {
        if allDayEvents.isEmpty && allDayTodos.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("全天")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(theme.weakText)
                ForEach(allDayEvents) { event in
                    Label(event.title, systemImage: "calendar")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(event.isCompleted ? theme.weakText : event.category.tagText)
                        .strikethrough(event.isCompleted)
                }
                ForEach(allDayTodos) { item in
                    Label(item.text, systemImage: "checklist")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(item.isDone ? theme.weakText : theme.active)
                        .strikethrough(item.isDone)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
        }
    }
}

private struct TimelineEventRow: View {
    let event: CalendarEvent
    let selectedDate: Date
    let theme: PaperPalette
    let onOpen: () -> Void
    let onToggleCompletion: () -> Void

    private var timeSummary: String {
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let occurrenceStart = event.occurrenceStart(on: selectedDate, calendar: calendar) ?? event.startTime
        let occurrenceEnd = occurrenceStart.addingTimeInterval(event.endTime.timeIntervalSince(event.startTime))
        let startDay = calendar.startOfDay(for: occurrenceStart)
        let endDay = calendar.startOfDay(for: occurrenceEnd)
        if startDay == selectedDay && endDay == selectedDay {
            return "\(occurrenceStart.formatted(.dateTime.hour().minute())) - \(occurrenceEnd.formatted(.dateTime.hour().minute()))"
        }
        if startDay < selectedDay && endDay > selectedDay {
            return "跨日 · 全天"
        }
        if startDay < selectedDay {
            return "延续至 \(occurrenceEnd.formatted(.dateTime.hour().minute()))"
        }
        return "从 \(occurrenceStart.formatted(.dateTime.hour().minute())) 开始"
    }

    var body: some View {
        PressableScaleButton(action: onOpen) { pressed in
            HStack(alignment: .top, spacing: 6) {
                Text((event.occurrenceStart(on: selectedDate) ?? event.startTime).formatted(.dateTime.hour().minute()))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(event.category.ringColor)
                    .frame(width: 44, alignment: .trailing)
                    .padding(.top, 11)

                ZStack {
                    Rectangle().fill(event.category.ringColor.opacity(0.42)).frame(width: 1.5)
                    Circle().stroke(event.category.ringColor, lineWidth: 2)
                        .frame(width: 10, height: 10)
                        .padding(.top, 13)
                }
                .frame(maxWidth: 1, maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(timeSummary)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.timeColor)
                        Text(event.category.displayName)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(event.category.tagText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(event.category.tagBackground, in: Capsule())
                    }
                    Text(event.title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(event.isCompleted ? theme.weakText : event.category.tagText)
                        .strikethrough(event.isCompleted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    pressed ? event.category.tagBackground.opacity(0.32) : theme.paper.opacity(0.45),
                    in: RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                        .stroke(theme.paperBorder.opacity(0.5), lineWidth: 1)
                )
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(event.category.ringColor)
                        .frame(width: 3)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                .shadow(color: theme.shadow.opacity(0.3), radius: 8, y: 4)
            }
        }
        .contextMenu {
            Button(action: onToggleCompletion) {
                Label(event.isCompleted ? "标记为未完成" : "标记为已完成", systemImage: event.isCompleted ? "arrow.uturn.backward" : "checkmark")
            }
            Button(action: onOpen) {
                Label("编辑日程", systemImage: "pencil")
            }
        }
        .accessibilityLabel("\(event.title)，\(event.isCompleted ? "已完成" : "未完成")")
        .accessibilityHint("打开事件编辑")
        .accessibilityAddTraits(.isButton)
    }
}

private struct ScheduledTodoTimelineRow: View {
    let item: TodoItem
    let selectedDate: Date
    let theme: PaperPalette
    let onComplete: () -> Void
    let onEdit: () -> Void

    private var timeSummary: String {
        guard let start = item.scheduledStart else { return "已安排" }
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let occurrenceStart = item.scheduledOccurrenceStart(on: selectedDate, calendar: calendar) ?? start
        let duration = item.scheduledEnd?.timeIntervalSince(start) ?? Double((item.estimatedMinutes ?? 30) * 60)
        let end = occurrenceStart.addingTimeInterval(duration)
        let startDay = calendar.startOfDay(for: occurrenceStart)
        let endDay = calendar.startOfDay(for: end)
        if startDay < selectedDay && endDay > selectedDay {
            return "跨日 · 全天"
        }
        if startDay < selectedDay {
            return "延续至 \(end.formatted(.dateTime.hour().minute()))"
        }
        guard item.scheduledEnd != nil else {
            return "从 \(occurrenceStart.formatted(.dateTime.hour().minute())) 开始"
        }
        if startDay == selectedDay && endDay > selectedDay {
            return "从 \(occurrenceStart.formatted(.dateTime.hour().minute())) 开始"
        }
        return "\(occurrenceStart.formatted(.dateTime.hour().minute())) - \(end.formatted(.dateTime.hour().minute()))"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text((item.scheduledOccurrenceStart(on: selectedDate) ?? item.scheduledStart)?.formatted(.dateTime.hour().minute()) ?? "")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(theme.active)
                .frame(width: 44, alignment: .trailing)
                .padding(.top, 11)

            ZStack {
                Rectangle().fill(theme.active.opacity(0.42)).frame(width: 1.5)
                Circle().stroke(theme.active, lineWidth: 2)
                    .frame(width: 10, height: 10)
                    .padding(.top, 13)
            }
            .frame(maxWidth: 1, maxHeight: .infinity)

            Button(action: onComplete) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeSummary)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.timeColor)
                    Text(item.text)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.text)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.active.opacity(0.1), in: RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(theme.active)
                        .frame(width: 3)
                        .padding(.vertical, 8)
                }
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(action: onComplete) {
                    Label("标记为已完成", systemImage: "checkmark")
                }
                Button(action: onEdit) {
                    Label("编辑排期", systemImage: "pencil")
                }
            }
        }
        .accessibilityLabel("待办，\(item.text)，\(timeSummary)")
        .accessibilityHint("点击标记为已完成")
    }
}

private struct TimelineNowMarker: View {
    let date: Date
    let theme: PaperPalette

    var body: some View {
        HStack(spacing: 8) {
            Text("现在")
                .font(.caption2.weight(.bold))
                .foregroundStyle(theme.accent)
                .frame(width: 44, alignment: .trailing)
            Capsule()
                .fill(theme.accent)
                .frame(width: 8, height: 8)
            Rectangle()
                .fill(theme.accent.opacity(0.7))
                .frame(height: 1.5)
            Text(date.formatted(.dateTime.hour().minute()))
                .font(.caption2.weight(.semibold).monospacedDigit())
                .foregroundStyle(theme.accent)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("当前时间 \(date.formatted(.dateTime.hour().minute()))")
    }
}

private struct TimelineStatusStrip: View {
    let selectedDate: Date
    let events: [CalendarEvent]
    let scheduledTodos: [TodoItem]
    let theme: PaperPalette

    private var completedCount: Int {
        events.filter(\.isCompleted).count + scheduledTodos.filter(\.isDone).count
    }

    private var totalCount: Int {
        events.count + scheduledTodos.count
    }

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            HStack(spacing: 10) {
                Image(systemName: Calendar.current.isDateInToday(selectedDate) ? "clock.fill" : "checkmark.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.accent)

                if Calendar.current.isDateInToday(selectedDate) {
                    Text("现在 \(context.date.formatted(.dateTime.hour().minute()))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.text)
                } else {
                    Text("当天进度")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.text)
                }

                Spacer()

                Text(totalCount == 0 ? "暂无安排" : "日程 \(completedCount)/\(totalCount)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.weakText)

                if totalCount > 0 {
                    ProgressView(value: Double(completedCount), total: Double(totalCount))
                        .tint(theme.accent)
                        .frame(width: 52)
                        .accessibilityLabel("日程完成进度")
                        .accessibilityValue("已完成 \(completedCount) 项，共 \(totalCount) 项")
                }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 34)
            .background(theme.accent.opacity(0.08), in: Capsule())
            .overlay(Capsule().stroke(theme.accent.opacity(0.14), lineWidth: 1))
        }
    }
}

private struct PressableScaleButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: (Bool) -> Label
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            label(pressed)
                .scaleEffect(pressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed)
    }
}
