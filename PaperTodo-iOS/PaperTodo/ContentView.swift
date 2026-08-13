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
        settings.palette(systemDark: colorScheme == .dark)
    }

    private var capsulePapers: [Paper] {
        sortedPapers.filter(\.isCollapsed)
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
                            HomeOverview(papers: sortedPapers, theme: theme)
                                .padding(.bottom, 2)

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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !capsulePapers.isEmpty {
                    CapsuleBar(papers: capsulePapers, theme: theme)
                }
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

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }

                    Menu {
                        ForEach(sortedPapers) { paper in
                            NavigationLink(value: paper) {
                                Label(
                                    paper.title.isEmpty ? (paper.kind == .todo ? "待办" : "笔记") : paper.title,
                                    systemImage: paper.kind == .todo ? "checklist" : "note.text"
                                )
                            }
                        }
                    } label: {
                        Image(systemName: "rectangle.stack")
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
        if paper.kind == .note {
            NoteImageStore.deleteReferenced(in: paper.body)
        }
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

private struct CapsuleBar: View {
    let papers: [Paper]
    let theme: PaperPalette

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(papers) { paper in
                    NavigationLink(value: paper) {
                        HStack(spacing: 6) {
                            Image(systemName: paper.kind == .todo ? "checklist" : "note.text")
                                .foregroundStyle(paper.kind == .todo ? theme.tint : theme.active)
                            Text(paper.title.isEmpty ? (paper.kind == .todo ? "待办" : "笔记") : paper.title)
                                .lineLimit(1)
                        }
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(theme.paper)
                                .shadow(color: .black.opacity(0.08), radius: 5, y: 2)
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    paper.isPinned ? theme.tint.opacity(0.9) : theme.paperBorder.opacity(0.7),
                                    lineWidth: paper.isPinned ? 1.5 : 1
                                )
                        )
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
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
            let text = paper.body
                .replacingOccurrences(of: #"[`*_>#\[\]]"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? "空笔记" : text
        }
    }

    private var completedCount: Int {
        paper.todoItems.filter(\.isDone).count
    }

    private var progress: Double {
        guard !paper.todoItems.isEmpty else { return 0 }
        return Double(completedCount) / Double(paper.todoItems.count)
    }

    private var icon: String {
        paper.kind == .todo ? "checklist" : "note.text"
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: PaperRadius.small, style: .continuous)
                .fill(paper.kind == .todo ? theme.tint : theme.active)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(paper.kind == .todo ? theme.tint : theme.active)
                    Text(paper.title.isEmpty ? (paper.kind == .todo ? "待办" : "笔记") : paper.title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(theme.text)
                        .lineLimit(1)
                }
                Text(paper.kind == .todo ? "待办清单" : "Markdown 笔记")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(theme.weakText)
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(theme.weakText)
                    .lineLimit(1)
                if paper.kind == .todo && !paper.todoItems.isEmpty {
                    ProgressView(value: progress)
                        .tint(theme.active)
                        .scaleEffect(x: 1, y: 0.65, anchor: .center)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
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
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                .fill(theme.paper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                .stroke(theme.paperBorder.opacity(0.5), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [theme.text.opacity(0.16), .clear],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
        .shadow(color: .black.opacity(0.07), radius: 14, y: 5)
        .contextMenu {
            Button(action: onTogglePin) {
                Label(paper.isPinned ? "取消置顶" : "置顶", systemImage: "pin")
            }
        }
    }
}

private struct HomeOverview: View {
    let papers: [Paper]
    let theme: PaperPalette

    private var todoPapers: [Paper] {
        papers.filter { $0.kind == .todo }
    }

    private var noteCount: Int {
        papers.filter { $0.kind == .note }.count
    }

    private var pendingCount: Int {
        todoPapers.reduce(0) { total, paper in
            total + paper.todoItems.filter { !$0.isDone }.count
        }
    }

    private var pinnedCount: Int {
        papers.filter(\.isPinned).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("今日工作台")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.text)
                    Text(pendingCount == 0 ? "所有待办都已处理" : "还有 \(pendingCount) 项待办等待处理")
                        .font(.caption)
                        .foregroundStyle(theme.weakText)
                }
                Spacer()
                Image(systemName: pendingCount == 0 ? "checkmark.seal.fill" : "sparkles")
                    .font(.title2)
                    .foregroundStyle(pendingCount == 0 ? theme.active : theme.tint)
            }

            HStack(spacing: 0) {
                overviewMetric(value: papers.count, label: "纸片")
                Divider()
                    .frame(height: 24)
                    .opacity(0.45)
                overviewMetric(value: pendingCount, label: "待办")
                Divider()
                    .frame(height: 24)
                    .opacity(0.45)
                overviewMetric(value: noteCount, label: "笔记")
                Divider()
                    .frame(height: 24)
                    .opacity(0.45)
                overviewMetric(value: pinnedCount, label: "置顶")
            }
            .padding(.vertical, 10)
            .background(theme.paper.opacity(0.48), in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous)
                    .stroke(theme.paperBorder.opacity(0.35), lineWidth: 1)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }

    private func overviewMetric(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(theme.text)
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundStyle(theme.weakText)
        }
        .frame(maxWidth: .infinity)
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
