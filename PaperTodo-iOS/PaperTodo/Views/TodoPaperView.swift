import SwiftUI
import SwiftData

struct TodoPaperView: View {
    @Bindable var paper: Paper
    @Environment(\.modelContext) private var modelContext
    @FocusState private var newItemFocused: Bool

    @State private var newTodoText = ""

    private var sortedTodos: [TodoItem] {
        paper.todoItems.sorted { $0.sortIndex < $1.sortIndex }
    }

    var body: some View {
        List {
            Section {
                TextField("纸片标题", text: $paper.title)
                    .font(.headline)
            }
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
                            .strikethrough(item.isDone)
                            .foregroundStyle(item.isDone ? Color.secondary : Color.primary)

                        Spacer()
                    }
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
            } header: {
                Text("待办事项")
            }

            Section {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.secondary)
                    TextField("新增事项，回车添加", text: $newTodoText)
                        .focused($newItemFocused)
                        .submitLabel(.done)
                        .onSubmit(addItem)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
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

    private func addItem() {
        let text = newTodoText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let maxIndex = paper.todoItems.map(\.sortIndex).max() ?? -1
        let item = TodoItem(text: text, sortIndex: maxIndex + 1)
        item.paper = paper
        modelContext.insert(item)
        paper.updatedAt = Date()
        newTodoText = ""
        newItemFocused = true
        try? modelContext.save()
    }

    private func toggle(_ item: TodoItem) {
        item.isDone.toggle()
        paper.updatedAt = Date()
        try? modelContext.save()
    }

    private func deleteItems(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(sortedTodos[index])
        }
        paper.updatedAt = Date()
        try? modelContext.save()
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var items = sortedTodos
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.sortIndex = index
        }
        paper.updatedAt = Date()
        try? modelContext.save()
    }
}
