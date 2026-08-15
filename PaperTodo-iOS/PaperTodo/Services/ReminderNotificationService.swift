import Foundation
import UserNotifications

enum ReminderNotificationService {
    private static let horizonDays = 365

    static func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func schedule(event: CalendarEvent) async {
        await remove(for: event.id)
        guard let minutes = event.reminderMinutes, !event.isCompleted else { return }
        let starts = event.recurrenceStarts(in: schedulingInterval(from: event.startTime), calendar: .current)
        let occurrenceStarts = starts.isEmpty ? [event.startTime] : starts
        for start in occurrenceStarts {
            await addNotification(
                id: identifier(for: event.id, occurrence: start),
                title: event.title,
                body: "日程即将开始",
                date: start.addingTimeInterval(TimeInterval(-minutes * 60))
            )
        }
    }

    static func schedule(todo: TodoItem) async {
        await remove(for: todo.id)
        guard let start = todo.scheduledStart, let minutes = todo.reminderMinutes, !todo.isDone else { return }
        let starts = todo.recurrenceStarts(in: schedulingInterval(from: start), calendar: .current)
        let occurrenceStarts = starts.isEmpty ? [start] : starts
        for occurrence in occurrenceStarts {
            await addNotification(
                id: identifier(for: todo.id, occurrence: occurrence),
                title: todo.text,
                body: "待办即将开始",
                date: occurrence.addingTimeInterval(TimeInterval(-minutes * 60))
            )
        }
    }

    static func remove(for id: UUID) async {
        let center = UNUserNotificationCenter.current()
        let ids = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix("papertodo-reminder-\(id.uuidString)-") }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func schedulingInterval(from start: Date, calendar: Calendar = .current) -> DateInterval {
        let end = calendar.date(byAdding: .day, value: horizonDays, to: start) ?? start.addingTimeInterval(365 * 86400)
        return DateInterval(start: start, end: end)
    }

    private static func identifier(for id: UUID, occurrence: Date) -> String {
        "papertodo-reminder-\(id.uuidString)-\(Int(occurrence.timeIntervalSince1970))"
    }

    private static func addNotification(id: String, title: String, body: String, date: Date) async {
        guard date > Date() else { return }
        let components = Calendar.current.dateComponents([.calendar, .year, .month, .day, .hour, .minute], from: date)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
        _ = try? await UNUserNotificationCenter.current().add(request)
    }
}
