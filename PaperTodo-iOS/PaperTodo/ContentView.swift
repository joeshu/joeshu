import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.settings) private var settings
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Paper.updatedAt, order: .reverse) private var papers: [Paper]
    @State private var paperPendingDeletion: Paper?
    @State private var saveErrorMessage: String?
    @State private var activeFilter: PaperFilter = .all
    @State private var paperPreview: Paper?
    @State private var paperAwaitingDeletion: Paper?
    @State private var pendingDeletions: [UUID: PendingDeletion] = [:]
    @State private var isQuickCapturePresented = false

    private var sortedPapers: [Paper] {
        Self.sortPapers(papers)
    }

    private static func sortPapers(_ input: [Paper]) -> [Paper] {
        input.sorted {
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
        activePapers.filter(\.isCollapsed)
    }

    private var activePapers: [Paper] {
        let pendingIDs = Set(pendingDeletions.keys)
        return sortedPapers.filter { !pendingIDs.contains($0.id) }
    }

    private var pendingDeletionPapers: [Paper] {
        pendingDeletions.values.map(\.paper).sorted { $0.updatedAt > $1.updatedAt }
    }

    private var visiblePapers: [Paper] {
        switch activeFilter {
        case .all:
            return activePapers
        case .todo:
            return activePapers.filter { $0.kind == .todo }
        case .note:
            return activePapers.filter { $0.kind == .note }
        case .pending:
            return activePapers.filter { paper in
                paper.kind == .todo && paper.todoItems.contains { !$0.isDone }
            }
        }
    }

    private var filterCounts: PaperFilterCounts {
        activePapers.reduce(into: PaperFilterCounts()) { counts, paper in
            counts.all += 1
            switch paper.kind {
            case .todo:
                counts.todo += 1
                if paper.todoItems.contains(where: { !$0.isDone }) {
                    counts.pending += 1
                }
            case .note:
                counts.note += 1
            }
        }
    }

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Group {
                HomeModeContent(
                    mode: $settings.homeMode,
                    papers: activePapers,
                    visiblePapers: visiblePapers,
                    filter: $activeFilter,
                    filterCounts: filterCounts,
                    theme: theme,
                    onTogglePin: togglePin,
                    onToggleCollapse: toggleCollapse,
                    onPreview: { paperPreview = $0 },
                    onDelete: { paperPendingDeletion = $0 },
                    onAddTodo: { addPaper(kind: .todo, title: "待办") },
                    onAddNote: { addPaper(kind: .note, title: "笔记") },
                    onQuickCapture: { isQuickCapturePresented = true }
                )
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
            .sheet(
                isPresented: Binding(
                    get: { paperPreview != nil },
                    set: { if !$0 { paperPreview = nil } }
                )
            ) {
                if let paperPreview {
                    PaperPreviewSheet(paper: paperPreview, theme: theme)
                }
            }
            .sheet(isPresented: $isQuickCapturePresented) {
                QuickCaptureSheet(papers: activePapers, theme: theme) { kind, text in
                    capture(kind: kind, text: text)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !capsulePapers.isEmpty {
                    CapsuleBar(papers: capsulePapers, theme: theme)
                }
            }
            .overlay(alignment: .bottom) {
                if !pendingDeletionPapers.isEmpty {
                    UndoDeletionBanner(papers: pendingDeletionPapers, theme: theme) { paper in
                        undoDeletion(paper)
                    }
                    .padding(.bottom, capsulePapers.isEmpty ? 12 : 64)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
                    .accessibilityLabel("配色")

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("设置")

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
                    .accessibilityLabel("纸片列表")

                    Menu {
                        Button {
                            isQuickCapturePresented = true
                        } label: {
                            Label("快速记录", systemImage: "square.and.pencil")
                        }
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
                    .accessibilityLabel("新建纸片")
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

    private func capture(kind: PaperKind, text: String) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if kind == .note {
                modelContext.insert(Paper(kind: .note, title: value))
            } else {
                let existingInbox = activePapers.first(where: { $0.kind == .todo && $0.title == "收件箱" })
                let inbox = existingInbox ?? Paper(kind: .todo, title: "收件箱")
                if existingInbox == nil {
                    modelContext.insert(inbox)
                }
                inbox.todoItems.append(TodoItem(text: value, sortIndex: inbox.todoItems.count))
                inbox.updatedAt = Date()
            }
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

    private func toggleCollapse(_ paper: Paper) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            paper.isCollapsed.toggle()
            paper.updatedAt = Date()
            saveContext()
        }
    }

    private func deletePaper(_ paper: Paper) {
        let entry = PendingDeletion(paper: paper, token: UUID())
        pendingDeletions[paper.id] = entry
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            paperAwaitingDeletion = paper
        }
        paperPendingDeletion = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            guard let stored = pendingDeletions[paper.id], stored.token == entry.token else { return }
            permanentlyDelete(stored.paper)
            pendingDeletions.removeValue(forKey: paper.id)
            if paperAwaitingDeletion?.id == paper.id {
                paperAwaitingDeletion = nil
            }
        }
    }

    private func undoDeletion(_ paper: Paper) {
        pendingDeletions.removeValue(forKey: paper.id)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if paperAwaitingDeletion?.id == paper.id {
                paperAwaitingDeletion = nil
            }
        }
    }

    private func permanentlyDelete(_ paper: Paper) {
        if paper.kind == .note {
            let namesReferencedByOtherNotes = (try? modelContext.fetch(FetchDescriptor<Paper>()))?
                .filter { $0.id != paper.id && $0.kind == .note }
                .reduce(into: Set<String>()) { names, otherPaper in
                    names.formUnion(NoteImageStore.referencedNames(in: otherPaper.body))
                } ?? []
            NoteImageStore.deleteReferenced(in: paper.body, preserving: namesReferencedByOtherNotes)
        }
        pendingDeletions.removeValue(forKey: paper.id)
        if paperAwaitingDeletion?.id == paper.id {
            paperAwaitingDeletion = nil
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            modelContext.delete(paper)
        }
        saveContext()
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}

enum PaperFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case todo = "待办"
    case note = "笔记"
    case pending = "未完成"

    var id: String { rawValue }
}

