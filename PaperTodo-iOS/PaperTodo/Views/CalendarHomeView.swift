import SwiftUI
import SwiftData

struct CalendarHomeView: View {
    @Environment(\.modelContext) private var modelContext
    let papers: [Paper]
    let theme: PaperPalette
    let onTabSelect: (CalendarTab) -> Void
    @Query(sort: \CalendarEvent.startTime) private var events: [CalendarEvent]
    @State private var month = Date()
    @State private var selectedDate = Date()
    @State private var activeTab = CalendarTab.calendar
    @State private var appeared = false

    private let calendar = Calendar.current
    private let weekdays = ["一", "二", "三", "四", "五", "六", "日"]

    private var monthTitle: String {
        month.formatted(.dateTime.month(.wide))
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
        events.filter { calendar.isDate($0.startTime, inSameDayAs: selectedDate) }
            .sorted { $0.startTime < $1.startTime }
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let width = geo.size.width
                ZStack(alignment: .topLeading) {
                    CalendarBackdrop()

                    MonthCard(
                        month: month,
                        title: monthTitle,
                        days: days,
                        weekdays: weekdays,
                        events: events,
                        selectedDate: selectedDate,
                        calendar: calendar,
                        onSelect: selectDate,
                        onShift: shiftMonth
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
                        onSelect: selectDate,
                        onToggleCompletion: toggleCompletion
                    )
                    .padding(.top, 104)
                    .frame(width: width * 0.60)
                    .offset(x: width * 0.40, y: appeared ? 0 : 40)
                    .zIndex(2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            CalendarTabBar(selection: $activeTab, onSelect: onTabSelect)
        }
        .background(Color(hex: "E8EEF5").ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.86)) { appeared = true }
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

    private func toggleCompletion(_ event: CalendarEvent) {
        event.isCompleted.toggle()
        try? modelContext.save()
    }
}

enum CalendarTab: String, CaseIterable, Identifiable {
    case calendar, apps, profile
    var id: String { rawValue }
}

private struct CalendarBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "F0F4F8"), Color(hex: "E8EEF5")], startPoint: .top, endPoint: .bottom)
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
                context.stroke(path, with: .color(Color(red: 180 / 255, green: 195 / 255, blue: 220 / 255).opacity(0.12)), lineWidth: 1)
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
    let onSelect: (Date) -> Void
    let onShift: (Int) -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(title).font(.system(size: 18, weight: .bold)).foregroundStyle(Color(hex: "1C1C1E"))
                Spacer()
                Menu {
                    Button("上个月") { onShift(-1) }
                    Button("下个月") { onShift(1) }
                    Button("回到今天") { onShift(0) }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(hex: "1C1C1E"))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "F2F2F7"), in: Circle())
                }
                .accessibilityLabel("更多选项")
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day).font(.system(size: 12, weight: .medium)).foregroundStyle(Color(hex: "C7C7CC"))
                }
                ForEach(days, id: \.self) { date in
                    monthDay(date)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 24, y: 12)
    }

    private func monthDay(_ date: Date) -> some View {
        let inMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)
        let selected = calendar.isDate(date, inSameDayAs: selectedDate)
        let dayEvents = events.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
        let visibleEvents = Array(dayEvents.prefix(3))
        return Button { onSelect(date) } label: {
            VStack(alignment: .leading, spacing: 1.5) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: selected ? 14 : (inMonth ? 14 : 13), weight: selected ? .bold : .medium))
                    .foregroundStyle(selected ? .white : (inMonth ? Color(hex: "1C1C1E") : Color(hex: "E5E5EA")))
                    .frame(width: 34, height: 34)
                    .background(selected ? Color(hex: "4A7BF7") : .clear, in: Circle())
                    .shadow(color: selected ? Color(hex: "4A7BF7").opacity(0.25) : .clear, radius: 6, y: 3)
                ForEach(visibleEvents) { event in
                    Text(event.title)
                        .font(.system(size: 9, weight: .medium))
                        .lineLimit(1)
                        .padding(.horizontal, 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 15)
                        .foregroundStyle(event.category.tagText)
                        .background(event.category.tagBackground, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                if dayEvents.count > 3 {
                    Text("+\(dayEvents.count - 3)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(hex: "C7C7CC"))
                        .frame(height: 12, alignment: .leading)
                }
            }
            .frame(height: 84, alignment: .top)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(date.formatted(.dateTime.month().day()))，\(dayEvents.count) 个事件")
    }
}

