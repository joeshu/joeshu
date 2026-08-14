import SwiftUI

struct SettingsView: View {
    @Environment(\.settings) private var settings
    @Environment(\.colorScheme) private var colorScheme

    private var theme: PaperPalette {
        settings.palette(systemDark: colorScheme == .dark)
    }

    private var effectiveDarkMode: Bool {
        switch settings.appearance {
        case .system: return colorScheme == .dark
        case .light: return false
        case .dark: return true
        }
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
                    ThemePickerRow(selection: $settings.colorScheme, dark: effectiveDarkMode)
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
            .background(theme.surfaceGradient, in: RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                    .stroke(theme.paperBorder.opacity(0.65), lineWidth: 1)
            }
            .shadow(color: theme.shadow.opacity(0.48), radius: 14, y: 5)
        }
    }
}

private struct PickerRow<PickerContent: View>: View {
    let title: String
    let value: String
    let theme: PaperPalette
    let picker: PickerContent

    init(
        title: String,
        value: String,
        theme: PaperPalette,
        @ViewBuilder picker: () -> PickerContent
    ) {
        self.title = title
        self.value = value
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)，\(value)")
        .accessibilityHint("打开菜单选择")
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

private struct ThemePickerRow: View {
    @Binding var selection: PaperColorScheme
    let dark: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("纸张配色")
                    .foregroundStyle(currentPalette.text)
                Spacer()
                Text(selection.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(currentPalette.active)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 10)], spacing: 10) {
                ForEach(PaperColorScheme.allCases) { scheme in
                    let palette = PaperPalette.scheme(scheme, dark: dark)
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selection = scheme
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous)
                                    .fill(palette.surfaceGradient)
                                    .frame(height: 42)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous)
                                            .stroke(palette.paperBorder.opacity(0.85), lineWidth: 1)
                                    }
                                    .overlay(alignment: .bottomLeading) {
                                        HStack(spacing: 3) {
                                            Circle().fill(palette.active).frame(width: 7, height: 7)
                                            Capsule().fill(palette.text.opacity(0.55)).frame(width: 18, height: 3)
                                        }
                                        .padding(7)
                                    }

                                if selection == scheme {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(palette.active)
                                        .padding(5)
                                }
                            }
                            Text(scheme.rawValue)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(currentPalette.text)
                        }
                    }
                    .buttonStyle(PaperPressStyle(pressedScale: 0.96))
                    .accessibilityLabel("纸张配色：\(scheme.rawValue)")
                    .accessibilityAddTraits(selection == scheme ? .isSelected : [])
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var currentPalette: PaperPalette {
        PaperPalette.scheme(selection, dark: dark)
    }
}
