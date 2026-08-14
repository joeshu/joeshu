import SwiftUI
import SwiftData

struct CalendarEventFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let event: CalendarEvent?
    let onSave: () -> Void

    @State private var title: String
    @State private var date: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var category: EventCategory
    @State private var isCompleted: Bool
    @State private var note: String

    private let calendar = Calendar.current

    init(event: CalendarEvent?, date: Date, onSave: @escaping () -> Void = {}) {
        self.event = event
        self.onSave = onSave
        let day = Calendar.current.startOfDay(for: event?.startTime ?? date)
        _title = State(initialValue: event?.title ?? "")
        _date = State(initialValue: day)
        _startTime = State(initialValue: event?.startTime ?? day.addingTimeInterval(7 * 3600))
        _endTime = State(initialValue: event?.endTime ?? day.addingTimeInterval(8 * 3600))
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
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                    DatePicker("开始", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("结束", selection: $endTime, displayedComponents: .hourAndMinute)
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
                if event != nil {
                    Section {
                        Toggle("已完成", isOn: $isCompleted)
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
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let start = combined(date: date, time: startTime)
        var end = combined(date: date, time: endTime, fallback: start.addingTimeInterval(3600))
        if end <= start {
            end = start.addingTimeInterval(3600)
        }
        let target = event ?? CalendarEvent(title: title, startTime: start, endTime: end, category: category)
        target.title = title
        target.startTime = start
        target.endTime = end
        target.category = category
        target.note = note.isEmpty ? nil : note
        if event != nil {
            target.isCompleted = isCompleted
        }
        if event == nil {
            modelContext.insert(target)
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
