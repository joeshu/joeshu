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
                    PaperSwipeDeleteRow(
                        paper: paper,
                        theme: theme,
                        onTogglePin: { onTogglePin(paper) },
                        onToggleCollapse: { onToggleCollapse(paper) },
                        onPreview: { onPreview(paper) },
                        onDelete: { onDelete(paper) }
                    )
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

private struct PaperSwipeDeleteRow: View {
    let paper: Paper
    let theme: PaperPalette
    let onTogglePin: () -> Void
    let onToggleCollapse: () -> Void
    let onPreview: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    private let deleteWidth: CGFloat = 84

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteAction

            NavigationLink(value: paper) {
                PaperCard(paper: paper, theme: theme) { onTogglePin() }
            }
            .buttonStyle(PaperPressStyle())
            .contextMenu {
                Button { onTogglePin() } label: {
                    Label(paper.isPinned ? "取消置顶" : "置顶", systemImage: "pin")
                }
                Button { onToggleCollapse() } label: {
                    Label(paper.isCollapsed ? "展开纸片" : "折叠纸片", systemImage: paper.isCollapsed ? "rectangle.expand.vertical" : "rectangle.compress.vertical")
                }
                Button { onPreview() } label: {
                    Label("快速预览", systemImage: "eye")
                }
                Button(role: .destructive) { onDelete() } label: {
                    Label("删除纸片", systemImage: "trash")
                }
            }
            .offset(x: offset)
            .contentShape(Rectangle())
        }
        .clipped()
        .contentShape(Rectangle())
        .simultaneousGesture(swipeGesture)
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "删除纸片") {
            onDelete()
        }
    }

    private var deleteAction: some View {
        Button(role: .destructive) {
            onDelete()
            withAnimation(.easeOut(duration: 0.18)) {
                offset = 0
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "trash.fill")
                    .font(.system(size: PaperIconSize.medium, weight: .semibold))
                Text("删除")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(theme.onAccent)
            .frame(width: deleteWidth)
            .frame(maxHeight: .infinity)
            .background(theme.danger, in: RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("删除纸片")
        .opacity(offset == 0 ? 0 : 1)
        .allowsHitTesting(offset != 0)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { value in
                let translation = value.translation.width
                if translation < 0 {
                    offset = max(-deleteWidth, translation)
                } else if offset < 0 {
                    offset = min(0, -deleteWidth + translation)
                }
            }
            .onEnded { value in
                let shouldReveal = value.translation.width < -(deleteWidth * 0.45)
                    || value.predictedEndTranslation.width < -(deleteWidth * 0.8)
                withAnimation(.easeOut(duration: 0.18)) {
                    offset = shouldReveal ? -deleteWidth : 0
                }
            }
    }
}
