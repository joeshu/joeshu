import SwiftUI
import SwiftData

struct CalendarEventFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let event: CalendarEvent?
    let onSave: () -> Void

    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var isAllDay: Bool
    @State private var recurrenceEnabled: Bool
    @State private var recurrenceFrequency: CalendarRecurrenceFrequency
    @State private var recurrenceInterval: Int
    @State private var recurrenceEndDate: Date
    @State private var hasRecurrenceEnd: Bool
    @State private var category: EventCategory
    @State private var isCompleted: Bool
    @State private var note: String
    @State private var saveError: String?

    private let calendar = Calendar.current

    init(event: CalendarEvent?, date: Date, onSave: @escaping () -> Void = {}) {
        self.event = event
        self.onSave = onSave
        let startDay = Calendar.current.startOfDay(for: event?.startTime ?? date)
        let endDay = Calendar.current.startOfDay(for: event?.endTime ?? event?.startTime ?? date)
        _title = State(initialValue: event?.title ?? "")
        _startDate = State(initialValue: startDay)
        _endDate = State(initialValue: endDay)
        _startTime = State(initialValue: event?.startTime ?? startDay.addingTimeInterval(7 * 3600))
        _endTime = State(initialValue: event?.endTime ?? startDay.addingTimeInterval(8 * 3600))
        _isAllDay = State(initialValue: event?.isAllDay ?? false)
        let rule = event?.recurrenceRule
        _recurrenceEnabled = State(initialValue: rule != nil)
        _recurrenceFrequency = State(initialValue: rule?.frequency ?? .daily)
        _recurrenceInterval = State(initialValue: rule?.interval ?? 1)
        _hasRecurrenceEnd = State(initialValue: rule?.endDate != nil)
        _recurrenceEndDate = State(initialValue: rule?.endDate ?? startDay.addingTimeInterval(30 * 86400))
        _category = State(initialValue: event?.category ?? .daily)
        _isCompleted = State(initialValue: event?.isCompleted ?? false)
        _note = State(initialValue: event?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("事件") {
                    TextField("标题", text: $title)
                }
                Section("时间") {
                    Toggle("全天", isOn: $isAllDay)
                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                    DatePicker("结束日期", selection: $endDate, displayedComponents: .date)
                    if !isAllDay {
                        DatePicker("开始", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("结束", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                }
                Section("分类") {
                    Picker("分类", selection: $category) {
                        ForEach(EventCategory.allCases) { item in
                            Label(item.displayName, systemImage: "circle.fill")
                                .foregroundStyle(item.tagText)
                                .tag(item)
                        }
                    }
                }
                Section("重复") {
                    Toggle("重复日程", isOn: $recurrenceEnabled)
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
                if event != nil {
                    Section {
                        Toggle("已完成", isOn: $isCompleted)
                    }
                }
                if !isValidTime {
                    Section {
                    Text("结束日期和时间需晚于开始日期和时间")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                Section("备注") {
                    TextField("备注（可选）", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
                if event != nil {
                    Section {
                        Button("删除日程", role: .destructive) {
                            delete()
                        }
                    }
                }
            }
            .navigationTitle(event == nil ? "新建日程" : "编辑日程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isValidTime)
                }
            }
            .alert("无法保存", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("好", role: .cancel) { }
            } message: {
                Text(saveError ?? "请检查输入后重试。")
            }
        }
    }

    private var isValidTime: Bool {
        if isAllDay { return combined(date: endDate, time: endTime) >= combined(date: startDate, time: startTime) }
        return combined(date: endDate, time: endTime) > combined(date: startDate, time: startTime)
    }

    private func save() {
        let start = calendar.startOfDay(for: combined(date: startDate, time: startTime))
        let end = isAllDay
            ? calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: combined(date: endDate, time: endTime))) ?? start.addingTimeInterval(86400)
            : combined(date: endDate, time: endTime, fallback: start.addingTimeInterval(3600))
        guard end > start else {
            saveError = "结束时间需晚于开始时间。"
            return
        }
        let target = event ?? CalendarEvent(title: title, startTime: start, endTime: end, category: category)
        target.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        target.startTime = start
        target.endTime = end
        target.isAllDay = isAllDay
        target.recurrenceRule = recurrenceEnabled
            ? CalendarRecurrenceRule(
                frequency: recurrenceFrequency,
                interval: recurrenceInterval,
                endDate: hasRecurrenceEnd ? calendar.startOfDay(for: recurrenceEndDate) : nil,
                exceptionDates: event?.recurrenceRule?.exceptionDates ?? []
            )
            : nil
        target.category = category
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        target.note = trimmedNote.isEmpty ? nil : trimmedNote
        if event != nil {
            target.isCompleted = isCompleted
        }
        if event == nil {
            modelContext.insert(target)
        }
        do {
            try modelContext.save()
        } catch {
            saveError = "保存失败：\(error.localizedDescription)"
            return
        }
        onSave()
        dismiss()
    }

    private func delete() {
        guard let event else { return }
        modelContext.delete(event)
        onSave()
        dismiss()
    }

    private func combined(date: Date, time: Date, fallback: Date? = nil) -> Date {
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        let day = calendar.startOfDay(for: date)
        if let result = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day), result >= day {
            return result
        }
        return fallback ?? day
    }
}
