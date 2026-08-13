import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Paper.updatedAt, order: .reverse) private var papers: [Paper]

    var body: some View {
        NavigationStack {
            Group {
                if papers.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(papers) { paper in
                            NavigationLink(value: paper) {
                                PaperRow(paper: paper)
                            }
                        }
                        .onDelete(perform: deletePapers)
                    }
                }
            }
            .navigationTitle("PaperTodo")
            .navigationDestination(for: Paper.self) { paper in
                switch paper.kind {
                case .todo:
                    TodoPaperView(paper: paper)
                case .note:
                    NotePaperView(paper: paper)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            addPaper(kind: .todo, title: "待办")
                        } label: {
                            Label("新建待办纸", systemImage: "checklist")
                        }
                        Button {
                            addPaper(kind: .note, title: "笔记")
                        } label: {
                            Label("新建笔记纸", systemImage: "note.text")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func addPaper(kind: PaperKind, title: String) {
        let paper = Paper(kind: kind, title: title)
        modelContext.insert(paper)
        try? modelContext.save()
    }

    private func deletePapers(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(papers[index])
        }
        try? modelContext.save()
    }
}

struct PaperRow: View {
    let paper: Paper

    private var summary: String {
        switch paper.kind {
        case .todo:
            let done = paper.todoItems.filter { $0.isDone }.count
            let total = paper.todoItems.count
            return total == 0 ? "空待办纸" : "\(done)/\(total) 已完成"
        case .note:
            let text = paper.body.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? "空笔记" : text
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: paper.kind == .todo ? "checklist" : "note.text")
                .foregroundStyle(paper.kind == .todo ? .orange : .blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(paper.title.isEmpty ? (paper.kind == .todo ? "待办" : "笔记") : paper.title)
                    .font(.headline)
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            if paper.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyStateView: View {
    var body: some View {
        ContentUnavailableView {
            Label("还没有纸片", systemImage: "rectangle.on.rectangle")
        } description: {
            Text("点击右上角 + 新建一张待办纸或笔记纸")
        }
    }
}
