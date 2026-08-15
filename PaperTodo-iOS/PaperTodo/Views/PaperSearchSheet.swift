import SwiftUI

struct PaperSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    let papers: [Paper]
    let theme: PaperPalette

    private var results: [Paper] {
        let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return papers }
        return papers.filter { paper in
            paper.title.localizedCaseInsensitiveContains(value)
                || paper.body.localizedCaseInsensitiveContains(value)
                || paper.todoItems.contains { $0.text.localizedCaseInsensitiveContains(value) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if results.isEmpty {
                    ContentUnavailableView("没有找到内容", systemImage: "magnifyingglass", description: Text("试试搜索纸片标题、笔记正文或任务内容。"))
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(results) { paper in
                        NavigationLink(value: paper) {
                            HStack(spacing: 12) {
                                Image(systemName: paper.kind == .todo ? "checklist" : "note.text")
                                    .foregroundStyle(paper.kind == .todo ? theme.tint : theme.active)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(paper.title.isEmpty ? (paper.kind == .todo ? "待办" : "笔记") : paper.title)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(theme.text)
                                    Text(resultDetail(for: paper))
                                        .font(.caption)
                                        .foregroundStyle(theme.weakText)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "搜索纸片、笔记和任务")
            .navigationDestination(for: Paper.self) { paper in
                switch paper.kind {
                case .todo:
                    TodoPaperView(paper: paper)
                case .note:
                    NotePaperView(paper: paper)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private func resultDetail(for paper: Paper) -> String {
        switch paper.kind {
        case .todo:
            let pending = paper.todoItems.filter { !$0.isDone }.count
            return "待办 · \(pending) 项未完成"
        case .note:
            return paper.body.isEmpty ? "空笔记" : "Markdown 笔记 · 最近编辑 \(paper.updatedAt.formatted(.relative(presentation: .named)))"
        }
    }
}
