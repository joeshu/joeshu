import SwiftUI
import UIKit

struct MarkdownEditorTextView: UIViewRepresentable {
    @Binding var text: String
    var textColor: UIColor
    var baseFont: UIFont

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.backgroundColor = .clear
        tv.isScrollEnabled = true
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        tv.autocapitalizationType = .sentences
        tv.font = baseFont
        tv.textColor = textColor
        applyHighlight(to: tv)
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        guard !context.coordinator.isUpdating else { return }
        if uiView.text != text {
            uiView.text = text
            applyHighlight(to: uiView)
        }
    }

    private func applyHighlight(to tv: UITextView) {
        let selected = tv.selectedRange
        tv.attributedText = MarkdownHighlight.highlight(tv.text, textColor: textColor, baseFont: baseFont)
        tv.selectedRange = selected
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MarkdownEditorTextView
        var isUpdating = false

        init(parent: MarkdownEditorTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            isUpdating = true
            parent.text = textView.text
            isUpdating = false

            let selected = textView.selectedRange
            textView.attributedText = MarkdownHighlight.highlight(
                textView.text,
                textColor: parent.textColor,
                baseFont: parent.baseFont
            )
            textView.selectedRange = selected
        }
    }
}

enum MarkdownHighlight {
    static func highlight(_ markdown: String, textColor: UIColor, baseFont: UIFont) -> NSAttributedString {
        var attr: AttributedString
        if let parsed = try? AttributedString(markdown: markdown) {
            attr = parsed
        } else {
            attr = AttributedString(markdown)
        }
        let result = NSMutableAttributedString(attributedString: NSAttributedString(attr))
        let fullRange = NSRange(location: 0, length: result.length)
        result.addAttribute(.foregroundColor, value: textColor, range: fullRange)
        result.addAttribute(.font, value: baseFont, range: fullRange)
        return result
    }
}
