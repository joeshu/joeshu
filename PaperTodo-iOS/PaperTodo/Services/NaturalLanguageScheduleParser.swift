import Foundation

struct NaturalLanguageScheduleDraft {
    var title: String
    var start: Date
    var end: Date
    var category: EventCategory
    var reminderMinutes: Int?
    var isAllDay: Bool
    var confidence: Double
}

enum NaturalLanguageScheduleParser {
    static func parse(_ input: String, reference: Date = Date(), calendar: Calendar = .current) -> NaturalLanguageScheduleDraft {
        let normalized = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let day = parsedDay(in: normalized, reference: reference, calendar: calendar)
        let times = parsedTimes(in: normalized)
        let start = calendar.date(bySettingHour: times.start.hour, minute: times.start.minute, second: 0, of: day) ?? day.addingTimeInterval(9 * 3600)
        let end: Date
        if let explicitEnd = times.end {
            end = calendar.date(bySettingHour: explicitEnd.hour, minute: explicitEnd.minute, second: 0, of: day) ?? start.addingTimeInterval(3600)
        } else if let duration = parsedDuration(in: normalized) {
            end = start.addingTimeInterval(duration)
        } else {
            end = start.addingTimeInterval(3600)
        }
        let title = cleanedTitle(normalized)
        return NaturalLanguageScheduleDraft(
            title: title.isEmpty ? normalized : title,
            start: start,
            end: end > start ? end : start.addingTimeInterval(3600),
            category: parsedCategory(in: normalized),
            reminderMinutes: parsedReminder(in: normalized),
            isAllDay: normalized.contains("全天"),
            confidence: title.isEmpty ? 0.35 : (times.hasTime ? 0.9 : 0.65)
        )
    }

    private static func parsedDay(in input: String, reference: Date, calendar: Calendar) -> Date {
        let base = calendar.startOfDay(for: reference)
        if input.contains("后天") { return calendar.date(byAdding: .day, value: 2, to: base) ?? base }
        if input.contains("明天") { return calendar.date(byAdding: .day, value: 1, to: base) ?? base }
        if input.contains("昨天") { return calendar.date(byAdding: .day, value: -1, to: base) ?? base }
        let pattern = #"(\d{1,2})月(\d{1,2})日?"#
        guard let match = firstMatch(pattern, in: input), let month = Int(match[1]), let day = Int(match[2]) else { return base }
        let year = calendar.component(.year, from: reference)
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? base
    }

    private static func parsedTimes(in input: String) -> (start: (hour: Int, minute: Int), end: (hour: Int, minute: Int)?, hasTime: Bool) {
        let pattern = #"(上午|下午|晚上|早上)?\s*(\d{1,2})(?:[:：](\d{1,2}))?"#
        let matches = allMatches(pattern, in: input)
        guard let first = matches.first, let rawHour = Int(first[2]) else { return ((9, 0), nil, false) }
        let firstHour = adjustedHour(rawHour, meridiem: first[1])
        let firstTime = (firstHour, Int(first[3]) ?? 0)
        guard matches.count > 1, let rawEndHour = Int(matches[1][2]) else { return (firstTime, nil, true) }
        return (firstTime, (adjustedHour(rawEndHour, meridiem: matches[1][1]), Int(matches[1][3]) ?? 0), true)
    }

    private static func parsedDuration(in input: String) -> TimeInterval? {
        guard let match = firstMatch(#"(\d+(?:\.\d+)?)\s*(小时|h|分钟|min)"#, in: input), let value = Double(match[1]) else { return nil }
        return value * (match[2].contains("小时") || match[2] == "h" ? 3600 : 60)
    }

    private static func parsedReminder(in input: String) -> Int? {
        guard let match = firstMatch(#"提前\s*(\d+)\s*(分钟|小时|天)"#, in: input), let value = Int(match[1]) else { return nil }
        return value * (match[2] == "小时" ? 60 : match[2] == "天" ? 1440 : 1)
    }

    private static func parsedCategory(in input: String) -> EventCategory {
        if input.contains("重要") || input.contains("截止") { return .important }
        if input.contains("工作") || input.contains("会议") { return .work }
        if input.contains("购物") { return .shopping }
        if input.contains("出行") || input.contains("机场") { return .travel }
        if input.contains("休息") || input.contains("娱乐") { return .leisure }
        return .daily
    }

    private static func cleanedTitle(_ input: String) -> String {
        input.replacingOccurrences(of: #"(今天|明天|后天|昨天|\d{1,2}月\d{1,2}日?)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(上午|下午|晚上|早上)?\s*\d{1,2}(?:[:：]\d{1,2})?"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"提前\s*\d+\s*(分钟|小时|天)|\d+(?:\.\d+)?\s*(小时|h|分钟|min)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "全天", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func adjustedHour(_ hour: Int, meridiem: String) -> Int {
        if (meridiem == "下午" || meridiem == "晚上") && hour < 12 { return hour + 12 }
        return hour
    }

    private static func firstMatch(_ pattern: String, in input: String) -> [String]? { allMatches(pattern, in: input).first }

    private static func allMatches(_ pattern: String, in input: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(input.startIndex..., in: input)
        return regex.matches(in: input, range: range).map { match in
            (0..<match.numberOfRanges).map { index in
                let range = match.range(at: index)
                return range.location == NSNotFound ? "" : (input as NSString).substring(with: range)
            }
        }
    }
}
