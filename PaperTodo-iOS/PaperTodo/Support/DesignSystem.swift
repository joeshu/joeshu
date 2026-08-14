import SwiftUI

enum PaperRadius {
    static let small: CGFloat = 4
    static let control: CGFloat = 8
    static let block: CGFloat = 12
    static let shell: CGFloat = 16
}

struct PaperCardModifier: ViewModifier {
    let palette: PaperPalette

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
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
            .shadow(color: palette.shadow.opacity(0.7), radius: 3, y: 1)
            .shadow(color: palette.shadow.opacity(0.5), radius: 16, y: 6)
    }
}

extension View {
    func paperCard(_ palette: PaperPalette) -> some View {
        modifier(PaperCardModifier(palette: palette))
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
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isDone)
    }
}