private struct PendingDeletion {
    let paper: Paper
    let token: UUID
}

struct PaperFilterCounts {
    var all = 0
    var todo = 0
    var note = 0
    var pending = 0

    subscript(filter: PaperFilter) -> Int {
        switch filter {
        case .all: return all
        case .todo: return todo
        case .note: return note
        case .pending: return pending
        }
    }
}

struct PaperFilterBar: View {
    @Binding var filter: PaperFilter
    let counts: PaperFilterCounts
    let theme: PaperPalette

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PaperFilter.allCases) { item in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            filter = item
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(item.rawValue) \(counts[item])")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(filter == item ? theme.paper : theme.weakText)
                            Capsule()
                                .fill(filter == item ? theme.paper.opacity(0.9) : .clear)
                                .frame(width: 18, height: 2)
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .frame(minHeight: 44)
                            .background(
                                Capsule()
                                    .fill(
                                        filter == item
                                            ? AnyShapeStyle(theme.activeGradient)
                                            : AnyShapeStyle(theme.paper.opacity(0.55))
                                    )
                            )
                            .overlay {
                                Capsule()
                                    .stroke(theme.paperBorder.opacity(filter == item ? 0 : 0.5), lineWidth: 1)
                            }
                    }
                    .buttonStyle(PaperPressStyle(pressedScale: 0.96))
                    .accessibilityLabel("筛选\(item.rawValue)")
                    .accessibilityValue("\(counts[item]) 项")
                    .accessibilityAddTraits(filter == item ? .isSelected : [])
                }
            }
            .padding(.horizontal, 4)
        }
        .scrollIndicators(.hidden)
    }

}

