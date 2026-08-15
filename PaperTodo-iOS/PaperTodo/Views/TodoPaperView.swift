import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit
import WidgetKit

struct TodoPaperView: View {
    @Bindable var paper: Paper
    @Environment(\.modelContext) private var modelContext
    @Environment(\.settings) private var settings
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var newItemFocused: Bool

    @State private var newTodoText = ""
    @State private var undoStack: [[TodoSnapshot]] = []
    @State private var redoStack: [[TodoSnapshot]] = []
    @State private var isDropTargeted = false
    @State private var editingItemID: UUID?
    @FocusState private var editingItemFocused: Bool
    @State private var saveTask: Task<Void, Never>?
    @State private var autoClearTasks: [UUID: Task<Void, Never>] = [:]
    @State private var saveErrorMessage: String?
    @State private var schedulingItem: TodoItem?

    private var sortedTodos: [TodoItem] {
        paper.todoItems.sorted { $0.sortIndex < $1.sortIndex }
    }

    private var hasCompletedTodos: Bool {
        paper.todoItems.contains(where: \.isDone)
    }

    private var theme: PaperPalette {
        settings.palette(systemDark: colorScheme == .dark)
    }

    private var completedCount: Int {
        sortedTodos.filter(\.isDone).count
    }

    private var completionRatio: Double {
        guard !sortedTodos.isEmpty else { return 0 }
        return Double(completedCount) / Double(sortedTodos.count)
    }

