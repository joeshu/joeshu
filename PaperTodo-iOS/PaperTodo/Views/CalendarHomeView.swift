import SwiftUI
import SwiftData

struct CalendarHomeView: View {
    let papers: [Paper]
    let theme: PaperPalette
    @Query(sort: \CalendarEvent.startTime) private var events: [CalendarEvent]
    @State private var month = Date()
    @State private var selectedDate = Date()
    @State private var activeTab = CalendarTab.calendar
    @State private var appeared = false

    private let calendar = Calendar.current
    private let weekdays = ["一", "二", "三", "四", "五", "六", "日"]
    private let timelineHours = [7, 8, 9, 10, 11, 13, 15, 17, 19]

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
        events.filter { calendar.isDate($0.startTime, inSameDayAs: selectedDate) }
            .sorted { $0.startTime < $1.startTime }
    }

    var body: some View {
        VStack(spacing: 0) {
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
                    onSelect: { selectedDate = $0 },
                    onShift: shiftMonth
                )
                .padding(.leading, 12)
                .padding(.top, 28)
                .frame(width: 275)
                .offset(y: appeared ? 0 : 40)
                .zIndex(1)

                DayTimelineCard(
                    monthTitle: monthTitle,
                    selectedDate: selectedDate,
                    events: selectedEvents,
                    hours: timelineHours,
                    calendar: calendar,
                    onSelect: { selectedDate = $0 }
                )
                .padding(.top, 92)
                .offset(x: 142, y: appeared ? 0 : 40)
                .zIndex(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            CalendarTabBar(selection: $activeTab)
        }
        .background(Color(hex: "E8EEF5").ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.86)) { appeared = true }
        }
    }

    private func shiftMonth(_ offset: Int) {
        month = calendar.date(byAdding: .month, value: offset, to: month) ?? month
        selectedDate = month
    }
}

private enum CalendarTab: String, CaseIterable, Identifiable {
    case calendar, apps, profile
    var id: String { rawValue }
}

private struct CalendarBackdrop: View {
    @State private var phase = false

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
            HStack(spacing: 13) {
                FloatingAppIcon(label: "G", color: .white, foreground: .blue, offset: phase ? -4 : 4)
                FloatingAppIcon(label: "E", color: Color(hex: "E7F5E8"), foreground: .green, offset: phase ? 4 : -4)
                FloatingAppIcon(label: "O", color: Color(hex: "E5F0FA"), foreground: Color(hex: "2F80C0"), offset: phase ? -3 : 3)
            }
            .padding(.top, 16)
            .padding(.leading, 220)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) { phase.toggle() }
        }
    }
}

private struct FloatingAppIcon: View {
    let label: String
    let color: Color
    let foreground: Color
    let offset: CGFloat

    var body: some View {
        Text(label)
            .font(.system(size: 19, weight: .bold, design: .rounded))
            .foregroundStyle(foreground)
            .frame(width: 42, height: 42)
            .background(color, in: Circle())
            .shadow(color: .black.opacity(0.08), radius: 9, y: 4)
            .offset(y: offset)
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
                Button { onShift(1) } label: {
                    Image(systemName: "ellipsis").font(.caption.weight(.bold)).frame(width: 28, height: 28)
                }
                .foregroundStyle(Color(hex: "1C1C1E"))
                .background(Color(hex: "F2F2F7"), in: Circle())
                .accessibilityLabel("切换月份")
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
        return Button { onSelect(date) } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: selected ? 14 : 13, weight: selected ? .bold : .medium))
                    .foregroundStyle(selected ? .white : (inMonth ? Color(hex: "1C1C1E") : Color(hex: "E5E5EA")))
                    .frame(maxWidth: .infinity, minHeight: 22)
                    .background(selected ? Color(hex: "4A7BF7") : .clear, in: Circle())
                ForEach(Array(dayEvents.prefix(2))) { event in
                    Text(event.title)
                        .font(.system(size: 7, weight: .medium))
                        .lineLimit(1)
                        .padding(.horizontal, 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(event.category.tagText)
                        .background(event.category.tagBackground, in: RoundedRectangle(cornerRadius: 3, style: .continuous))
                }
            }
            .frame(height: 42, alignment: .top)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(date.formatted(.dateTime.month().day()))，\(dayEvents.count) 个事件")
    }
}

private struct DayTimelineCard: View {
    let monthTitle: String
    let selectedDate: Date
    let events: [CalendarEvent]
    let hours: [Int]
    let calendar: Calendar
    let onSelect: (Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock").font(.title3)
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
                            timelineEvent(event)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .frame(width: 300)
        .background(.thinMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 28, bottomTrailingRadius: 24, topTrailingRadius: 24))
        .background(Color.white.opacity(0.95), in: UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 28, bottomTrailingRadius: 24, topTrailingRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 28, x: -8, y: 8)
    }

    private var weekStrip: some View {
        let week = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0 - 3, to: selectedDate) }
        return HStack(spacing: 3) {
            ForEach(week, id: \.self) { date in
                Button { onSelect(date) } label: {
                    VStack(spacing: 3) {
                        Text(date.formatted(.dateTime.weekday(.abbreviated))).font(.system(size: 10)).foregroundStyle(Color(hex: "C7C7CC"))
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 13, weight: calendar.isDate(date, inSameDayAs: selectedDate) ? .bold : .regular))
                            .foregroundStyle(calendar.isDate(date, inSameDayAs: selectedDate) ? .white : Color(hex: "8E8E93"))
                            .frame(width: 30, height: 30)
                            .background(calendar.isDate(date, inSameDayAs: selectedDate) ? Color(hex: "4A7BF7") : .clear, in: Circle())
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func timelineEvent(_ event: CalendarEvent) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(spacing: 4) {
                Text(event.startTime.formatted(.dateTime.hour().minute())).font(.system(size: 11)).foregroundStyle(Color(hex: "C7C7CC"))
                Circle().stroke(event.category.ringColor, lineWidth: 2).frame(width: 10, height: 10)
            }
            Rectangle().fill(Color(hex: "E5E5EA")).frame(width: 1).padding(.top, 3)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(event.startTime.formatted(.dateTime.hour().minute())) - \(event.endTime.formatted(.dateTime.hour().minute()))")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(Color(hex: "5B9BD5"))
                Text(event.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "1C1C1E"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
        }
    }
}

private struct CalendarTabBar: View {
    @Binding var selection: CalendarTab

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
        Button { selection = item } label: {
            Image(systemName: icon)
                .font(.system(size: item == selection ? 22 : 24, weight: .semibold))
                .foregroundStyle(item == selection ? .white : Color(hex: "C7C7CC"))
                .frame(width: item == selection ? 52 : 44, height: item == selection ? 52 : 44)
                .background(item == selection ? Color(hex: "4A7BF7") : .clear, in: Circle())
                .shadow(color: item == selection ? Color(hex: "4A7BF7").opacity(0.3) : .clear, radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(item == .calendar ? "日历" : (item == .apps ? "应用" : "个人中心"))
    }
}
