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
                    .fill(palette.paper)
            )
            .overlay(
                RoundedRectangle(cornerRadius: PaperRadius.block, style: .continuous)
                    .stroke(palette.paperBorder.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 12, y: 2)
    }
}

extension View {
    func paperCard(_ palette: PaperPalette) -> some View {
        modifier(PaperCardModifier(palette: palette))
    }
}

struct AnimatedCheckCircle: View {
    let isDone: Bool
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(isDone ? tint : Color.secondary.opacity(0.5), lineWidth: 1.8)
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
