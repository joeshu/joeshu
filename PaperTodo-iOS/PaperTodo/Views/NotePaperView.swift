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
                        font: .system(.body, design: .rounded),
                        textColor: theme.text
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: PaperRadius.shell, style: .continuous)
                            .fill(theme.paper)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: PaperRadius.shell, style: .continuous)
                            .stroke(theme.paperBorder.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.10), radius: 14, y: 2)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(theme.paper.opacity(0.15))
                .scrollIndicators(.hidden)
            } else {
                MarkdownEditorTextView(
                    text: $paper.body,
                    textColor: UIColor(theme.text),
                    baseFont: .systemFont(ofSize: 17)
                )
                .padding(.horizontal, 8)
                .background(theme.paper.opacity(0.15))
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
