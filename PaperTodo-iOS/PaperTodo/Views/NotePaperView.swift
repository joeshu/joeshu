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
    @State private var exportError: String?
    @State private var saveErrorMessage: String?
    @State private var taskImportMessage: String?
    @State private var saveTask: Task<Void, Never>?
    @State private var importGeneration = UUID()

    private var theme: PaperPalette {
        settings.palette(systemDark: colorScheme == .dark)
    }

    var body: some View {
        @Bindable var settings = settings
        VStack(alignment: .leading, spacing: 0) {
            TextField("纸片标题", text: $paper.title)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .onChange(of: paper.title) { _, _ in
                    paper.updatedAt = Date()
                    scheduleSave()
                }
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
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            } else {
                MarkdownEditorTextView(
                    text: $paper.body,
                    insertionRequest: $insertionRequest,
                    textColor: UIColor(theme.text),
                    baseFont: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17))
                )
                .padding(.horizontal, 8)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
                .background(theme.paper.opacity(0.15))
                .onDrop(of: [UTType.image.identifier, UTType.fileURL.identifier], isTargeted: nil) { providers in
                    loadDroppedImages(providers)
                    return true
                }
                .onChange(of: paper.body) { _, _ in
                    paper.updatedAt = Date()
                    scheduleSave()
                }
            }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(alignment: .bottom) {
            if pendingImports > 0 {
                Label {
                    Text("正在导入图片")
                } icon: {
                    ProgressView()
                        .controlSize(.small)
                }
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
                .accessibilityLabel("导入图片")
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
                .accessibilityLabel("粘贴图片")

                Button {
                    exportNote()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("导出笔记")

                Button {
                    withAnimation {
                        paper.isPinned.toggle()
                        paper.updatedAt = Date()
                    }
                } label: {
                    Image(systemName: paper.isPinned ? "pin.fill" : "pin")
                }
                .accessibilityLabel(paper.isPinned ? "取消置顶" : "置顶")

                Button {
                    withAnimation {
                        paper.isCollapsed.toggle()
                        paper.updatedAt = Date()
                    }
                } label: {
                    Image(systemName: paper.isCollapsed ? "rectangle.expand.vertical" : "rectangle.compress.vertical")
                }
                .accessibilityLabel(paper.isCollapsed ? "展开纸片" : "折叠纸片")

                Menu {
                    Picker("渲染强度", selection: $settings.renderStrength) {
                        ForEach(RenderStrength.allCases) { strength in
                            Text(strength.label).tag(strength)
                        }
                    }
                } label: {
                    Image(systemName: "textformat")
                }
                .accessibilityLabel("渲染强度")

                Button {
                    withAnimation {
                        previewing.toggle()
                    }
                } label: {
                    Image(systemName: previewing ? "pencil" : "eye")
                }
                .accessibilityLabel(previewing ? "编辑笔记" : "预览笔记")

                if !markdownTasks.isEmpty {
                    Button {
                        importMarkdownTasks()
                    } label: {
                        Image(systemName: "checklist")
                    }
                    .accessibilityLabel("导入 Markdown 任务")
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
        .alert("导出失败", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("好", role: .cancel) { }
        } message: {
            Text(exportError ?? "请重试。")
        }
        .alert("保存失败", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("好", role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? "无法保存更改。")
        }
        .alert("任务导入", isPresented: Binding(
            get: { taskImportMessage != nil },
            set: { if !$0 { taskImportMessage = nil } }
        )) {
            Button("好", role: .cancel) { }
        } message: {
            Text(taskImportMessage ?? "")
        }
        .onDisappear {
            importGeneration = UUID()
            saveTask?.cancel()
            saveContext()
        }
    }

    private func loadImage(from item: PhotosPickerItem) {
        let generation = importGeneration
        let referencedNames = NoteImageStore.referencedNames(in: paper.body)
        Task {
            await MainActor.run { startImport() }
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                await MainActor.run {
                    finishImport(name: nil, generation: generation)
                    pickerItem = nil
                }
                return
            }
            let name = await NoteImageImportQueue.shared.save(
                data: data,
                referencedNames: referencedNames
            )
            await MainActor.run {
                finishImport(name: name, generation: generation)
                pickerItem = nil
            }
        }
    }

    private func pasteImage() {
        let pasteboard = UIPasteboard.general
        let imageTypes = [UTType.png.identifier, UTType.jpeg.identifier, UTType.image.identifier]
        guard let data = imageTypes.lazy.compactMap({ pasteboard.data(forPasteboardType: $0) }).first else { return }
        let generation = importGeneration
        let referencedNames = NoteImageStore.referencedNames(in: paper.body)
        startImport()
        Task {
            let name = await NoteImageImportQueue.shared.save(
                data: data,
                referencedNames: referencedNames
            )
            await MainActor.run {
                finishImport(name: name, generation: generation)
            }
        }
    }

    private func loadDroppedImages(_ providers: [NSItemProvider]) {
        for provider in providers {
            let generation = importGeneration
            let referencedNames = NoteImageStore.referencedNames(in: paper.body)
            startImport()
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    guard let data else {
                        Task { @MainActor in finishImport(name: nil, generation: generation) }
                        return
                    }
                    Task {
                        let name = await NoteImageImportQueue.shared.save(
                            data: data,
                            referencedNames: referencedNames
                        )
                        await MainActor.run {
                            finishImport(name: name, generation: generation)
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    Task {
                        guard let url = item as? URL else {
                            await MainActor.run { finishImport(name: nil, generation: generation) }
                            return
                        }
                        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
                        guard let fileSize = values?.fileSize,
                              fileSize <= NoteImageStore.maxInputBytes,
                              let data = try? Data(contentsOf: url) else {
                            await MainActor.run { finishImport(name: nil, generation: generation) }
                            return
                        }
                        let name = await NoteImageImportQueue.shared.save(
                            data: data,
                            referencedNames: referencedNames
                        )
                        await MainActor.run {
                            finishImport(name: name, generation: generation)
                        }
                    }
                }
            }
        }
    }

    private func insertImageReference(_ name: String) {
        insertionRequest = (insertionRequest ?? "") + "\n![图片](\(name))\n"
        paper.updatedAt = Date()
        scheduleSave()
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            saveContext()
        }
    }

    private var markdownTasks: [String] {
        paper.body.components(separatedBy: .newlines).compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("- [ ]") else { return nil }
            let task = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            return task.isEmpty ? nil : task
        }
    }

    private func importMarkdownTasks() {
        let tasks = markdownTasks
        guard !tasks.isEmpty else { return }
        do {
            let papers = try modelContext.fetch(FetchDescriptor<Paper>())
            let inbox = papers.first(where: { $0.kind == .todo && $0.title == "收件箱" }) ?? Paper(kind: .todo, title: "收件箱")
            if !papers.contains(where: { $0.id == inbox.id }) {
                modelContext.insert(inbox)
            }
            let existing = Set(inbox.todoItems.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) })
            var imported = 0
            for task in tasks where !existing.contains(task) {
                inbox.todoItems.append(TodoItem(text: task, sortIndex: inbox.todoItems.count))
                imported += 1
            }
            inbox.updatedAt = Date()
            try modelContext.save()
            taskImportMessage = imported == 0 ? "收件箱中已经有这些任务。" : "已导入 \(imported) 项任务到收件箱。"
        } catch {
            taskImportMessage = "导入失败：\(error.localizedDescription)"
        }
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func exportNote() {
        let title = paper.title
        let body = paper.body
        Task.detached(priority: .userInitiated) {
            let url = NoteExportStore.writeMarkdownPackage(title: title, body: body)
            await MainActor.run {
                if let url {
                    exportURL = url
                } else {
                    exportError = "导出失败，无法写入临时文件。"
                }
            }
        }
    }

    private func startImport() {
        pendingImports += 1
    }

    private func finishImport(name: String?, generation: UUID? = nil) {
        guard generation == nil || generation == importGeneration else {
            pendingImports = max(0, pendingImports - 1)
            return
        }
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