struct FilterEmptyState: View {
    let filter: PaperFilter
    let theme: PaperPalette

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: filter == .pending ? "checkmark.circle" : "rectangle.stack")
                .font(.title2)
                .foregroundStyle(theme.weakText)
            Text(filter == .pending ? "没有未完成的待办" : "这个分类暂时为空")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.text)
            Text("切换分类查看其它纸片")
                .font(.caption)
                .foregroundStyle(theme.weakText)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PaperPreviewSheet: View {
    let paper: Paper
    let theme: PaperPalette
    @Environment(\.dismiss) private var dismiss

    private var displayTitle: String {
        paper.title.isEmpty ? (paper.kind == .todo ? "待办" : "笔记") : paper.title
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: paper.kind == .todo ? "checklist" : "note.text")
                            .foregroundStyle(paper.kind == .todo ? theme.tint : theme.active)
                        Text(paper.kind == .todo ? "待办清单" : "Markdown 笔记")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.weakText)
                    }

                    if paper.kind == .todo {
                        if paper.todoItems.isEmpty {
                            Text("这张待办纸还是空的")
                                .font(.body)
                                .foregroundStyle(theme.weakText)
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(paper.todoItems.sorted { $0.sortIndex < $1.sortIndex }) { item in
                                    HStack(spacing: 10) {
                                        Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(item.isDone ? theme.active : theme.weakText)
                                        Text(item.text)
                                            .font(.body)
                                            .foregroundStyle(item.isDone ? theme.weakText : theme.text)
                                            .strikethrough(item.isDone)
                                    }
                                }
                            }
                        }
                    } else {
                        NoteRenderView(
                            markdown: paper.body,
                            strength: .full,
                            font: .body,
                            textColor: theme.text,
                            palette: theme
                        )
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.surfaceGradient, in: RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                        .stroke(theme.paperBorder.opacity(0.65), lineWidth: 1)
                }
                .padding(16)
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle(displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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
                                .fill(theme.surfaceGradient)
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
                    .buttonStyle(PaperPressStyle(pressedScale: 0.96))
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

    private static let previewLimit = 160

    private var summary: String {
        switch paper.kind {
        case .todo:
            let done = paper.todoItems.filter { $0.isDone }.count
            let total = paper.todoItems.count
            return total == 0 ? "空待办纸" : "\(done)/\(total) 已完成"
        case .note:
            let prefix = String(paper.body.prefix(Self.previewLimit * 2))
            let text = prefix
                .replacingOccurrences(of: #"[`*_>#\[\]]"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty { return "空笔记" }
            return text.count > Self.previewLimit ? String(text.prefix(Self.previewLimit)) + "…" : text
        }
    }

    private var detailText: String {
        switch paper.kind {
        case .todo:
            if paper.todoItems.isEmpty { return "还没有任务" }
            let scheduledCount = paper.todoItems.filter { item in
                guard let start = item.scheduledStart else { return false }
                return Calendar.current.isDateInToday(start)
            }.count
            return scheduledCount == 0 ? "\(paper.todoItems.count) 项任务" : "\(paper.todoItems.count) 项任务 · 今日已排 \(scheduledCount)"
        case .note:
            let prefix = String(paper.body.prefix(Self.previewLimit * 2))
            let count = prefix.split { $0.isWhitespace || $0.isNewline }.count
            return count == 0 ? "Markdown 笔记" : "\(count)+ 字 · Markdown 笔记"
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

    private var statusText: String {
        if paper.isPinned { return "已置顶" }
        if paper.kind == .todo && progress == 1 { return "已完成" }
        return paper.kind == .todo ? "进行中" : "可编辑"
    }

    private var nextTaskText: String? {
        paper.pendingTodos.first?.text.trimmingCharacters(in: .whitespacesAndNewlines)
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
                Text(detailText)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(theme.weakText)
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(theme.weakText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if paper.kind == .todo, let nextTaskText, !nextTaskText.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right.circle")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(theme.active)
                        Text("下一项：\(nextTaskText)")
                            .font(.caption)
                            .foregroundStyle(theme.text)
                            .lineLimit(1)
                    }
                }
                Text(paper.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(theme.weakText.opacity(0.82))
                if paper.kind == .todo && !paper.todoItems.isEmpty {
                    HStack(spacing: 8) {
                        ProgressView(value: progress)
                            .tint(theme.active)
                            .scaleEffect(x: 1, y: 0.65, anchor: .center)
                        Text("\(Int(progress * 100))%")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(theme.active)
                            .monospacedDigit()
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Label(statusText, systemImage: paper.isPinned ? "pin.fill" : (paper.kind == .todo && progress == 1 ? "checkmark.seal.fill" : icon))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(paper.isPinned || (paper.kind == .todo && progress == 1) ? theme.active : theme.weakText)
                    .labelStyle(.iconOnly)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.weakText.opacity(0.5))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                .fill(theme.surfaceGradient)
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
        .shadow(color: theme.shadow.opacity(0.75), radius: 3, y: 1)
        .shadow(color: theme.shadow.opacity(0.48), radius: 16, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(paper.title.isEmpty ? (paper.kind == .todo ? "待办" : "笔记") : paper.title)，\(statusText)")
        .accessibilityHint("双击打开")
        .contextMenu {
            Button(action: onTogglePin) {
                Label(paper.isPinned ? "取消置顶" : "置顶", systemImage: "pin")
            }
        }
    }
}

struct HomeOverview: View {
    let papers: [Paper]
    let theme: PaperPalette

    private var metrics: OverviewMetrics {
        papers.reduce(into: OverviewMetrics()) { metrics, paper in
            if paper.isPinned { metrics.pinnedCount += 1 }
            switch paper.kind {
            case .todo:
                metrics.totalTodoCount += paper.todoItems.count
                metrics.completedTodoCount += paper.todoItems.filter(\.isDone).count
                metrics.pendingCount += paper.todoItems.filter { !$0.isDone }.count
            case .note:
                metrics.noteCount += 1
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("今日工作台")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.text)
                    Text(metrics.pendingCount == 0 ? "所有待办都已处理" : "还有 \(metrics.pendingCount) 项待办等待处理")
                        .font(.caption)
                        .foregroundStyle(theme.weakText)
                }
                Spacer()
                Image(systemName: metrics.pendingCount == 0 ? "checkmark.seal.fill" : "sparkles")
                    .font(.title2)
                    .foregroundStyle(metrics.pendingCount == 0 ? theme.active : theme.tint)
            }

            HStack(spacing: 0) {
                overviewMetric(value: papers.count, label: "纸片")
                Divider()
                    .frame(height: 24)
                    .opacity(0.45)
                overviewMetric(value: metrics.pendingCount, label: "待办")
                Divider()
                    .frame(height: 24)
                    .opacity(0.45)
                overviewMetric(value: metrics.noteCount, label: "笔记")
                Divider()
                    .frame(height: 24)
                    .opacity(0.45)
                overviewMetric(value: metrics.pinnedCount, label: "置顶")
            }
            .padding(.vertical, 10)
            .background(theme.surfaceGradient.opacity(0.72), in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous)
                    .stroke(theme.paperBorder.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: theme.shadow.opacity(0.4), radius: 10, y: 4)

            HStack(spacing: 10) {
                Image(systemName: metrics.completionRate == 1 ? "checkmark.circle.fill" : "chart.bar.fill")
                    .foregroundStyle(metrics.completionRate == 1 ? theme.active : theme.tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text("待办完成率")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.weakText)
                    ProgressView(value: metrics.completionRate)
                        .tint(metrics.completionRate == 1 ? theme.active : theme.tint)
                }
                Text("\(Int(metrics.completionRate * 100))%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.text)
                    .monospacedDigit()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(theme.paper.opacity(0.34), in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
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

private struct OverviewMetrics {
    var noteCount = 0
    var pendingCount = 0
    var pinnedCount = 0
    var totalTodoCount = 0
    var completedTodoCount = 0

    var completionRate: Double {
        guard totalTodoCount > 0 else { return 1 }
        return Double(completedTodoCount) / Double(totalTodoCount)
    }
}

private struct UndoDeletionBanner: View {
    let papers: [Paper]
    let theme: PaperPalette
    let onUndo: (Paper) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "trash.slash")
                .foregroundStyle(theme.danger)
            Text("已移除 \(papers.count) 张纸片")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.text)
            Spacer(minLength: 8)
            Menu {
                ForEach(papers) { paper in
                    Button(paper.title.isEmpty ? (paper.kind == .todo ? "待办" : "笔记") : paper.title) {
                        onUndo(paper)
                    }
                }
            } label: {
                Text("撤销")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.active)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(theme.paperBorder.opacity(0.7), lineWidth: 1))
        .shadow(color: theme.shadow.opacity(0.55), radius: 12, y: 4)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("已移除 \(papers.count) 张纸片，可选择撤销")
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
                        .background(Capsule().fill(theme.accentGradient))
                }
                .buttonStyle(PaperPressStyle())
                Button(action: onAddNote) {
                    Label("笔记纸", systemImage: "note.text")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(theme.active)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(theme.paper.opacity(0.72)))
                        .overlay(Capsule().stroke(theme.active.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(PaperPressStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.backgroundGradient.ignoresSafeArea())
    }
}
