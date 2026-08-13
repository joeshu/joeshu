import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.settings) private var settings
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Paper.updatedAt, order: .reverse) private var papers: [Paper]
    @State private var paperPendingDeletion: Paper?
    @State private var saveErrorMessage: String?

    private var sortedPapers: [Paper] {
        papers.sorted {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned
            }
            return $0.updatedAt > $1.updatedAt
        }
    }

    private var theme: PaperPalette {
        settings.palette(dark: colorScheme == .dark)
    }

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Group {
                if papers.isEmpty {
                    EmptyStateView(
                        theme: theme,
                        onAddTodo: { addPaper(kind: .todo, title: "待办") },
                        onAddNote: { addPaper(kind: .note, title: "笔记") }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(sortedPapers) { paper in
                                NavigationLink(value: paper) {
                                    PaperCard(paper: paper, theme: theme) {
                                        togglePin(paper)
                                    }
                                }
                                .buttonStyle(.plain)
                                .transition(.scale.combined(with: .opacity))
                                .contextMenu {
                                    Button {
                                        togglePin(paper)
                                    } label: {
                                        Label(paper.isPinned ? "取消置顶" : "置顶", systemImage: "pin")
                                    }
                                    Button(role: .destructive) {
                                        paperPendingDeletion = paper
                                    } label: {
                                        Label("删除纸片", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        paperPendingDeletion = paper
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .scrollIndicators(.hidden)
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
                }
            }
            .navigationTitle("PaperTodo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Paper.self) { paper in
                switch paper.kind {
                case .todo:
                    TodoPaperView(paper: paper)
                case .note:
                    NotePaperView(paper: paper)
                }
            }
            .confirmationDialog(
                "删除这张纸片？",
                isPresented: Binding(
                    get: { paperPendingDeletion != nil },
                    set: { if !$0 { paperPendingDeletion = nil } }
                ),
                presenting: paperPendingDeletion
            ) { paper in
                Button("删除", role: .destructive) {
                    deletePaper(paper)
                }
                Button("取消", role: .cancel) { }
            } message: { paper in
                Text("将删除“\(paper.title.isEmpty ? (paper.kind == .todo ? "待办" : "笔记") : paper.title)”及其内容。")
            }
            .alert("保存失败", isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )) {
                Button("好", role: .cancel) { }
            } message: {
                Text(saveErrorMessage ?? "无法保存当前修改。")
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Picker("配色", selection: $settings.colorScheme) {
                            ForEach(PaperColorScheme.allCases) { scheme in
                                Text(scheme.rawValue).tag(scheme)
                            }
                        }
                    } label: {
                        Image(systemName: "paintpalette")
                    }

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
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            let paper = Paper(kind: kind, title: title)
            modelContext.insert(paper)
            saveContext()
        }
    }

    private func togglePin(_ paper: Paper) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            paper.isPinned.toggle()
            paper.updatedAt = Date()
            saveContext()
        }
    }

    private func deletePaper(_ paper: Paper) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            modelContext.delete(paper)
        }
        saveContext()
        paperPendingDeletion = nil
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}

struct PaperCard: View {
    let paper: Paper
    let theme: PaperPalette
    let onTogglePin: () -> Void

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

    private var icon: String {
        paper.kind == .todo ? "checklist" : "note.text"
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(paper.kind == .todo ? theme.tint.opacity(0.16) : theme.active.opacity(0.16))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(paper.kind == .todo ? theme.tint : theme.active)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(paper.title.isEmpty ? (paper.kind == .todo ? "待办" : "笔记") : paper.title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(theme.text)
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(theme.weakText)
                    .lineLimit(2)
            }

            Spacer()

            VStack(spacing: 8) {
                if paper.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(theme.tint)
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.weakText.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                .fill(theme.paper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                .stroke(theme.paperBorder.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 12, y: 2)
        .contextMenu {
            Button(action: onTogglePin) {
                Label(paper.isPinned ? "取消置顶" : "置顶", systemImage: "pin")
            }
        }
    }
}

struct EmptyStateView: View {
    let theme: PaperPalette
    var onAddTodo: () -> Void = {}
    var onAddNote: () -> Void = {}

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(theme.tint.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(theme.tint)
            }
            VStack(spacing: 8) {
                Text("还没有纸片")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.text)
                Text("让桌面上有几张安静、可用、不打扰人的纸")
                    .font(.subheadline)
                    .foregroundStyle(theme.weakText)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 12) {
                Button(action: onAddTodo) {
                    Label("待办纸", systemImage: "checklist")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(theme.tint))
                }
                .buttonStyle(.plain)
                Button(action: onAddNote) {
                    Label("笔记纸", systemImage: "note.text")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.active)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().stroke(theme.active.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    theme.paper.opacity(0.35),
                    theme.paper.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
