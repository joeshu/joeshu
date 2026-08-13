import SwiftUI
import UIKit

struct MarkdownEditorTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var insertionRequest: String?
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
        context.coordinator.parentTextView = tv
        tv.inputAccessoryView = context.coordinator.makeToolbar()
        applyHighlight(to: tv)
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        guard !context.coordinator.isUpdating else { return }
        if uiView.text != text {
            uiView.text = text
            applyHighlight(to: uiView)
        }
        if let request = insertionRequest {
            context.coordinator.insert(request, into: uiView)
            insertionRequest = nil
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
        weak var parentTextView: UITextView?

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

        func makeToolbar() -> UIToolbar {
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            toolbar.items = [
                UIBarButtonItem(title: "B", style: .plain, target: self, action: #selector(bold)),
                UIBarButtonItem(title: "I", style: .plain, target: self, action: #selector(italic)),
                UIBarButtonItem(title: "S", style: .plain, target: self, action: #selector(strike)),
                UIBarButtonItem(title: "H", style: .plain, target: self, action: #selector(heading)),
                UIBarButtonItem(title: ">", style: .plain, target: self, action: #selector(quote)),
                UIBarButtonItem(title: "`", style: .plain, target: self, action: #selector(code)),
                UIBarButtonItem(systemItem: .flexibleSpace)
            ]
            return toolbar
        }

        func insert(_ value: String, into textView: UITextView) {
            let range = textView.selectedRange
            guard let textRange = Range(range, in: textView.text) else { return }
            textView.text = textView.text.replacingCharacters(in: textRange, with: value)
            textView.selectedRange = NSRange(location: range.location + value.utf16.count, length: 0)
            textViewDidChange(textView)
        }

        private func wrap(_ prefix: String, suffix: String = "") {
            guard let textView = parentTextView else { return }
            let range = textView.selectedRange
            guard let textRange = Range(range, in: textView.text) else { return }
            let selected = String(textView.text[textRange])
            textView.text = textView.text.replacingCharacters(in: textRange, with: prefix + selected + suffix)
            textView.selectedRange = NSRange(location: range.location + prefix.utf16.count, length: selected.utf16.count)
            textViewDidChange(textView)
        }

        @objc private func bold() { wrap("**", suffix: "**") }
        @objc private func italic() { wrap("*", suffix: "*") }
        @objc private func strike() { wrap("~~", suffix: "~~") }
        @objc private func heading() { wrap("# ") }
        @objc private func quote() { wrap("> ") }
        @objc private func code() { wrap("`", suffix: "`") }
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
