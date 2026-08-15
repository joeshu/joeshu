import SwiftUI

struct TaskScheduleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hasSchedule: Bool
    @State private var start: Date
    @State private var estimatedMinutes: Int
    @State private var isAllDay: Bool
    @State private var recurrenceEnabled: Bool
    @State private var recurrenceFrequency: CalendarRecurrenceFrequency
    @State private var recurrenceInterval: Int
    @State private var recurrenceEndDate: Date
    @State private var hasRecurrenceEnd: Bool
    let item: TodoItem
    let theme: PaperPalette
    let onSave: () -> Void

    init(item: TodoItem, theme: PaperPalette, onSave: @escaping () -> Void = {}) {
        self.item = item
        self.theme = theme
        self.onSave = onSave
        _hasSchedule = State(initialValue: item.scheduledStart != nil)
        _start = State(initialValue: item.scheduledStart ?? Date())
        _estimatedMinutes = State(initialValue: item.estimatedMinutes ?? 30)
        _isAllDay = State(initialValue: item.isAllDay)
        let rule = item.recurrenceRule
        _recurrenceEnabled = State(initialValue: rule != nil)
        _recurrenceFrequency = State(initialValue: rule?.frequency ?? .daily)
        _recurrenceInterval = State(initialValue: rule?.interval ?? 1)
        _hasRecurrenceEnd = State(initialValue: rule?.endDate != nil)
        _recurrenceEndDate = State(initialValue: rule?.endDate ?? (item.scheduledStart ?? Date()).addingTimeInterval(30 * 86400))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("任务") {
                    Text(item.text)
                        .foregroundStyle(theme.text)
                }
                Section("计划") {
                    Toggle("安排到今日", isOn: $hasSchedule)
                    if hasSchedule {
                        Toggle("全天", isOn: $isAllDay)
                        DatePicker("开始时间", selection: $start, displayedComponents: [.date, .hourAndMinute])
                        if !isAllDay {
                            Picker("预计时长", selection: $estimatedMinutes) {
                                ForEach([15, 30, 45, 60, 90, 120], id: \.self) { minutes in
                                    Text("\(minutes) 分钟").tag(minutes)
                                }
                            }
                        }
                        Toggle("重复安排", isOn: $recurrenceEnabled)
                        if recurrenceEnabled {
                            Picker("频率", selection: $recurrenceFrequency) {
                                ForEach(CalendarRecurrenceFrequency.allCases) { frequency in
                                    Text(frequency.displayName).tag(frequency)
                                }
                            }
                            Stepper("每隔 \(recurrenceInterval) 个周期", value: $recurrenceInterval, in: 1...30)
                            Toggle("设置结束日期", isOn: $hasRecurrenceEnd)
                            if hasRecurrenceEnd {
                                DatePicker("结束日期", selection: $recurrenceEndDate, displayedComponents: .date)
                            }
                        }
                    }
                }
                if item.scheduledStart != nil {
                    Section {
                        Button("清除安排", role: .destructive) {
                            hasSchedule = false
                            save()
                        }
                    }
                }
            }
            .navigationTitle("安排任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        if hasSchedule {
            item.scheduledStart = start
            item.isAllDay = isAllDay
            item.estimatedMinutes = isAllDay ? nil : estimatedMinutes
            item.scheduledEnd = isAllDay
                ? Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: start))
                : Calendar.current.date(byAdding: .minute, value: estimatedMinutes, to: start)
            item.recurrenceRule = recurrenceEnabled
                ? CalendarRecurrenceRule(
                    frequency: recurrenceFrequency,
                    interval: recurrenceInterval,
                    endDate: hasRecurrenceEnd ? Calendar.current.startOfDay(for: recurrenceEndDate) : nil,
                    exceptionDates: item.recurrenceRule?.exceptionDates ?? []
                )
                : nil
        } else {
            item.scheduledStart = nil
            item.scheduledEnd = nil
            item.estimatedMinutes = nil
            item.isAllDay = false
            item.recurrenceRule = nil
        }
        onSave()
        dismiss()
    }
}
