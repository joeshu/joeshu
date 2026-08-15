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
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        guard !context.coordinator.isUpdating else { return }
        if uiView.text != text {
            uiView.text = text
            context.coordinator.scheduleHighlight(for: uiView)
        }
        if let request = insertionRequest {
            context.coordinator.insert(request, into: uiView)
            insertionRequest = nil
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MarkdownEditorTextView
        var isUpdating = false
        weak var parentTextView: UITextView?
        private var pendingHighlight: DispatchWorkItem?
        private var pendingID = UUID()

        init(parent: MarkdownEditorTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            isUpdating = true
            parent.text = textView.text
            isUpdating = false

            guard textView.markedTextRange == nil else { return }
            scheduleHighlight(for: textView)
        }

        func scheduleHighlight(for textView: UITextView) {
            let id = UUID()
            pendingID = id
            let selected = textView.selectedRange
            let text = textView.text ?? ""
            let textColor = parent.textColor
            let baseFont = parent.baseFont
            let work = DispatchWorkItem { [weak self] in
                guard let self, self.pendingID == id else { return }
                let highlighted = MarkdownHighlight.highlight(
                    text,
                    textColor: textColor,
                    baseFont: baseFont
                )
                DispatchQueue.main.async { [weak textView] in
                    guard let textView else { return }
                    guard self.pendingID == id, textView.text == text else { return }
                    textView.attributedText = highlighted
                    let location = min(selected.location, textView.text.utf16.count)
                    let length = min(selected.length, textView.text.utf16.count - location)
                    textView.selectedRange = NSRange(location: location, length: max(0, length))
                }
            }
            pendingHighlight?.cancel()
            pendingHighlight = work
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.15, execute: work)
        }

        func makeToolbar() -> UIToolbar {
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            toolbar.items = [
                iconItem("加粗", image: UIImage(systemName: "bold"), action: #selector(bold)),
                iconItem("斜体", image: UIImage(systemName: "italic"), action: #selector(italic)),
                iconItem("删除线", image: UIImage(systemName: "strikethrough"), action: #selector(strike)),
                iconItem("标题", image: UIImage(systemName: "textformat.size"), action: #selector(heading)),
                iconItem("引用", image: UIImage(systemName: "text.quote"), action: #selector(quote)),
                iconItem("代码", image: UIImage(systemName: "chevron.left.forwardslash.chevron.right"), action: #selector(code)),
                iconItem("链接", image: UIImage(systemName: "link"), action: #selector(link)),
                UIBarButtonItem(systemItem: .flexibleSpace)
            ]
            return toolbar
        }

        private func iconItem(_ title: String, image: UIImage?, action: Selector) -> UIBarButtonItem {
            let item = UIBarButtonItem(image: image, style: .plain, target: self, action: action)
            item.accessibilityLabel = title
            item.accessibilityHint = "将格式应用到当前选中文本"
            return item
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
        @objc private func link() { wrap("[", suffix: "](https://)") }
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
