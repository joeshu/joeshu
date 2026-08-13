import SwiftUI
import SwiftData
import UniformTypeIdentifiers

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

    private var sortedTodos: [TodoItem] {
        paper.todoItems.sorted { $0.sortIndex < $1.sortIndex }
    }

    private var theme: PaperPalette {
        settings.palette(dark: colorScheme == .dark)
    }

    var body: some View {
        List {
            Section {
                TextField("纸片标题", text: $paper.title)
                    .font(.headline)
                    .foregroundStyle(theme.text)
            }
            .listRowBackground(theme.paper)
            Section {
                ForEach(sortedTodos) { item in
                    HStack(spacing: 10) {
                        Button {
                            toggle(item)
                        } label: {
                            Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(item.isDone ? Color.green : Color.secondary)
                        }
                        .buttonStyle(.borderless)

                        Text(item.text)
                            .font(.system(size: settings.todoVisualSize.fontSize))
                            .strikethrough(item.isDone)
                            .foregroundStyle(item.isDone ? Color.secondary : Color.primary)

                        Spacer()
                    }
                    .onDrag { NSItemProvider(object: item.id.uuidString as NSString) }
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
            } header: {
                HStack {
                    Text("待办事项")
                    Spacer()
                    if settings.autoClearDone {
                        Label("自动清除", systemImage: "wand.and.stars")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listRowBackground(theme.paper)

            Section {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    TextEditor(text: $newTodoText)
                        .frame(minHeight: 36, maxHeight: 80)
                        .focused($newItemFocused)
                        .onChange(of: newTodoText) { _, newValue in
                            if newValue.contains("\n") {
                                let lines = newValue.components(separatedBy: .newlines)
                                addItems(lines)
                                newTodoText = ""
                            }
                        }
                }
            }
            .listRowBackground(theme.paper)
        }
        .scrollContentBackground(.hidden)
        .background(theme.paper.opacity(0.4))
        .safeAreaInset(edge: .bottom) {
            if !sortedTodos.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                    Text("拖拽到此删除")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isDropTargeted ? Color.red.opacity(0.9) : Color.red.opacity(0.6))
                .dropDestination(for: String.self) { items, _ in
                    deleteDragged(items)
                    return true
                } isTargeted: { targeted in
                    withAnimation { isDropTargeted = targeted }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(undoStack.isEmpty)

                Button {
                    redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(redoStack.isEmpty)

                Button {
                    withAnimation {
                        paper.isPinned.toggle()
                        paper.updatedAt = Date()
                    }
                } label: {
                    Image(systemName: paper.isPinned ? "pin.fill" : "pin")
                }

                EditButton()
            }
        }
        .navigationTitle(paper.title.isEmpty ? "待办" : paper.title)
    }

    private func pushUndo() {
        undoStack.append(snapshot())
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    private func snapshot() -> [TodoSnapshot] {
        sortedTodos.map {
            TodoSnapshot(id: $0.id, text: $0.text, isDone: $0.isDone, sortIndex: $0.sortIndex)
        }
    }

    private func restore(_ snap: [TodoSnapshot]) {
        for item in paper.todoItems {
            modelContext.delete(item)
        }
        for s in snap {
            let item = TodoItem(text: s.text, isDone: s.isDone, sortIndex: s.sortIndex)
            item.paper = paper
            modelContext.insert(item)
        }
        paper.updatedAt = Date()
        try? modelContext.save()
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
        for raw in lines {
            let text = cleanPrefix(raw)
            guard !text.isEmpty else { continue }
            maxIndex += 1
            let item = TodoItem(text: text, sortIndex: maxIndex)
            item.paper = paper
            modelContext.insert(item)
        }
        if maxIndex >= 0 {
            paper.updatedAt = Date()
            try? modelContext.save()
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
        try? modelContext.save()

        if settings.autoClearDone && item.isDone {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                modelContext.delete(item)
                paper.updatedAt = Date()
                try? modelContext.save()
            }
        }
    }

    private func deleteItems(_ indexSet: IndexSet) {
        pushUndo()
        for index in indexSet {
            modelContext.delete(sortedTodos[index])
        }
        paper.updatedAt = Date()
        try? modelContext.save()
    }

    private func deleteDragged(_ uuids: [String]) {
        pushUndo()
        let set = Set(uuids)
        for item in paper.todoItems where set.contains(item.id.uuidString) {
            modelContext.delete(item)
        }
        paper.updatedAt = Date()
        try? modelContext.save()
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        pushUndo()
        var items = sortedTodos
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.sortIndex = index
        }
        paper.updatedAt = Date()
        try? modelContext.save()
    }
}

struct TodoSnapshot {
    let id: UUID
    let text: String
    let isDone: Bool
    let sortIndex: Int
}
