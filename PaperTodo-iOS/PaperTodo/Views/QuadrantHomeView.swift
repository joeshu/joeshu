import SwiftUI
import SwiftData

struct QuadrantHomeView: View {
    let papers: [Paper]
    let theme: PaperPalette
    @Environment(\.modelContext) private var modelContext

    @State private var editorConfig: QuadrantEditorConfig?
    @State private var saveErrorMessage: String?

    private var allItems: [TodoItem] {
        papers.flatMap(\.todoItems)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PaperSpacing.section) {
                VStack(alignment: .leading, spacing: PaperSpacing.micro) {
                    Text("四象限")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.text)
                    Text("按重要性和紧急性整理待办")
                        .font(PaperTypography.metadata)
                        .foregroundStyle(theme.weakText)
                }
                .padding(.horizontal, 4)

                HStack(spacing: PaperSpacing.compact) {
                    Label("重要", systemImage: "star")
                    Label("紧急", systemImage: "bolt")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.weakText)
                .padding(.horizontal, PaperSpacing.control)
                .frame(minHeight: 36)
                .background(theme.paper.opacity(0.46), in: Capsule())
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 240), spacing: 12)], spacing: 12) {
                    ForEach(Quadrant.allCases) { quadrant in
                        quadrantCard(quadrant)
                    }
                }
            }
            .padding(PaperSpacing.content)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottomTrailing) {
            Menu {
                ForEach(Quadrant.allCases) { quadrant in
                    Button {
                        presentAddTask(in: quadrant)
                    } label: {
                        Label("新增到\(quadrant.displayName)", systemImage: symbolName(for: quadrant))
                    }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(theme.onAccent)
                    .frame(width: 52, height: 52)
                    .background(theme.brandAction, in: Circle())
                    .shadow(color: theme.shadow.opacity(0.22), radius: 12, y: 6)
            }
            .accessibilityLabel("新增四象限任务")
            .padding(.trailing, PaperSpacing.content)
            .padding(.bottom, PaperSpacing.content)
        }
        .sheet(item: $editorConfig) { config in
            QuadrantTaskEditorSheet(title: config.title, initialText: config.initialText, onSubmit: config.handler)
        }
        .alert("保存失败", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("好", role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? "无法保存当前修改。")
        }
    }

    private func quadrantCard(_ quadrant: Quadrant) -> some View {
        let tasks = allItems.filter { !$0.isDone && resolvedQuadrant(of: $0) == quadrant }
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: PaperSpacing.compact) {
                RoundedRectangle(cornerRadius: PaperRadius.small, style: .continuous)
                    .fill(quadrant.color)
                    .frame(width: 4, height: 42)
                VStack(alignment: .leading, spacing: 1) {
                    Text(quadrant.displayName).font(.subheadline.weight(.bold))
                    Text(quadrant.subtitle)
                        .font(PaperTypography.metadata)
                        .foregroundStyle(theme.weakText)
                }
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(quadrant.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(quadrant.color.opacity(0.12), in: Capsule())
            }
            .foregroundStyle(theme.text)
            if tasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("暂无任务").font(.caption).foregroundStyle(theme.weakText)
                    Button {
                        presentAddTask(in: quadrant)
                    } label: {
                        Label("新增任务", systemImage: "plus")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(PaperSecondaryButtonStyle(palette: theme))
                    .tint(quadrant.color)
                    .accessibilityLabel("在\(quadrant.displayName)新增任务")
                }
            } else {
                ForEach(tasks.prefix(5)) { item in
                    taskRow(item, quadrant: quadrant)
                }
                if tasks.count > 5 {
                    Text("+\(tasks.count - 5) 更多任务")
                        .font(.caption2)
                        .foregroundStyle(theme.weakText)
                }
            }
        }
        .padding(PaperSpacing.content)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .background(theme.paper.opacity(0.44), in: RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                .stroke(quadrant.color.opacity(0.32), lineWidth: 1)
        }
        .shadow(color: theme.shadow.opacity(0.1), radius: PaperElevation.raised.shadowRadius, y: PaperElevation.raised.shadowY)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(quadrant.displayName)，\(tasks.count) 项任务")
    }

    private func symbolName(for quadrant: Quadrant) -> String {
        switch quadrant {
        case .urgentImportant: return "bolt.fill"
        case .importantNotUrgent: return "star.fill"
        case .urgentNotImportant: return "clock.fill"
        case .notUrgentNotImportant: return "leaf.fill"
        }
    }

    private func taskRow(_ item: TodoItem, quadrant: Quadrant) -> some View {
        HStack(spacing: PaperSpacing.compact) {
            Button {
                toggleDone(item)
            } label: {
                Image(systemName: item.isDone ? "checkmark.square.fill" : "square")
                    .foregroundStyle(item.isDone ? quadrant.color : theme.weakText)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isDone ? "标记未完成" : "标记完成")

            if let paper = item.paper {
                NavigationLink(value: paper) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.text)
                            .lineLimit(2)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(theme.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(paper.title.isEmpty ? "待办纸片" : paper.title)
                            .font(.caption2)
                            .foregroundStyle(theme.weakText)
                            .lineLimit(1)
                    }
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("打开\(item.text)")
            } else {
                Text(item.text)
                    .lineLimit(2)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Menu {
                ForEach(Quadrant.allCases) { target in
                    if target != quadrant {
                        Button("移到\(target.displayName)") {
                            move(item, to: target)
                        }
                    }
                }
                Button("编辑") {
                    presentEdit(item)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(theme.weakText)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(item.text)的操作")
        }
        .padding(.horizontal, PaperSpacing.compact)
        .padding(.vertical, 2)
        .background(theme.paper.opacity(0.28), in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(item.text)
    }

    private func resolvedQuadrant(of item: TodoItem) -> Quadrant {
        if let quadrant = item.quadrant {
            return quadrant
        }
        return Self.deriveQuadrant(from: item.text)
    }

    static func deriveQuadrant(from text: String) -> Quadrant {
        let lower = text.lowercased()
        let urgent = lower.contains("紧急") || lower.contains("今天") || lower.contains("马上")
        let important = lower.contains("重要") || lower.contains("项目") || lower.contains("截止")
        switch (important, urgent) {
        case (true, true): return .urgentImportant
        case (true, false): return .importantNotUrgent
        case (false, true): return .urgentNotImportant
        case (false, false): return .notUrgentNotImportant
        }
    }

    private func toggleDone(_ item: TodoItem) {
        item.isDone.toggle()
        item.paper?.updatedAt = Date()
        saveContext()
        Task { await ReminderNotificationService.schedule(todo: item) }
    }

    private func move(_ item: TodoItem, to quadrant: Quadrant) {
        item.quadrant = quadrant
        item.paper?.updatedAt = Date()
        saveContext()
    }

    private func presentAddTask(in quadrant: Quadrant) {
        editorConfig = QuadrantEditorConfig(title: "在\(quadrant.displayName)新增任务", initialText: "") { text in
            addTask(named: text, in: quadrant)
        }
    }

    private func presentEdit(_ item: TodoItem) {
        editorConfig = QuadrantEditorConfig(title: "编辑任务", initialText: item.text) { text in
            item.text = text
            item.paper?.updatedAt = Date()
            return saveContext()
        }
    }

    private func addTask(named title: String, in quadrant: Quadrant) -> Bool {
        let target: Paper
        if let existing = papers.first(where: { $0.kind == .todo }) {
            target = existing
        } else {
            let paper = Paper(kind: .todo, title: "待办")
            modelContext.insert(paper)
            target = paper
        }
        let item = TodoItem(text: title, sortIndex: target.todoItems.count)
        item.quadrant = quadrant
        target.todoItems.append(item)
        target.updatedAt = Date()
        return saveContext()
    }

    private func saveContext() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            saveErrorMessage = error.localizedDescription
            return false
        }
    }
}

private struct QuadrantEditorConfig: Identifiable {
    let id = UUID()
    let title: String
    let initialText: String
    let handler: (String) -> Bool
}

private struct QuadrantTaskEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let initialText: String
    let onSubmit: (String) -> Bool
    @State private var text: String

    init(title: String, initialText: String, onSubmit: @escaping (String) -> Bool) {
        self.title = title
        self.initialText = initialText
        self.onSubmit = onSubmit
        _text = State(initialValue: initialText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("任务内容", text: $text)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if onSubmit(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                            dismiss()
                        }
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
