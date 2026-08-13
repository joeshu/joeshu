import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct NotePaperView: View {
    @Bindable var paper: Paper
    @Environment(\.modelContext) private var modelContext
    @Environment(\.settings) private var settings
    @Environment(\.colorScheme) private var colorScheme
    @State private var previewing = false
    @State private var pickerItem: PhotosPickerItem?

    private var theme: PaperPalette {
        settings.palette(dark: colorScheme == .dark)
    }

    var body: some View {
        @Bindable var settings = settings
        Group {
            if previewing {
                ScrollView {
                    NoteRenderView(
                        markdown: paper.body,
                        strength: settings.renderStrength,
                        font: .body
                    )
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(theme.paper)
            } else {
                MarkdownEditorTextView(
                    text: $paper.body,
                    textColor: UIColor(settings.palette(dark: colorScheme == .dark).text),
                    baseFont: .systemFont(ofSize: 17)
                )
                .padding(.horizontal, 8)
                .background(theme.paper)
                .onChange(of: paper.body) { _, _ in
                    paper.updatedAt = Date()
                    try? modelContext.save()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image(systemName: "photo")
                }
                .onChange(of: pickerItem) { _, newItem in
                    if let newItem {
                        loadImage(from: newItem)
                    }
                }

                Button {
                    withAnimation {
                        paper.isPinned.toggle()
                        paper.updatedAt = Date()
                    }
                } label: {
                    Image(systemName: paper.isPinned ? "pin.fill" : "pin")
                }

                Menu {
                    Picker("渲染强度", selection: $settings.renderStrength) {
                        ForEach(RenderStrength.allCases) { strength in
                            Text(strength.label).tag(strength)
                        }
                    }
                } label: {
                    Image(systemName: "textformat")
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

    private func loadImage(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data),
               let name = NoteImageStore.save(image: image) {
                await MainActor.run {
                    let reference = "\n![图片](\(name))\n"
                    if paper.body.isEmpty {
                        paper.body = reference
                    } else {
                        paper.body += reference
                    }
                    paper.updatedAt = Date()
                    try? modelContext.save()
                }
            }
            pickerItem = nil
        }
    }
}
