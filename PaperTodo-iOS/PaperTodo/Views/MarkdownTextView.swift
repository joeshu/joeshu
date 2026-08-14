import SwiftUI

struct MarkdownTextView: View {
    let markdown: String
    var strength: RenderStrength = .full
    var font: Font = .body
    var textColor: Color = .primary
    var palette: PaperPalette? = nil
    private let parsedBlocks: [Block]

    init(
        markdown: String,
        strength: RenderStrength = .full,
        font: Font = .body,
        textColor: Color = .primary,
        palette: PaperPalette? = nil
    ) {
        self.markdown = markdown
        self.strength = strength
        self.font = font
        self.textColor = textColor
        self.palette = palette
        self.parsedBlocks = Self.parseBlocks(markdown, strength: strength)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(parsedBlocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private enum Block {
        case heading(level: Int, text: String)
        case quote(String)
        case code(String)
        case divider
        case paragraph(String)
    }

    @ViewBuilder
    private func blockView(_ block: Block) -> some View {
        switch block {
        case let .heading(level, text):
            Text(inline(text))
                .font(.system(size: max(18, 27 - CGFloat(level) * 2), design: .rounded).weight(.semibold))
                .foregroundStyle(textColor)
                .padding(.top, level == 1 ? 8 : 3)
                .overlay(alignment: .bottomLeading) {
                    if level == 1 {
                        Capsule()
                            .fill(palette?.active ?? textColor.opacity(0.35))
                            .frame(width: 28, height: 3)
                            .offset(y: 7)
                    }
                }
                .accessibilityAddTraits(.isHeader)
        case let .quote(text):
            Text(inline(text))
                .font(font)
                .foregroundStyle(textColor)
                .lineSpacing(4)
                .padding(.leading, 12)
                .padding(.vertical, 4)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(palette?.quoteBorder ?? textColor.opacity(0.35))
                        .frame(width: 3)
                }
        case let .code(text):
            Text(text)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(textColor)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [
                            (palette?.code ?? textColor.opacity(0.08)).opacity(0.9),
                            (palette?.code ?? textColor.opacity(0.08)).opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous)
                        .stroke((palette?.paperBorder ?? textColor.opacity(0.15)).opacity(0.7), lineWidth: 1)
                }
                .shadow(color: (palette?.shadow ?? .black.opacity(0.15)).opacity(0.28), radius: 7, y: 3)
        case .divider:
            Divider().overlay((palette?.quoteBorder ?? textColor.opacity(0.25)).opacity(0.7))
        case let .paragraph(text):
            Text(inline(text))
                .font(font)
                .foregroundStyle(textColor)
                .lineSpacing(4)
        }
    }

    private static func parseBlocks(_ markdown: String, strength: RenderStrength) -> [Block] {
        guard strength != .plain else { return [.paragraph(markdown)] }
        var result: [Block] = []
        var paragraph: [String] = []
        var codeLines: [String] = []
        var inCode = false

        func flushParagraph() {
            let value = paragraph.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty { result.append(.paragraph(value)) }
            paragraph.removeAll()
        }

        for line in markdown.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                if inCode { result.append(.code(codeLines.joined(separator: "\n"))); codeLines.removeAll() } else { flushParagraph() }
                inCode.toggle()
            } else if inCode {
                codeLines.append(line)
            } else if let match = trimmed.firstMatch(of: /^(#{1,6})\s+(.+)$/) {
                flushParagraph()
                result.append(.heading(level: match.1.count, text: String(match.2)))
            } else if trimmed.hasPrefix(">") {
                flushParagraph()
                result.append(.quote(String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)))
            } else if trimmed.count >= 3 && trimmed.allSatisfy({ $0 == "-" || $0 == "*" || $0 == "_" }) {
                flushParagraph()
                result.append(.divider)
            } else if trimmed.isEmpty {
                flushParagraph()
            } else {
                paragraph.append(line)
            }
        }
        if inCode { result.append(.code(codeLines.joined(separator: "\n"))) }
        flushParagraph()
        return result.isEmpty ? [.paragraph(markdown)] : result
    }

    private func inline(_ value: String) -> AttributedString {
        guard !value.isEmpty else { return AttributedString("") }

        switch strength {
        case .plain:
            return AttributedString(value)
        case .light:
            let options = AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
            if var attr = try? AttributedString(markdown: value, options: options) {
                colorLinks(in: &attr)
                return attr
            }
            return AttributedString(value)
        case .full:
            if var attr = try? AttributedString(markdown: value) {
                colorLinks(in: &attr)
                return attr
            }
            return AttributedString(value)
        }
    }

    private func colorLinks(in value: inout AttributedString) {
        guard let linkColor = palette?.link else { return }
        for run in value.runs where run.link != nil {
            value[run.range].foregroundColor = linkColor
        }
    }
}
