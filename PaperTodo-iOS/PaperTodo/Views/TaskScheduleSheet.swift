import SwiftUI

struct TaskScheduleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hasSchedule: Bool
    @State private var start: Date
    @State private var estimatedMinutes: Int
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
                        DatePicker("开始时间", selection: $start, displayedComponents: [.date, .hourAndMinute])
                        Picker("预计时长", selection: $estimatedMinutes) {
                            ForEach([15, 30, 45, 60, 90, 120], id: \.self) { minutes in
                                Text("\(minutes) 分钟").tag(minutes)
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
            item.estimatedMinutes = estimatedMinutes
            item.scheduledEnd = Calendar.current.date(byAdding: .minute, value: estimatedMinutes, to: start)
        } else {
            item.scheduledStart = nil
            item.scheduledEnd = nil
            item.estimatedMinutes = nil
        }
        onSave()
        dismiss()
    }
}
