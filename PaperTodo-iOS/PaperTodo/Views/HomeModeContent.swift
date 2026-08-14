import SwiftUI

struct HomeModeContent: View {
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

    var body: some View {
        VStack(spacing: 0) {
            Picker("首页模式", selection: $mode) {
                ForEach(HomeMode.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .tint(theme.active)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 4)
            .accessibilityLabel("首页模式")

            Group {
                switch mode {
                case .list:
                    PaperListHome(
                        visiblePapers: visiblePapers,
                        filter: $filter,
                        filterCounts: filterCounts,
                        theme: theme,
                        onTogglePin: onTogglePin,
                        onToggleCollapse: onToggleCollapse,
                        onPreview: onPreview,
                        onDelete: onDelete
                    )
                case .calendar:
                    CalendarHomeView(theme: theme)
                case .quadrant:
                    QuadrantHomeView(papers: papers, theme: theme)
                }
            }
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
        }
        .background(theme.backgroundGradient.ignoresSafeArea())
    }
}

private struct PaperListHome: View {
    let visiblePapers: [Paper]
    @Binding var filter: PaperFilter
    let filterCounts: PaperFilterCounts
    let theme: PaperPalette
    let onTogglePin: (Paper) -> Void
    let onToggleCollapse: (Paper) -> Void
    let onPreview: (Paper) -> Void
    let onDelete: (Paper) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                HomeOverview(papers: visiblePapers, theme: theme)
                    .padding(.bottom, 2)
                PaperFilterBar(filter: $filter, counts: filterCounts, theme: theme)
                if visiblePapers.isEmpty {
                    FilterEmptyState(filter: filter, theme: theme)
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
}
