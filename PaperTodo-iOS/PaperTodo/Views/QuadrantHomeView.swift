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

    private var activeItems: [TodoItem] {
        allItems.filter { !$0.isDone }
    }

    private var completedItems: [TodoItem] {
        allItems.filter(\.isDone)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PaperSpacing.section) {
                VStack(alignment: .leading, spacing: PaperSpacing.micro) {
                    Text("四象限")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.text)
                    Text("把注意力放在真正重要的下一步")
                        .font(PaperTypography.metadata)
                        .foregroundStyle(theme.weakText)
                }
                .padding(.horizontal, 4)

                summaryStrip

                quadrantAxisGuide

                LazyVGrid(columns: quadrantColumns, spacing: 12) {
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

    private var quadrantColumns: [GridItem] {
        [GridItem(.flexible(minimum: 0), spacing: 10), GridItem(.flexible(minimum: 0), spacing: 10)]
    }

    private var summaryStrip: some View {
        HStack(spacing: 0) {
            summaryMetric(value: activeItems.count, label: "待处理", color: theme.accent)
            Divider()
                .frame(height: 32)
                .overlay(theme.paperBorder.opacity(0.6))
            summaryMetric(value: completedItems.count, label: "已完成", color: theme.active)
            Divider()
                .frame(height: 32)
                .overlay(theme.paperBorder.opacity(0.6))
            summaryMetric(value: allItems.count, label: "全部任务", color: theme.text)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PaperSpacing.control)
        .background(theme.surfaceGradient, in: RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                .stroke(theme.paperBorder.opacity(0.55), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("共 \(allItems.count) 项任务，待处理 \(activeItems.count) 项，已完成 \(completedItems.count) 项")
    }

    private var quadrantAxisGuide: some View {
        HStack(spacing: PaperSpacing.compact) {
            Label("重要", systemImage: "star.fill")
            Text("↑")
                .foregroundStyle(theme.accent)
            Text("紧急 →")
                .foregroundStyle(theme.weakText)
            Spacer(minLength: PaperSpacing.compact)
            Text("先处理左上")
                .foregroundStyle(theme.weakText)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(theme.text)
        .padding(.horizontal, PaperSpacing.control)
        .frame(minHeight: 34)
        .background(theme.paper.opacity(0.46), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("重要性从下到上增加，紧急性从左到右增加，优先处理左上象限")
    }

    private func summaryMetric(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(PaperTypography.statistic)
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(PaperTypography.metadata)
                .foregroundStyle(theme.weakText)
        }
        .frame(maxWidth: .infinity)
    }

    private func quadrantCard(_ quadrant: Quadrant) -> some View {
        let tasks = activeItems.filter { resolvedQuadrant(of: $0) == quadrant }
        let completedCount = completedItems.filter { resolvedQuadrant(of: $0) == quadrant }.count
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: PaperSpacing.micro) {
                Image(systemName: symbolName(for: quadrant))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(quadrant.color)
                    .frame(width: 22, height: 22)
                    .background(quadrant.color.opacity(0.1), in: RoundedRectangle(cornerRadius: PaperRadius.small, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text(quadrant.displayName)
                        .font(.caption.weight(.bold))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(quadrant.subtitle)
                        .font(.caption2)
                        .foregroundStyle(theme.weakText)
                }
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(quadrant.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(quadrant.color.opacity(0.12), in: Capsule())
            }
            .foregroundStyle(theme.text)
            if tasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: completedCount > 0 ? "checkmark.circle" : "tray")
                        .font(.system(size: 13))
                        .foregroundStyle(completedCount > 0 ? theme.active : theme.weakText)
                    Text(completedCount > 0 ? "本象限已清空" : "从这里开始整理")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(theme.weakText)
                    Button {
                        presentAddTask(in: quadrant)
                    } label: {
                        Label("新增任务", systemImage: "plus")
                            .font(.caption2.weight(.semibold))
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
            if completedCount > 0 && !tasks.isEmpty {
                Text("已完成 \(completedCount) 项")
                    .font(.caption2)
                    .foregroundStyle(theme.active)
            }
        }
        .padding(.horizontal, PaperSpacing.control)
        .padding(.vertical, PaperSpacing.compact)
        .frame(maxWidth: .infinity, minHeight: 176, alignment: .topLeading)
        .background(theme.surfaceGradient, in: RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                .stroke(quadrant.color.opacity(0.32), lineWidth: 1)
        }
        .shadow(color: theme.shadow.opacity(0.1), radius: PaperElevation.raised.shadowRadius, y: PaperElevation.raised.shadowY)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(quadrant.displayName)，\(tasks.count) 项待处理任务，已完成 \(completedCount) 项")
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
        HStack(spacing: PaperSpacing.micro) {
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
                            .lineLimit(3)
                            .font(.caption2.weight(.medium))
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
                    .lineLimit(3)
                    .font(.caption2.weight(.medium))
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
                Image(systemName: "ellipsis")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.weakText)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(item.text)的操作")
        }
        .padding(.horizontal, PaperSpacing.micro)
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
