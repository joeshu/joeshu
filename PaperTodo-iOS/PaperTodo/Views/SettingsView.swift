import SwiftUI

struct SettingsView: View {
    @Environment(\.settings) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("外观") {
                Picker("显示模式", selection: $settings.appearance) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                Picker("纸张配色", selection: $settings.colorScheme) {
                    ForEach(PaperColorScheme.allCases) { scheme in
                        Text(scheme.rawValue).tag(scheme)
                    }
                }
            }
            Section("待办") {
                Picker("文字大小", selection: $settings.todoVisualSize) {
                    ForEach(TodoVisualSize.allCases) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                Toggle("完成后自动清除", isOn: $settings.autoClearDone)
            }
            Section("笔记") {
                Picker("Markdown 渲染", selection: $settings.renderStrength) {
                    ForEach(RenderStrength.allCases) { strength in
                        Text(strength.label).tag(strength)
                    }
                }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}
