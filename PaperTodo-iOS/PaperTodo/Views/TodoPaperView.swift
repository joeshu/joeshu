import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

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

    private var sortedTodos: [TodoItem] {
        paper.todoItems.sorted { $0.sortIndex < $1.sortIndex }
    }

    private var theme: PaperPalette {
        settings.palette(systemDark: colorScheme == .dark)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("待办事项")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(theme.weakText)
                        Spacer()
                        if settings.autoClearDone {
                            Label("自动清除", systemImage: "wand.and.stars")
                                .font(.caption2)
                                .foregroundStyle(theme.tint)
                        }
                    }
                    TextField("纸片标题", text: $paper.title)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.text)
                }
                .padding(.vertical, 6)
                .listRowBackground(clearCardBackground)
            }

            Section {
                ForEach(sortedTodos) { item in
                    todoRow(item)
                        .listRowBackground(theme.paper)
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
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
                        .font(.title2)
                        .foregroundStyle(theme.tint)
                        .padding(.top, 2)
                    TextEditor(text: $newTodoText)
                        .frame(minHeight: 36, maxHeight: 88)
                        .scrollContentBackground(.hidden)
                        .font(.system(.body, design: .rounded))
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
        .background(
            LinearGradient(
                colors: [
                    theme.paper.opacity(0.25),
                    theme.paper.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .safeAreaInset(edge: .bottom) {
            if !sortedTodos.isEmpty {
                dropZone
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
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        paper.isPinned.toggle()
                        paper.updatedAt = Date()
                    }
                } label: {
                    Image(systemName: paper.isPinned ? "pin.fill" : "pin")
                }

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        paper.isCollapsed.toggle()
                        paper.updatedAt = Date()
                        try? modelContext.save()
                    }
                } label: {
                    Image(systemName: paper.isCollapsed ? "rectangle.expand.vertical" : "rectangle.compress.vertical")
                }

                EditButton()
            }
        }
        .navigationTitle(paper.title.isEmpty ? "待办" : paper.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var clearCardBackground: some View {
        RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
            .fill(theme.paper)
            .overlay(
                RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                    .stroke(theme.paperBorder.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 12, y: 2)
    }

    private func todoRow(_ item: TodoItem) -> some View {
        HStack(spacing: 12) {
            Button {
                toggle(item)
            } label: {
                AnimatedCheckCircle(
                    isDone: item.isDone,
                    tint: theme.active
                )
            }
            .buttonStyle(.borderless)

             if editingItemID == item.id {
                 TextField("待办事项", text: binding(for: item), onCommit: finishEditing)
                     .font(.system(size: settings.todoVisualSize.fontSize, design: .rounded))
                     .foregroundStyle(theme.text)
                     .textFieldStyle(.plain)
                     .submitLabel(.done)
             } else {
                 Text(item.text)
                     .font(.system(size: settings.todoVisualSize.fontSize, design: .rounded))
                     .strikethrough(item.isDone)
                     .foregroundStyle(item.isDone ? theme.weakText : theme.text)
                     .animation(.easeOut(duration: 0.2), value: item.isDone)
                     .onTapGesture {
                         pushUndo()
                         editingItemID = item.id
                     }
             }

            Spacer()

            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundStyle(theme.weakText.opacity(0.5))
        }
        .contentShape(Rectangle())
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
                  editingItemID = item.id
             } label: {
                 Label("编辑", systemImage: "pencil")
             }
             Button {
                 pushUndo()
                 withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    item.isDone.toggle()
                    paper.updatedAt = Date()
                    try? modelContext.save()
                }
            } label: {
                Label(item.isDone ? "标记未完成" : "标记完成", systemImage: item.isDone ? "circle" : "checkmark.circle")
            }
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
                .fill(isDropTargeted ? Color.red : Color.red.opacity(0.65))
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
                try? modelContext.save()
            }
        )
    }

    private func finishEditing() {
        editingItemID = nil
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
            try? modelContext.save()
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
        try? modelContext.save()

        if item.isDone {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        if settings.autoClearDone && item.isDone {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    modelContext.delete(item)
                }
                paper.updatedAt = Date()
                try? modelContext.save()
            }
        }
    }

    private func deleteItems(_ indexSet: IndexSet) {
        pushUndo()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            for index in indexSet {
                modelContext.delete(sortedTodos[index])
            }
        }
        paper.updatedAt = Date()
        try? modelContext.save()
    }

    private func deleteItem(_ item: TodoItem) {
        pushUndo()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            modelContext.delete(item)
        }
        paper.updatedAt = Date()
        try? modelContext.save()
    }

    private func deleteDragged(_ uuids: [String]) {
        pushUndo()
        let set = Set(uuids)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            for item in paper.todoItems where set.contains(item.id.uuidString) {
                modelContext.delete(item)
            }
        }
        paper.updatedAt = Date()
        try? modelContext.save()
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
        try? modelContext.save()
    }
}

struct TodoSnapshot {
    let id: UUID
    let text: String
    let isDone: Bool
    let sortIndex: Int
}
