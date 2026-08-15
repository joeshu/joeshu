import SwiftUI
import SwiftData

struct CalendarHomeView: View {
    @Environment(\.modelContext) private var modelContext
    let theme: PaperPalette
    @Query(sort: \CalendarEvent.startTime) private var events: [CalendarEvent]
    @State private var month = Date()
    @State private var selectedDate = Date()
    @State private var appeared = false
    @State private var isPresentingForm = false
    @State private var editingEvent: CalendarEvent?
    @State private var saveErrorMessage: String?

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
        events.filter { eventCoversDate($0, selectedDate) }
            .sorted { $0.startTime < $1.startTime }
    }

    private func eventCoversDate(_ event: CalendarEvent, _ date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        let startDay = calendar.startOfDay(for: event.startTime)
        let endDay = calendar.startOfDay(for: event.endTime)
        return day >= startDay && day <= endDay
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
                                    eventCount: selectedEvents.count,
                                    isCurrentMonth: calendar.isDate(month, equalTo: Date(), toGranularity: .month),
                                    theme: theme,
                                    onToday: { shiftMonth(0) },
                                    onPrevious: { shiftMonth(-1) },
                                    onNext: { shiftMonth(1) },
                                    onAdd: addEvent
                                )
                                MonthCard(
                                    month: month,
                                    title: monthTitle,
                                    days: days,
                                    weekdays: weekdays,
                                    events: events,
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
                                    onAdd: addEvent
                                )
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
                        CalendarContextToolbar(
                            monthTitle: monthTitle,
                            selectedDate: selectedDate,
                            eventCount: selectedEvents.count,
                            isCurrentMonth: calendar.isDate(month, equalTo: Date(), toGranularity: .month),
                            theme: theme,
                            onToday: { shiftMonth(0) },
                            onPrevious: { shiftMonth(-1) },
                            onNext: { shiftMonth(1) },
                            onAdd: addEvent
                        )
                        .padding(.horizontal, 12)
                        .padding(.top, 16)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .offset(y: appeared ? 0 : 40)
                        .zIndex(3)

                        MonthCard(
                            month: month,
                            title: monthTitle,
                            days: days,
                            weekdays: weekdays,
                            events: events,
                            selectedDate: selectedDate,
                            calendar: calendar,
                            theme: theme,
                            onSelect: selectDate
                        )
                        .padding(.leading, 12)
                        .padding(.top, 34)
                        .frame(width: max(width * 0.58, 296))
                        .offset(y: appeared ? 0 : 40)
                        .zIndex(1)

                        DayTimelineCard(
                            monthTitle: monthTitle,
                            selectedDate: selectedDate,
                            events: selectedEvents,
                            calendar: calendar,
                            theme: theme,
                            onSelect: selectDate,
                            onOpen: openEvent,
                            onAdd: addEvent
                        )
                        .padding(.top, 104)
                        .frame(width: width * 0.60)
                        .offset(x: width * 0.40, y: appeared ? 0 : 40)
                        .zIndex(2)
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
}

private struct CalendarContextToolbar: View {
    let monthTitle: String
    let selectedDate: Date
    let eventCount: Int
    let isCurrentMonth: Bool
    let theme: PaperPalette
    let onToday: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onAdd: () -> Void

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
                addButton
            }
            VStack(alignment: .leading, spacing: 12) {
                contextSummary
                HStack {
                    navigationControls
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
}

private struct CalendarBackdrop: View {
    let theme: PaperPalette

    var body: some View {
        ZStack {
            theme.backgroundGradient
            Canvas { context, size in
                let step: CGFloat = 40
                var path = Path()
                stride(from: 0, through: size.width, by: step).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                stride(from: 0, through: size.height, by: step).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(theme.paperBorder.opacity(0.22)), lineWidth: 1)
            }
            VStack {
                HStack(spacing: 12) {
                    Spacer()
                    FloatingIcon(delay: 0) { GoogleGIcon() }
                    FloatingIcon(delay: 0.5) { ExcelIcon() }
                    FloatingIcon(delay: 1.0) { OutlookIcon() }
                }
                .padding(.top, 18)
                .padding(.trailing, 14)
                Spacer()
            }
        }
    }
}

