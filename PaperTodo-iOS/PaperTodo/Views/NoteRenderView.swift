import SwiftUI

struct NoteRenderView: View {
    let markdown: String
    var strength: RenderStrength = .full
    var font: Font = .body

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                if let imageName = segment.imageName {
                    if let uiImage = NoteImageStore.image(named: imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Text(segment.raw)
                            .font(font)
                            .foregroundStyle(.secondary)
                    }
                } else if !segment.raw.isEmpty {
                    MarkdownTextView(markdown: segment.raw, strength: strength, font: font)
                }
            }
        }
    }

    private var segments: [Segment] {
        var result: [Segment] = []
        let pattern = #"!\[([^\]]*)\]\(([^)]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [Segment(raw: markdown)]
        }
        let ns = markdown as NSString
        var cursor = 0
        for match in regex.matches(in: markdown, range: NSRange(location: 0, length: ns.length)) {
            let leading = ns.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
            if !leading.isEmpty {
                result.append(Segment(raw: leading))
            }
            let name = ns.substring(with: match.range(at: 2))
            result.append(Segment(raw: ns.substring(with: match.range), imageName: name))
            cursor = match.range.location + match.range.length
        }
        let trailing = ns.substring(from: cursor)
        if !trailing.isEmpty {
            result.append(Segment(raw: trailing))
        }
        if result.isEmpty {
            result.append(Segment(raw: markdown))
        }
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
