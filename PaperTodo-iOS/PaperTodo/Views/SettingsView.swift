import SwiftUI

struct SettingsView: View {
    @Environment(\.settings) private var settings
    @Environment(\.colorScheme) private var colorScheme

    private var theme: PaperPalette {
        settings.palette(systemDark: colorScheme == .dark)
    }

    var body: some View {
        @Bindable var settings = settings
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                settingsSection("外观", systemImage: "paintpalette", theme: theme) {
                    PickerRow(title: "显示模式", value: settings.appearance.rawValue, theme: theme) {
                        Picker("显示模式", selection: $settings.appearance) {
                            ForEach(AppearanceMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                    }
                    PickerRow(title: "纸张配色", value: settings.colorScheme.rawValue, theme: theme) {
                        Picker("纸张配色", selection: $settings.colorScheme) {
                            ForEach(PaperColorScheme.allCases) { scheme in
                                Text(scheme.rawValue).tag(scheme)
                            }
                        }
                    }
                }

                settingsSection("待办", systemImage: "checklist", theme: theme) {
                    PickerRow(title: "文字大小", value: settings.todoVisualSize.rawValue, theme: theme) {
                        Picker("文字大小", selection: $settings.todoVisualSize) {
                            ForEach(TodoVisualSize.allCases) { size in
                                Text(size.rawValue).tag(size)
                            }
                        }
                    }
                    ToggleRow(title: "完成后自动清除", isOn: $settings.autoClearDone, theme: theme)
                }

                settingsSection("笔记", systemImage: "note.text", theme: theme) {
                    PickerRow(title: "Markdown 渲染", value: settings.renderStrength.label, theme: theme) {
                        Picker("Markdown 渲染", selection: $settings.renderStrength) {
                            ForEach(RenderStrength.allCases) { strength in
                                Text(strength.label).tag(strength)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(theme.paper.opacity(0.22).ignoresSafeArea())
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func settingsSection<Content: View>(
        _ title: String,
        systemImage: String,
        theme: PaperPalette,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(theme.text)
            VStack(spacing: 0) {
                content()
            }
            .background(theme.paper, in: RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                    .stroke(theme.paperBorder.opacity(0.65), lineWidth: 1)
            }
        }
    }
}

private struct PickerRow<PickerContent: View>: View {
    let title: String
    let theme: PaperPalette
    let picker: PickerContent

    init(
        title: String,
        value: String,
        theme: PaperPalette,
        @ViewBuilder picker: () -> PickerContent
    ) {
        self.title = title
        self.theme = theme
        self.picker = picker()
    }

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(theme.text)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(theme.weakText)
            picker
                .labelsHidden()
                .pickerStyle(.menu)
                .tint(theme.active)
                .foregroundStyle(theme.weakText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

private struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    let theme: PaperPalette

    var body: some View {
        Toggle(title, isOn: $isOn)
            .tint(theme.active)
            .foregroundStyle(theme.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
    }
}
