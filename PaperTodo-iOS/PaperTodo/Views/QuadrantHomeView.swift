import SwiftUI
import SwiftData

struct QuadrantHomeView: View {
    let papers: [Paper]
    let theme: PaperPalette
    @Environment(\.modelContext) private var modelContext

    private let quadrants: [(String, String, Color)] = [
        ("重要且紧急", "立即处理", .red),
        ("重要不紧急", "安排计划", .orange),
        ("不重要但紧急", "尽快委派", .blue),
        ("不重要不紧急", "适度安排", .green)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("四象限").font(.title2.weight(.bold)).foregroundStyle(theme.text)
                Text("按重要性和紧急性整理待办")
                    .font(.caption)
                    .foregroundStyle(theme.weakText)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(Array(quadrants.enumerated()), id: \.offset) { index, quadrant in
                        quadrantCard(index: index, title: quadrant.0, subtitle: quadrant.1, color: quadrant.2)
                    }
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
    }

    private func quadrantCard(index: Int, title: String, subtitle: String, color: Color) -> some View {
        let tasks = papers.flatMap(\.todoItems).filter { item in
            guard !item.isDone else { return false }
            return quadrantIndex(for: item) == index
        }
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Circle().fill(color).frame(width: 12, height: 12)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.subheadline.weight(.bold))
                    Text(subtitle).font(.caption2)
                }
                Spacer()
                Text("\(tasks.count)").font(.caption.weight(.bold)).monospacedDigit()
            }
            .foregroundStyle(theme.text)
            if tasks.isEmpty {
                Text("暂无任务").font(.caption).foregroundStyle(theme.weakText)
            } else {
                ForEach(tasks.prefix(5)) { item in
                    Button {
                        item.isDone.toggle()
                        item.paper?.updatedAt = Date()
                        try? modelContext.save()
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "square").foregroundStyle(color)
                            Text(item.text).lineLimit(2)
                            Spacer(minLength: 0)
                        }
                        .font(.caption)
                        .foregroundStyle(theme.text)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .background(theme.surfaceGradient, in: RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous).stroke(color.opacity(0.35), lineWidth: 1))
    }

    private func quadrantIndex(for item: TodoItem) -> Int {
        let text = item.text.lowercased()
        let urgent = text.contains("紧急") || text.contains("今天") || text.contains("马上")
        let important = text.contains("重要") || text.contains("项目") || text.contains("截止")
        switch (important, urgent) {
        case (true, true): return 0
        case (true, false): return 1
        case (false, true): return 2
        case (false, false): return 3
        }
    }
}
