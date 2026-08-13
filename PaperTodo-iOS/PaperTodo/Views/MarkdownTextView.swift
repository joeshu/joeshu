import SwiftUI

struct MarkdownTextView: View {
    let markdown: String

    var body: some View {
        Text(rendered)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rendered: AttributedString {
        guard !markdown.isEmpty else { return AttributedString("") }
        if let attr = try? AttributedString(markdown: markdown) {
            return attr
        }
        return AttributedString(markdown)
    }
}
