import SwiftUI

struct NoteRenderView: View {
    let markdown: String
    var strength: RenderStrength = .full
    var font: Font = .body
    var textColor: Color = .primary
    var palette: PaperPalette? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                if let imageName = segment.imageName {
                    if let uiImage = NoteImageStore.image(named: imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: PaperRadius.control, style: .continuous))
                            .shadow(color: (palette?.shadow ?? .black.opacity(0.22)).opacity(0.55), radius: 3, y: 1)
                            .shadow(color: (palette?.shadow ?? .black.opacity(0.22)).opacity(0.35), radius: 10, y: 4)
                    } else {
                        Text(segment.raw)
                            .font(font)
                            .foregroundStyle(.secondary)
                    }
                } else if !segment.raw.isEmpty {
                    MarkdownTextView(
                        markdown: segment.raw,
                        strength: strength,
                        font: font,
                        textColor: textColor,
                        palette: palette
                    )
                }
            }
        }
    }

    private var segments: [Segment] {
        var result: [Segment] = []
        let pattern = #"^!\[([^\]]*)\]\(([^)]+)\)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [Segment(raw: markdown)]
        }
        var textLines: [String] = []
        var inFence = false

        func flushText() {
            guard !textLines.isEmpty else { return }
            result.append(Segment(raw: textLines.joined(separator: "\n")))
            textLines.removeAll(keepingCapacity: true)
        }

        for line in markdown.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                inFence.toggle()
                textLines.append(line)
                continue
            }
            let range = NSRange(location: 0, length: (trimmed as NSString).length)
            if !inFence, let match = regex.firstMatch(in: trimmed, range: range) {
                flushText()
                let name = (trimmed as NSString).substring(with: match.range(at: 2))
                result.append(Segment(raw: trimmed, imageName: name))
            } else {
                textLines.append(line)
            }
        }
        flushText()
        if result.isEmpty { result.append(Segment(raw: markdown)) }
        return result
    }

    struct Segment {
        let raw: String
        let imageName: String?

        init(raw: String, imageName: String? = nil) {
            self.raw = raw
            self.imageName = imageName
        }
    }
}
