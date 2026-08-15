import SwiftUI
import SwiftData

struct NaturalLanguageScheduleSheet: View {
    private enum CreationKind: String, CaseIterable, Identifiable {
        case todo = "待办"
        case event = "日程"

        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var input: String
    @State private var draft: NaturalLanguageScheduleDraft
    @State private var kind: CreationKind = .todo
    @State private var selectedPaper: Paper?
    let papers: [Paper]
    let referenceDate: Date
    let theme: PaperPalette
    let onCreateEvent: (NaturalLanguageScheduleDraft) -> Void
    let onCreateTodo: (NaturalLanguageScheduleDraft, Paper) -> Void

    init(input: String, papers: [Paper], referenceDate: Date, theme: PaperPalette, onCreateEvent: @escaping (NaturalLanguageScheduleDraft) -> Void, onCreateTodo: @escaping (NaturalLanguageScheduleDraft, Paper) -> Void) {
        self.papers = papers
        self.referenceDate = referenceDate
        self.theme = theme
        self.onCreateEvent = onCreateEvent
        self.onCreateTodo = onCreateTodo
        _input = State(initialValue: input)
        _draft = State(initialValue: NaturalLanguageScheduleParser.parse(input, reference: referenceDate))
        _selectedPaper = State(initialValue: papers.first(where: { $0.kind == .todo }))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("描述") {
                    TextField("例如：明天上午 9 点准备周报 30 分钟", text: $input, axis: .vertical)
                        .lineLimit(2...4)
                    Button("重新解析") { draft = NaturalLanguageScheduleParser.parse(input, reference: referenceDate) }
                }
                Section("确认") {
                    TextField("标题", text: $draft.title)
                    Picker("类型", selection: $kind) {
                        ForEach(CreationKind.allCases) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }
                    DatePicker("开始", selection: $draft.start, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("结束", selection: $draft.end, displayedComponents: [.date, .hourAndMinute])
                    Picker("分类", selection: $draft.category) {
                        ForEach(EventCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    if kind == .todo {
                        Picker("保存到", selection: $selectedPaper) {
                            ForEach(papers.filter { $0.kind == .todo }) { paper in
                                Text(paper.title.isEmpty ? "待办" : paper.title).tag(Optional(paper))
                            }
                        }
                    }
                }
            }
            .navigationTitle("确认快速创建")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        guard draft.end > draft.start else { return }
                        if kind == .todo, let selectedPaper { onCreateTodo(draft, selectedPaper) }
                        if kind == .event { onCreateEvent(draft) }
                        dismiss()
                    }
                    .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.end <= draft.start || (kind == .todo && selectedPaper == nil))
                }
            }
        }
        .presentationDetents([.large])
    }
}
