import SwiftUI

struct MarkdownTextView: View {
    let markdown: String
    var strength: RenderStrength = .full
    var font: Font = .body
    var textColor: Color = .primary

    var body: some View {
        Text(rendered)
            .font(font)
            .foregroundStyle(textColor)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rendered: AttributedString {
        guard !markdown.isEmpty else { return AttributedString("") }

        switch strength {
        case .plain:
            return AttributedString(markdown)
        case .light:
            let options = AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
            if let attr = try? AttributedString(markdown: markdown, options: options) {
                return attr
            }
            return AttributedString(markdown)
        case .full:
            if let attr = try? AttributedString(markdown: markdown) {
                return attr
            }
            return AttributedString(markdown)
        }
    }
}
