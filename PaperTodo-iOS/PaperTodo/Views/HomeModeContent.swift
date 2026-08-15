import SwiftUI

struct HomeModeContent: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var mode: HomeMode
    let papers: [Paper]
    let visiblePapers: [Paper]
    @Binding var filter: PaperFilter
    let filterCounts: PaperFilterCounts
    let theme: PaperPalette
    let onTogglePin: (Paper) -> Void
    let onToggleCollapse: (Paper) -> Void
    let onPreview: (Paper) -> Void
    let onDelete: (Paper) -> Void
    let onAddTodo: () -> Void
    let onAddNote: () -> Void
    let onQuickCapture: () -> Void

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
                    WorkPerspectiveNavigation(mode: $mode, theme: theme, vertical: true)
                        .frame(width: 184)
                    content
                }
            } else {
                content
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        WorkPerspectiveNavigation(mode: $mode, theme: theme)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                            .background(.ultraThinMaterial)
                    }
            }
        }
        .background(theme.backgroundGradient.ignoresSafeArea())
    }

    @ViewBuilder
    private var content: some View {
        Group {
            switch mode {
            case .today:
                TodayHomeView(papers: papers, theme: theme, onQuickCapture: onQuickCapture)
            case .list:
                if papers.isEmpty {
                    EmptyStateView(
                        theme: theme,
                        onAddTodo: onAddTodo,
                        onAddNote: onAddNote
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    PaperListHome(
                        visiblePapers: visiblePapers,
                        filter: $filter,
                        filterCounts: filterCounts,
                        theme: theme,
                            onAddTodo: onAddTodo,
                            onAddNote: onAddNote,
                            onTogglePin: onTogglePin,
                        onToggleCollapse: onToggleCollapse,
                        onPreview: onPreview,
                        onDelete: onDelete
                    )
                }
            case .calendar:
                CalendarHomeView(theme: theme)
            case .quadrant:
                QuadrantHomeView(papers: papers, theme: theme)
            }
        }
        .frame(maxWidth: 800)
        .frame(maxWidth: .infinity)
    }
}

private struct WorkPerspectiveNavigation: View {
    @Binding var mode: HomeMode
    let theme: PaperPalette
    var vertical = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if vertical {
                VStack(alignment: .leading, spacing: PaperSpacing.compact) {
                    navigationLabel
                    navigationItems
                }
                .padding(.horizontal, PaperSpacing.control)
                .padding(.vertical, PaperSpacing.content)
            } else {
                HStack(spacing: PaperSpacing.compact) {
                    navigationItems
                }
                .padding(.horizontal, PaperSpacing.compact)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("工作视角导航")
    }

    private var navigationLabel: some View {
        Text("工作视角")
            .font(PaperTypography.eyebrow)
            .foregroundStyle(theme.weakText)
            .padding(.horizontal, PaperSpacing.compact)
    }

    @ViewBuilder
    private var navigationItems: some View {
        ForEach(HomeMode.allCases) { item in
            Button {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                    mode = item
                }
            } label: {
                Label(item.rawValue, systemImage: item.symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(mode == item ? theme.onAccent : theme.text)
                    .frame(maxWidth: vertical ? .infinity : nil, minHeight: 44)
                    .padding(.horizontal, vertical ? PaperSpacing.control : 10)
                    .background(
                        mode == item ? theme.brandAction : theme.paper.opacity(vertical ? 0.26 : 0.42),
                        in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous)
                    )
                    .overlay {
                        if mode != item {
                            RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous)
                                .stroke(theme.paperBorder.opacity(vertical ? 0.45 : 0.6), lineWidth: 1)
                        }
                    }
            }
            .buttonStyle(PaperPressStyle(pressedScale: 0.98))
            .accessibilityAddTraits(mode == item ? .isSelected : [])
            .accessibilityLabel(item.rawValue)
            .accessibilityValue(mode == item ? "当前视角" : "")
            .accessibilityHint("切换工作视角")
        }
    }
}

private struct PaperListHome: View {
    let visiblePapers: [Paper]
    @Binding var filter: PaperFilter
    let filterCounts: PaperFilterCounts
    let theme: PaperPalette
    let onAddTodo: () -> Void
    let onAddNote: () -> Void
    let onTogglePin: (Paper) -> Void
    let onToggleCollapse: (Paper) -> Void
    let onPreview: (Paper) -> Void
    let onDelete: (Paper) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                paperIndexHeader
                HomeOverview(papers: visiblePapers, theme: theme)
                    .padding(.bottom, 2)
                PaperFilterBar(filter: $filter, counts: filterCounts, theme: theme)
                if visiblePapers.isEmpty {
                    FilterEmptyState(
                        filter: filter,
                        theme: theme,
                        onAddTodo: onAddTodo,
                        onAddNote: onAddNote
                    )
                        .padding(.vertical, 30)
                }
                ForEach(visiblePapers) { paper in
                    NavigationLink(value: paper) {
                        PaperCard(paper: paper, theme: theme) { onTogglePin(paper) }
                    }
                    .buttonStyle(PaperPressStyle())
                    .contextMenu {
                        Button { onTogglePin(paper) } label: {
                            Label(paper.isPinned ? "取消置顶" : "置顶", systemImage: "pin")
                        }
                        Button { onToggleCollapse(paper) } label: {
                            Label(paper.isCollapsed ? "展开纸片" : "折叠纸片", systemImage: paper.isCollapsed ? "rectangle.expand.vertical" : "rectangle.compress.vertical")
                        }
                        Button { onPreview(paper) } label: {
                            Label("快速预览", systemImage: "eye")
                        }
                        Button(role: .destructive) { onDelete(paper) } label: {
                            Label("删除纸片", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) { onDelete(paper) } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
    }

    private var paperIndexHeader: some View {
        HStack(alignment: .center, spacing: PaperSpacing.control) {
            VStack(alignment: .leading, spacing: PaperSpacing.micro) {
                Text("纸片")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.text)
                Text("你的工作内容")
                    .font(PaperTypography.metadata)
                    .foregroundStyle(theme.weakText)
            }
            Spacer(minLength: PaperSpacing.compact)
            HStack(spacing: PaperSpacing.compact) {
                Button(action: onAddTodo) {
                    Image(systemName: "checklist")
                }
                .buttonStyle(PaperIconButtonStyle(palette: theme))
                .accessibilityLabel("新建待办纸片")

                Button(action: onAddNote) {
                    Image(systemName: "note.text")
                }
                .buttonStyle(PaperIconButtonStyle(palette: theme))
                .accessibilityLabel("新建笔记纸片")
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }
}
