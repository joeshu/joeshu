import SwiftUI
import Observation

enum TodoVisualSize: String, CaseIterable, Identifiable {
    case small = "小"
    case medium = "中"
    case large = "大"
    var id: String { rawValue }

    var fontSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 17
        case .large: return 21
        }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "跟随系统"
    case light = "浅色"
    case dark = "深色"
    var id: String { rawValue }
}

enum RenderStrength: Int, CaseIterable, Identifiable {
    case plain = 0
    case light = 1
    case full = 2
    var id: Int { rawValue }

    var label: String {
        switch self {
        case .plain: return "纯文本"
        case .light: return "轻渲染"
        case .full: return "完整渲染"
        }
    }
}

@Observable
final class AppSettings {
    var appearance: AppearanceMode {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: "appearance") }
    }
    var colorScheme: PaperColorScheme {
        didSet { UserDefaults.standard.set(colorScheme.rawValue, forKey: "colorScheme") }
    }
    var todoVisualSize: TodoVisualSize {
        didSet { UserDefaults.standard.set(todoVisualSize.rawValue, forKey: "todoVisualSize") }
    }
    var autoClearDone: Bool {
        didSet { UserDefaults.standard.set(autoClearDone, forKey: "autoClearDone") }
    }
    var renderStrength: RenderStrength {
        didSet { UserDefaults.standard.set(renderStrength.rawValue, forKey: "renderStrength") }
    }

    init() {
        let defaults = UserDefaults.standard
        appearance = AppearanceMode(rawValue: defaults.string(forKey: "appearance") ?? "") ?? .system
        colorScheme = PaperColorScheme(rawValue: defaults.string(forKey: "colorScheme") ?? "") ?? .warm
        todoVisualSize = TodoVisualSize(rawValue: defaults.string(forKey: "todoVisualSize") ?? "") ?? .medium
        autoClearDone = defaults.object(forKey: "autoClearDone") as? Bool ?? false
        renderStrength = RenderStrength(rawValue: defaults.integer(forKey: "renderStrength")) ?? .full
    }

    func palette(systemDark: Bool) -> PaperPalette {
        let dark: Bool
        switch appearance {
        case .system: dark = systemDark
        case .light: dark = false
        case .dark: dark = true
        }
        return PaperPalette.scheme(colorScheme, dark: dark)
    }
}

private struct AppSettingsKey: EnvironmentKey {
    static let defaultValue = AppSettings()
}

extension EnvironmentValues {
    var settings: AppSettings {
        get { self[AppSettingsKey.self] }
        set { self[AppSettingsKey.self] = newValue }
    }
}