private struct DayTimelineCard: View {
    let monthTitle: String
    let selectedDate: Date
    let events: [CalendarEvent]
    let calendar: Calendar
    let onSelect: (Date) -> Void
    let onToggleCompletion: (CalendarEvent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock").font(.system(size: 22))
                VStack(alignment: .leading, spacing: 1) {
                    Text(monthTitle).font(.system(size: 11)).foregroundStyle(Color(hex: "8E8E93"))
                    Text(calendar.isDateInToday(selectedDate) ? "今天" : selectedDate.formatted(.dateTime.day())).font(.system(size: 16, weight: .bold))
                }
                Spacer()
            }
            .foregroundStyle(Color(hex: "1C1C1E"))

            weekStrip

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    if events.isEmpty {
                        Text("当天暂无日程").font(.subheadline).foregroundStyle(Color(hex: "8E8E93")).frame(maxWidth: .infinity, minHeight: 180)
                    } else {
                        ForEach(events) { event in
                            TimelineEventRow(event: event) {
                                onToggleCompletion(event)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .background(.thinMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 28, bottomTrailingRadius: 24, topTrailingRadius: 24))
        .background(Color.white.opacity(0.95), in: UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 28, bottomTrailingRadius: 24, topTrailingRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 28, x: -8, y: 8)
    }

    private var weekStrip: some View {
        let weekdayIndex = calendar.component(.weekday, from: selectedDate) - 1
        let weekStart = calendar.date(byAdding: .day, value: -weekdayIndex, to: selectedDate) ?? selectedDate
        let week = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
        let weekdayLabels = ["日", "一", "二", "三", "四", "五", "六"]
        return HStack(spacing: 3) {
            ForEach(week, id: \.self) { date in
                let selected = calendar.isDate(date, inSameDayAs: selectedDate)
                let weekdayIndex = calendar.component(.weekday, from: date) - 1
                Button { onSelect(date) } label: {
                    VStack(spacing: 3) {
                        Text(weekdayLabels[weekdayIndex]).font(.system(size: 10)).foregroundStyle(Color(hex: "C7C7CC"))
                        ZStack {
                            Circle().fill(Color(hex: "4A7BF7"))
                                .frame(width: 30, height: 30)
                                .scaleEffect(selected ? 1.0 : 0.5)
                                .opacity(selected ? 1 : 0)
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selected)
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 13, weight: selected ? .bold : .regular))
                                .foregroundStyle(selected ? .white : Color(hex: "8E8E93"))
                        }
                        .frame(width: 30, height: 30)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct TimelineEventRow: View {
    let event: CalendarEvent
    let onToggle: () -> Void

    var body: some View {
        PressableScaleButton(action: onToggle) { pressed in
            HStack(alignment: .top, spacing: 6) {
                Text(event.startTime.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "C7C7CC"))
                    .frame(width: 44, alignment: .trailing)
                    .padding(.top, 11)

                ZStack {
                    Rectangle().fill(Color(hex: "E5E5EA")).frame(width: 1)
                    Circle().stroke(event.category.ringColor, lineWidth: 2)
                        .frame(width: 10, height: 10)
                        .padding(.top, 13)
                }
                .frame(maxWidth: 1, maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(event.startTime.formatted(.dateTime.hour().minute())) - \(event.endTime.formatted(.dateTime.hour().minute()))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "5B9BD5"))
                    Text(event.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(event.isCompleted ? Color(hex: "8E8E93") : Color(hex: "1C1C1E"))
                        .strikethrough(event.isCompleted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    pressed ? Color(hex: "F5F5F7") : Color.white,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
            }
        }
        .accessibilityLabel("\(event.title)，\(event.isCompleted ? "已完成" : "未完成")")
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

private struct CalendarTabBar: View {
    @Binding var selection: CalendarTab
    let onSelect: (CalendarTab) -> Void

    var body: some View {
        HStack {
            tab(.calendar, icon: "calendar")
            tab(.apps, icon: "square.grid.2x2")
            tab(.profile, icon: "person.circle")
        }
        .padding(.horizontal, 28)
        .frame(height: 70)
        .background(.thinMaterial)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 16, y: -4)
    }

    private func tab(_ item: CalendarTab, icon: String) -> some View {
        let selected = item == selection
        return Button {
            selection = item
            onSelect(item)
        } label: {
            ZStack {
                Circle().fill(Color(hex: "4A7BF7"))
                    .frame(width: 52, height: 52)
                    .scaleEffect(selected ? 1 : 0)
                    .opacity(selected ? 1 : 0)
                    .shadow(color: Color(hex: "4A7BF7").opacity(0.3), radius: 10, y: 5)
                Image(systemName: icon)
                    .font(.system(size: selected ? 22 : 24, weight: .semibold))
                    .foregroundStyle(selected ? .white : Color(hex: "C7C7CC"))
            }
            .frame(width: 52, height: 52)
            .offset(y: selected ? -2 : 0)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selection)
        .accessibilityLabel(item == .calendar ? "日历" : (item == .apps ? "应用" : "个人中心"))
    }
}