private struct FloatingIcon<Content: View>: View {
    let content: Content
    let delay: Double
    @State private var floating = false

    init(delay: Double, @ViewBuilder content: () -> Content) {
        self.delay = delay
        self.content = content()
    }

    var body: some View {
        content
            .frame(width: 40, height: 40)
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
            .offset(y: floating ? -4 : 4)
            .onAppear {
                withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(delay)) {
                    floating = true
                }
            }
    }
}

private struct GoogleGIcon: View {
    var body: some View {
        Canvas { context, size in
            let radius = size.width * 0.5
            let lineWidth = size.width * 0.26
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let ringRadius = radius - lineWidth / 2 - 1
            let segments: [(Color, Angle, Angle)] = [
                (.blue, .degrees(300), .degrees(45)),
                (.red, .degrees(45), .degrees(135)),
                (.yellow, .degrees(135), .degrees(225)),
                (.green, .degrees(225), .degrees(300))
            ]
            for (color, start, end) in segments {
                var path = Path()
                path.addArc(center: center, radius: ringRadius, startAngle: start, endAngle: end, clockwise: false)
                context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
            let bar = CGRect(x: center.x, y: center.y - lineWidth / 2, width: radius * 0.72, height: lineWidth)
            context.fill(Path(bar), with: .color(.blue))
        }
        .background(Circle().fill(.white))
    }
}

private struct ExcelIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color(hex: "1D9C4A"))
            Text("E")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

private struct OutlookIcon: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: "0F6CBD"))
            Image(systemName: "envelope.fill")
                .font(.system(size: 16))
                .foregroundStyle(.white)
        }
    }
}

private struct MonthCard: View {
    let month: Date
    let title: String
    let days: [Date]
    let weekdays: [String]
    let events: [CalendarEvent]
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
        events.filter { event in
            guard let interval = calendar.dateInterval(of: .month, for: month) else { return false }
            let start = calendar.startOfDay(for: event.startTime)
            let end = calendar.startOfDay(for: event.endTime)
            return end >= interval.start && start < interval.end
        }.count
    }

    private func monthDay(_ date: Date) -> some View {
        let inMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)
        let selected = calendar.isDate(date, inSameDayAs: selectedDate)
        let dayEvents = events.filter { eventCoversDate($0, date) }
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
                ForEach(visibleEvents) { event in
                    HStack(spacing: 3) {
                        Circle()
                            .fill(event.category.ringColor)
                            .frame(width: 4, height: 4)
                        Text(event.title)
                            .font(.caption2.weight(.medium))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 15)
                    .foregroundStyle(event.category.tagText)
                    .background(event.category.tagBackground, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                if dayEvents.count > 3 {
                    Text("+\(dayEvents.count - 3)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(theme.weakText)
                        .frame(height: 12, alignment: .leading)
                }
            }
            .frame(minHeight: 84, alignment: .top)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(date.formatted(.dateTime.month().day()))，\(dayEvents.count) 个事件")
    }

    private func eventCoversDate(_ event: CalendarEvent, _ date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        let startDay = calendar.startOfDay(for: event.startTime)
        let endDay = calendar.startOfDay(for: event.endTime)
        return day >= startDay && day <= endDay
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
                Text("\(events.count) 项")
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

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    if events.isEmpty {
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
                        ForEach(events) { event in
                            TimelineEventRow(event: event, theme: theme) {
                                onOpen(event)
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

private struct TimelineEventRow: View {
    let event: CalendarEvent
    let theme: PaperPalette
    let onToggle: () -> Void

    var body: some View {
        PressableScaleButton(action: onToggle) { pressed in
            HStack(alignment: .top, spacing: 6) {
                Text(event.startTime.formatted(.dateTime.hour().minute()))
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
                        Text("\(event.startTime.formatted(.dateTime.hour().minute())) - \(event.endTime.formatted(.dateTime.hour().minute()))")
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
        .accessibilityLabel("\(event.title)，\(event.isCompleted ? "已完成" : "未完成")")
        .accessibilityHint("打开事件编辑")
        .accessibilityAddTraits(.isButton)
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
