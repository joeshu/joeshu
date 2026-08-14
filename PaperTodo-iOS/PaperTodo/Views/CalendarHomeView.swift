import SwiftUI

struct CalendarHomeView: View {
    let papers: [Paper]
    let theme: PaperPalette
    @State private var month = Date()
    @State private var selectedDate = Date()

    private let calendar = Calendar.current
    private var monthTitle: String {
        month.formatted(.dateTime.year().month(.wide))
    }

    private var days: [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let firstWeek = calendar.dateInterval(of: .weekOfYear, for: interval.start),
              let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end),
              let lastWeek = calendar.dateInterval(of: .weekOfYear, for: lastDay) else { return [] }
        var result: [Date] = []
        var date = firstWeek.start
        while date < lastWeek.end {
            result.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? lastWeek.end
        }
        return result
    }

    private var selectedTasks: [Paper] {
        papers.filter { calendar.isDate($0.updatedAt, inSameDayAs: selectedDate) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                    Spacer()
                    Text(monthTitle).font(.headline.weight(.semibold))
                    Spacer()
                    Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
                }
                .foregroundStyle(theme.text)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("月份导航")

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                    ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                        Text(day).font(.caption2.weight(.semibold)).foregroundStyle(theme.weakText)
                    }
                    ForEach(days, id: \.self) { date in
                        dayCell(date)
                    }
                }
                .padding(12)
                .background(theme.surfaceGradient, in: RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous))

                Text(selectedDate.formatted(.dateTime.month().day()))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(theme.text)
                if selectedTasks.isEmpty {
                    Text("当天暂无纸片更新")
                        .font(.subheadline)
                        .foregroundStyle(theme.weakText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(selectedTasks) { paper in
                        NavigationLink(value: paper) {
                            HStack(spacing: 10) {
                                Image(systemName: paper.kind == .todo ? "checklist" : "note.text")
                                Text(paper.title.isEmpty ? (paper.kind == .todo ? "待办" : "笔记") : paper.title)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption)
                            }
                            .foregroundStyle(theme.text)
                            .padding(12)
                            .background(theme.surfaceGradient, in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
                        }
                    }
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
    }

    private func dayCell(_ date: Date) -> some View {
        let inMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)
        let selected = calendar.isDate(date, inSameDayAs: selectedDate)
        let count = papers.filter { calendar.isDate($0.updatedAt, inSameDayAs: date) }.count
        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline.weight(selected ? .bold : .regular))
                Circle()
                    .fill(count > 0 ? theme.active : .clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity, minHeight: 42)
            .foregroundStyle(selected ? theme.paper : (inMonth ? theme.text : theme.weakText.opacity(0.45)))
            .background(selected ? theme.active : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(date.formatted(.dateTime.month().day()))，\(count) 项")
    }

    private func shiftMonth(_ offset: Int) {
        month = calendar.date(byAdding: .month, value: offset, to: month) ?? month
        selectedDate = month
    }
}
