import SwiftUI
import SwiftData
import PhotosUI
import UIKit
import UniformTypeIdentifiers

struct NotePaperView: View {
    @Bindable var paper: Paper
    @Environment(\.modelContext) private var modelContext
    @Environment(\.settings) private var settings
    @Environment(\.colorScheme) private var colorScheme
    @State private var previewing = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var insertionRequest: String?
    @State private var exportURL: URL?
    @State private var pendingImports = 0
    @State private var importError: String?

    private var theme: PaperPalette {
        settings.palette(systemDark: colorScheme == .dark)
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
                        textColor: theme.text,
                        palette: theme
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: PaperRadius.shell, style: .continuous)
                            .fill(theme.surfaceGradient)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: PaperRadius.shell, style: .continuous)
                            .stroke(theme.paperBorder.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: theme.shadow.opacity(0.65), radius: 3, y: 1)
                    .shadow(color: theme.shadow.opacity(0.42), radius: 16, y: 6)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(theme.paper.opacity(0.15))
                .scrollIndicators(.hidden)
            } else {
                MarkdownEditorTextView(
                    text: $paper.body,
                    insertionRequest: $insertionRequest,
                    textColor: UIColor(theme.text),
                    baseFont: .systemFont(ofSize: 17)
                )
                .padding(.horizontal, 8)
                .background(theme.paper.opacity(0.15))
                .onDrop(of: [UTType.image.identifier, UTType.fileURL.identifier], isTargeted: nil) { providers in
                    loadDroppedImages(providers)
                    return true
                }
                .onChange(of: paper.body) { _, _ in
                    paper.updatedAt = Date()
                    try? modelContext.save()
                }
            }
        }
        .overlay(alignment: .bottom) {
            if pendingImports > 0 {
                Label("正在导入图片", systemImage: "arrow.down.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 12)
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
                    pasteImage()
                } label: {
                    Image(systemName: "doc.on.clipboard")
                }

                Button {
                    exportURL = NoteExportStore.writeMarkdownPackage(title: paper.title, body: paper.body)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }

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
                        paper.isCollapsed.toggle()
                        paper.updatedAt = Date()
                    }
                } label: {
                    Image(systemName: paper.isCollapsed ? "rectangle.expand.vertical" : "rectangle.compress.vertical")
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
        .sheet(
            isPresented: Binding(
                get: { exportURL != nil },
                set: { if !$0 { exportURL = nil } }
            )
        ) {
            if let exportURL {
                ActivityView(activityItems: [exportURL])
            }
        }
        .alert("图片导入失败", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("好", role: .cancel) { }
        } message: {
            Text(importError ?? "无法处理这张图片。")
        }
    }

    private func loadImage(from item: PhotosPickerItem) {
        Task {
            await MainActor.run { startImport() }
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                await MainActor.run {
                    finishImport(name: nil)
                    pickerItem = nil
                }
                return
            }
            let name = await NoteImageImportQueue.shared.save(data: data)
            await MainActor.run {
                finishImport(name: name)
                pickerItem = nil
            }
        }
    }

    private func pasteImage() {
        let pasteboard = UIPasteboard.general
        let imageTypes = [UTType.png.identifier, UTType.jpeg.identifier, UTType.image.identifier]
        guard let data = imageTypes.lazy.compactMap({ pasteboard.data(forPasteboardType: $0) }).first else { return }
        startImport()
        Task {
            let name = await NoteImageImportQueue.shared.save(data: data)
            await MainActor.run {
                finishImport(name: name)
            }
        }
    }

    private func loadDroppedImages(_ providers: [NSItemProvider]) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    guard let data else { return }
                    Task {
                        await MainActor.run { startImport() }
                        let name = await NoteImageImportQueue.shared.save(data: data)
                        await MainActor.run {
                            finishImport(name: name)
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    Task {
                        await MainActor.run { startImport() }
                        guard let url = item as? URL,
                              let data = try? Data(contentsOf: url) else {
                            await MainActor.run { finishImport(name: nil) }
                            return
                        }
                        let name = await NoteImageImportQueue.shared.save(data: data)
                        await MainActor.run {
                            finishImport(name: name)
                        }
                    }
                }
            }
        }
    }

    private func insertImageReference(_ name: String) {
        insertionRequest = (insertionRequest ?? "") + "\n![图片](\(name))\n"
        paper.updatedAt = Date()
        try? modelContext.save()
    }

    private func startImport() {
        pendingImports += 1
    }

    private func finishImport(name: String?) {
        pendingImports = max(0, pendingImports - 1)
        if let name {
            insertImageReference(name)
        } else {
            importError = "图片读取或压缩失败，请换一张图片重试。"
        }
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) { }
}
