import Foundation
import CoreTransferable
import UniformTypeIdentifiers

enum CalendarDateSupport {
    static func monthGridDates(for month: Date, calendar: Calendar) -> [Date] {
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

    static func weekDates(containing date: Date, calendar: Calendar) -> [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }
}

struct CalendarTimeSlot: Identifiable, Hashable {
    let date: Date
    let hour: Int

    var id: String { "\(date.timeIntervalSinceReferenceDate)-\(hour)" }

    func dateValue(using calendar: Calendar) -> Date {
        calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
    }
}

struct CalendarDropPayload: Codable, Transferable {
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
