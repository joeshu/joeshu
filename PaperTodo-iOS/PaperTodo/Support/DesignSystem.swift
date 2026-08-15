import SwiftUI

enum PaperSpacing {
    static let hairline: CGFloat = 1
    static let micro: CGFloat = 4
    static let compact: CGFloat = 8
    static let control: CGFloat = 12
    static let content: CGFloat = 16
    static let section: CGFloat = 24
    static let feature: CGFloat = 32
}

enum PaperRadius {
    static let small: CGFloat = 4
    static let control: CGFloat = 8
    static let block: CGFloat = 12
    static let shell: CGFloat = 16
}

enum PaperIconSize {
    static let small: CGFloat = 16
    static let medium: CGFloat = 20
    static let large: CGFloat = 28
}

enum PaperElevation {
    case flat
    case raised
    case floating

    var shadowRadius: CGFloat {
        switch self {
        case .flat: return 0
        case .raised: return 8
        case .floating: return 18
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .flat: return 0
        case .raised: return 3
        case .floating: return 7
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .flat: return 0
        case .raised: return 0.16
        case .floating: return 0.22
        }
    }
}

enum PaperTypography {
    static let eyebrow = Font.system(.caption, design: .rounded).weight(.semibold)
    static let sectionTitle = Font.system(.headline, design: .rounded).weight(.bold)
    static let body = Font.system(.body, design: .default)
    static let metadata = Font.system(.caption, design: .default)
    static let statistic = Font.system(.title3, design: .rounded).weight(.bold)
}

struct PaperSurface<Content: View>: View {
    let palette: PaperPalette
    let elevation: PaperElevation
    let content: Content

    init(
        palette: PaperPalette,
        elevation: PaperElevation = .flat,
        @ViewBuilder content: () -> Content
    ) {
        self.palette = palette
        self.elevation = elevation
        self.content = content()
    }

    var body: some View {
        content
            .padding(PaperSpacing.content)
            .background(palette.surfaceGradient, in: RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                    .stroke(palette.paperBorder.opacity(0.58), lineWidth: PaperSpacing.hairline)
            }
            .shadow(
                color: palette.shadow.opacity(elevation.shadowOpacity),
                radius: elevation.shadowRadius,
                y: elevation.shadowY
            )
    }
}

struct PaperCardModifier: ViewModifier {
    let palette: PaperPalette
    var elevation: PaperElevation = .raised

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, PaperSpacing.content)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                    .fill(palette.surfaceGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                    .stroke(palette.paperBorder.opacity(0.5), lineWidth: 1)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                    .stroke(palette.highlight, lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .shadow(
                color: palette.shadow.opacity(elevation.shadowOpacity),
                radius: elevation.shadowRadius,
                y: elevation.shadowY
            )
    }
}

extension View {
    func paperCard(_ palette: PaperPalette, elevation: PaperElevation = .raised) -> some View {
        modifier(PaperCardModifier(palette: palette, elevation: elevation))
    }
}

struct PaperPressStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.975

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct PaperPrimaryButtonStyle: ButtonStyle {
    let palette: PaperPalette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(palette.onAccent)
            .frame(minHeight: 44)
            .padding(.horizontal, PaperSpacing.control)
            .background(palette.brandAction, in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct PaperSecondaryButtonStyle: ButtonStyle {
    let palette: PaperPalette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(palette.active)
            .frame(minHeight: 44)
            .padding(.horizontal, PaperSpacing.control)
            .background(palette.paper.opacity(0.5), in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous)
                    .stroke(palette.paperBorder.opacity(0.8), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct PaperIconButtonStyle: ButtonStyle {
    let palette: PaperPalette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: PaperIconSize.medium, weight: .semibold))
            .foregroundStyle(palette.active)
            .frame(width: 44, height: 44)
            .background(palette.paper.opacity(configuration.isPressed ? 0.82 : 0.46), in: Circle())
            .overlay {
                Circle()
                    .stroke(palette.paperBorder.opacity(0.7), lineWidth: 1)
            }
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct PaperFilterChipStyle: ButtonStyle {
    let palette: PaperPalette
    let selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .foregroundStyle(selected ? palette.onAccent : palette.text)
            .frame(minHeight: 36)
            .padding(.horizontal, PaperSpacing.control)
            .background(selected ? palette.brandAction : palette.paper.opacity(0.52), in: Capsule())
            .overlay {
                if !selected {
                    Capsule().stroke(palette.paperBorder.opacity(0.72), lineWidth: 1)
                }
            }
            .opacity(configuration.isPressed ? 0.78 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

extension PaperPalette {
    var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [paper.opacity(0.98), paper.opacity(0.86)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var highlight: Color { text.opacity(0.12) }
    var shadow: Color { Color.black.opacity(0.22) }
}

struct AnimatedCheckCircle: View {
    let isDone: Bool
    let tint: Color
    var untinted: Color = Color.secondary
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(isDone ? tint : untinted.opacity(0.5), lineWidth: 1.8)
            if isDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 24, height: 24)
        .background(
            Circle()
                .fill(isDone ? tint : Color.clear)
                .scaleEffect(isDone ? 1 : 0.6)
                .opacity(isDone ? 1 : 0)
        )
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.6), value: isDone)
    }
}
