import SwiftUI
import SwiftData

struct NotePaperView: View {
    @Bindable var paper: Paper
    @Environment(\.modelContext) private var modelContext
    @State private var previewing = false

    var body: some View {
        Group {
            if previewing {
                ScrollView {
                    MarkdownTextView(markdown: paper.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                TextEditor(text: $paper.body)
                    .font(.body)
                    .padding(8)
                    .onChange(of: paper.body) { _, _ in
                        paper.updatedAt = Date()
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
                Button {
                    withAnimation {
                        previewing.toggle()
                    }
                } label: {
                    Image(systemName: previewing ? "pencil" : "eye")
                }
            }
        }
        .navigationTitle(paper.title.isEmpty ? "笔记" : paper.title)
    }
}