    private var todoFontSize: CGFloat {
        UIFontMetrics(forTextStyle: .body).scaledValue(for: settings.todoVisualSize.fontSize)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Label("待办事项", systemImage: "checklist")
                            .font(PaperTypography.eyebrow)
                            .foregroundStyle(theme.active)
                        Spacer()
                        if settings.autoClearDone {
                            Label("自动清除", systemImage: "wand.and.stars")
                                .font(.caption2)
                                .foregroundStyle(theme.tint)
                        }
                    }
                    if !sortedTodos.isEmpty {
                        HStack(spacing: 8) {
                            ProgressView(value: completionRatio)
                                .tint(theme.active)
                            Text("完成 \(completedCount)/\(sortedTodos.count)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(theme.weakText)
                            .monospacedDigit()
                        }
                    }
                    Text(sortedTodos.isEmpty ? "从一件小事开始" : "保持节奏，完成下一项")
                        .font(PaperTypography.metadata)
                        .foregroundStyle(theme.weakText)
                    TextField("纸片标题", text: $paper.title)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.text)
                        .onChange(of: paper.title) { _, _ in
                            paper.updatedAt = Date()
                            scheduleSave()
                        }
                }
                .padding(.vertical, 6)
                .listRowBackground(clearCardBackground)
            }

            Section {
                ForEach(sortedTodos) { item in
                    todoRow(item)
                        .listRowBackground(clearCardBackground)
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
                if sortedTodos.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checklist")
                            .font(.system(size: 34, weight: .light))
                            .foregroundStyle(theme.weakText.opacity(0.6))
                        Text("还没有待办")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(theme.weakText)
                        Text("在下方输入框写下内容，回车即可添加")
                            .font(PaperTypography.metadata)
                            .foregroundStyle(theme.weakText.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .listRowBackground(clearCardBackground)
                }
            } header: {
                if !sortedTodos.isEmpty {
                    Text("\(sortedTodos.count) 项")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(theme.weakText)
                }
            }

            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: PaperIconSize.large))
                        .foregroundStyle(theme.tint)
                        .padding(.top, 2)
                    TextEditor(text: $newTodoText)
                        .frame(minHeight: 36)
                        .frame(maxHeight: 132)
                        .scrollContentBackground(.hidden)
                        .font(PaperTypography.body)
                        .foregroundStyle(theme.text)
                        .focused($newItemFocused)
                        .onChange(of: newTodoText) { _, newValue in
                            if newValue.contains("\n") {
                                let lines = newValue.components(separatedBy: .newlines)
                                addItems(lines)
                                newTodoText = ""
                            }
                        }
                }
                .padding(.vertical, 6)
                .listRowBackground(clearCardBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(theme.backgroundGradient.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if !sortedTodos.isEmpty {
                dropZone
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button {
                        clearDoneItems()
                    } label: {
                        Label("清除已完成", systemImage: "checkmark.circle.badge.xmark")
                    }
                    .disabled(!hasCompletedTodos)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("更多操作")

                Button {
                    undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(undoStack.isEmpty)
                .accessibilityLabel("撤销")

                Button {
                    redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(redoStack.isEmpty)
                .accessibilityLabel("重做")

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        paper.isPinned.toggle()
                        paper.updatedAt = Date()
                    }
                } label: {
                    Image(systemName: paper.isPinned ? "pin.fill" : "pin")
                }
                .accessibilityLabel(paper.isPinned ? "取消置顶" : "置顶")

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        paper.isCollapsed.toggle()
                        paper.updatedAt = Date()
                        saveContext()
                    }
                } label: {
                    Image(systemName: paper.isCollapsed ? "rectangle.expand.vertical" : "rectangle.compress.vertical")
                }
                .accessibilityLabel(paper.isCollapsed ? "展开纸片" : "折叠纸片")

                EditButton()
            }
        }
        .navigationTitle(paper.title.isEmpty ? "待办" : paper.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("保存失败", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("好", role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? "无法保存更改。")
        }
        .onDisappear {
            saveTask?.cancel()
            autoClearTasks.values.forEach { $0.cancel() }
            autoClearTasks.removeAll()
            saveContext()
        }
        .sheet(item: $schedulingItem) { item in
            TaskScheduleSheet(item: item, theme: theme) {
                paper.updatedAt = Date()
                saveContext()
                refreshWidget()
            }
        }
    }

    private var clearCardBackground: some View {
        RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
            .fill(theme.surfaceGradient)
            .overlay(
                RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                    .stroke(theme.paperBorder.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: theme.shadow.opacity(PaperElevation.raised.shadowOpacity), radius: PaperElevation.raised.shadowRadius, y: PaperElevation.raised.shadowY)
    }

    private func todoRow(_ item: TodoItem) -> some View {
        todoRowContent(item)
            .contentShape(Rectangle())
        .onTapGesture {
            guard editingItemID != item.id else { return }
            toggle(item)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.text)
        .accessibilityValue(item.isDone ? "已完成" : "未完成")
        .accessibilityHint("双击切换完成状态，使用上下文菜单编辑")
        .onDrag { NSItemProvider(object: item.id.uuidString as NSString) }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteItem(item)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                deleteItem(item)
            } label: {
                Label("删除", systemImage: "trash")
            }
            Button {
                pushUndo()
                beginEditing(item)
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            Button {
                toggle(item)
            } label: {
                Label(item.isDone ? "标记未完成" : "标记完成", systemImage: item.isDone ? "circle" : "checkmark.circle")
            }
            Button {
                schedulingItem = item
            } label: {
                Label("安排时间", systemImage: "clock.badge.plus")
            }
        }
        .padding(.horizontal, PaperSpacing.compact)
        .padding(.vertical, PaperSpacing.micro)
        .background(theme.paper.opacity(0.24), in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
    }

    private func todoRowContent(_ item: TodoItem) -> some View {
        HStack(spacing: PaperSpacing.control) {
            AnimatedCheckCircle(
                isDone: item.isDone,
                tint: theme.active,
                untinted: theme.weakText
            )
            .accessibilityHidden(true)

            todoItemText(item)

            Spacer()

            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundStyle(theme.weakText.opacity(0.5))
        }
    }

    @ViewBuilder
    private func todoItemText(_ item: TodoItem) -> some View {
        if editingItemID == item.id {
            TextField("待办事项", text: binding(for: item), onCommit: finishEditing)
                .font(.system(size: todoFontSize, weight: .regular, design: .rounded, relativeTo: .body))
                .foregroundStyle(theme.text)
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .focused($editingItemFocused)
        } else {
            Text(item.text)
                .font(.system(size: todoFontSize, weight: .regular, design: .rounded, relativeTo: .body))
                .strikethrough(item.isDone)
                .foregroundStyle(item.isDone ? theme.weakText : theme.text)
                .animation(.easeOut(duration: 0.2), value: item.isDone)
        }
    }

    private var dropZone: some View {
        HStack(spacing: 8) {
            Image(systemName: "trash")
            Text("拖拽到此删除")
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            Capsule()
                .fill(isDropTargeted ? theme.danger : theme.danger.opacity(0.65))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .animation(.easeInOut(duration: 0.15), value: isDropTargeted)
        .dropDestination(for: String.self) { items, _ in
            deleteDragged(items)
            return true
        } isTargeted: { targeted in
            withAnimation { isDropTargeted = targeted }
        }
    }

    private func pushUndo() {
        undoStack.append(snapshot())
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    private func binding(for item: TodoItem) -> Binding<String> {
        Binding(
            get: { item.text },
            set: {
                item.text = $0
                paper.updatedAt = Date()
                scheduleSave()
            }
        )
    }

    private func finishEditing() {
        editingItemID = nil
        editingItemFocused = false
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            saveContext()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func refreshWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func beginEditing(_ item: TodoItem) {
        editingItemID = item.id
        DispatchQueue.main.async {
            editingItemFocused = true
        }
    }

    private func snapshot() -> [TodoSnapshot] {
        sortedTodos.map {
            TodoSnapshot(
                id: $0.id,
                text: $0.text,
                isDone: $0.isDone,
                sortIndex: $0.sortIndex,
                estimatedMinutes: $0.estimatedMinutes,
                scheduledStart: $0.scheduledStart,
                scheduledEnd: $0.scheduledEnd
            )
        }
    }

    private func restore(_ snap: [TodoSnapshot]) {
        autoClearTasks.values.forEach { $0.cancel() }
        autoClearTasks.removeAll()
        let snapByID = Dictionary(uniqueKeysWithValues: snap.map { ($0.id, $0) })
        var remainingIDs = Set(snapByID.keys)
        for item in paper.todoItems {
            if let match = snapByID[item.id] {
                item.text = match.text
                item.isDone = match.isDone
                item.sortIndex = match.sortIndex
                item.estimatedMinutes = match.estimatedMinutes
                item.scheduledStart = match.scheduledStart
                item.scheduledEnd = match.scheduledEnd
                remainingIDs.remove(item.id)
            } else {
                modelContext.delete(item)
            }
        }
        for id in remainingIDs {
            guard let s = snapByID[id] else { continue }
            let item = TodoItem(id: id, text: s.text, isDone: s.isDone, sortIndex: s.sortIndex)
            item.estimatedMinutes = s.estimatedMinutes
            item.scheduledStart = s.scheduledStart
            item.scheduledEnd = s.scheduledEnd
            item.paper = paper
            modelContext.insert(item)
        }
        paper.updatedAt = Date()
        saveContext()
        refreshWidget()
    }

    private func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(snapshot())
        restore(previous)
    }

    private func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(snapshot())
        restore(next)
    }

    private func addItems(_ lines: [String]) {
        pushUndo()
        var maxIndex = paper.todoItems.map(\.sortIndex).max() ?? -1
        var added = 0
        for raw in lines {
            let text = cleanPrefix(raw)
            guard !text.isEmpty else { continue }
            maxIndex += 1
            let item = TodoItem(text: text, sortIndex: maxIndex)
            item.paper = paper
            modelContext.insert(item)
            added += 1
        }
        if added > 0 {
            paper.updatedAt = Date()
            saveContext()
            refreshWidget()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func cleanPrefix(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let patterns = [
            #"^-\s+"#, #"^\*\s+"#, #"^•\s+"#,
            #"^\d+[\.\)]\s+"#, #"^\s*\[[ xX]\]\s+"#,
            #"^TODO\s*[:：]\s*"#, #"^待办[:：]\s*"#
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(location: 0, length: (text as NSString).length)
                text = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
            }
        }
        return text
    }

    private func toggle(_ item: TodoItem) {
        pushUndo()
        item.isDone.toggle()
        paper.updatedAt = Date()
        saveContext()
        Task { await ReminderNotificationService.schedule(todo: item) }
        refreshWidget()

        if item.isDone {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            UISelectionFeedbackGenerator().selectionChanged()
        }

        if settings.autoClearDone && item.isDone {
            let itemID = item.id
            let paperID = paper.persistentModelID
            autoClearTasks[itemID]?.cancel()
            autoClearTasks[itemID] = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else {
                    autoClearTasks.removeValue(forKey: itemID)
                    return
                }
                guard settings.autoClearDone,
                      let current = paper.todoItems.first(where: { $0.id == itemID }),
                      current.isDone,
                      current.paper?.persistentModelID == paperID else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    modelContext.delete(current)
                }
                paper.updatedAt = Date()
                saveContext()
                refreshWidget()
                autoClearTasks.removeValue(forKey: itemID)
            }
        }
    }

    private func deleteItems(_ indexSet: IndexSet) {
        pushUndo()
        for index in indexSet {
            Task { await ReminderNotificationService.remove(for: sortedTodos[index].id) }
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            for index in indexSet {
                modelContext.delete(sortedTodos[index])
            }
        }
        paper.updatedAt = Date()
        saveContext()
        refreshWidget()
    }

    private func deleteItem(_ item: TodoItem) {
        pushUndo()
        Task { await ReminderNotificationService.remove(for: item.id) }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            modelContext.delete(item)
        }
        paper.updatedAt = Date()
        saveContext()
        refreshWidget()
    }

    private func deleteDragged(_ uuids: [String]) {
        pushUndo()
        let set = Set(uuids)
        for item in paper.todoItems where set.contains(item.id.uuidString) {
            Task { await ReminderNotificationService.remove(for: item.id) }
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            for item in paper.todoItems where set.contains(item.id.uuidString) {
                modelContext.delete(item)
            }
        }
        paper.updatedAt = Date()
        saveContext()
        refreshWidget()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func clearDoneItems() {
        let completed = paper.todoItems.filter(\.isDone)
        guard !completed.isEmpty else { return }
        pushUndo()
        for item in completed {
            Task { await ReminderNotificationService.remove(for: item.id) }
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            completed.forEach(modelContext.delete)
        }
        paper.updatedAt = Date()
        saveContext()
        refreshWidget()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        pushUndo()
        var items = sortedTodos
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.sortIndex = index
        }
        paper.updatedAt = Date()
        saveContext()
        refreshWidget()
    }
}

struct TodoSnapshot {
    let id: UUID
    let text: String
    let isDone: Bool
    let sortIndex: Int
    let estimatedMinutes: Int?
    let scheduledStart: Date?
    let scheduledEnd: Date?
}
