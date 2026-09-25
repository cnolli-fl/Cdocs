import AppKit
import SwiftUI

struct MarkdownBlockView: View {
    let text: String

    private var blocks: [MarkdownBlock] { MarkdownBlock.parse(text) }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(blocks) { block in
                switch block.kind {
                case .heading(let level):
                    Text(block.content)
                        .font(level == 1 ? .title2.bold() : .headline)
                        .padding(.top, 4)
                case .code:
                    codeBlock(block.content)
                case .bullet:
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5))
                        Text(markdown: block.content)
                    }
                case .numbered(let number):
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(number).")
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 20, alignment: .trailing)
                        Text(markdown: block.content)
                    }
                case .paragraph:
                    Text(markdown: block.content)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func codeBlock(_ code: String) -> some View {
        VStack(alignment: .trailing, spacing: 8) {
            ScrollView(.horizontal) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(code, forType: .string)
            } label: {
                Label("Copiar", systemImage: "doc.on.doc")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(.separator, lineWidth: 1)
        }
    }
}

private struct MarkdownBlock: Identifiable {
    enum Kind {
        case heading(Int)
        case code
        case bullet
        case numbered(Int)
        case paragraph
    }

    let id = UUID()
    let kind: Kind
    let content: String

    static func parse(_ source: String) -> [MarkdownBlock] {
        var result: [MarkdownBlock] = []
        var codeLines: [String] = []
        var paragraphLines: [String] = []
        var insideCode = false

        func flushParagraph() {
            let value = paragraphLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty { result.append(MarkdownBlock(kind: .paragraph, content: value)) }
            paragraphLines.removeAll()
        }

        for line in source.components(separatedBy: .newlines) {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                if insideCode {
                    result.append(MarkdownBlock(kind: .code, content: codeLines.joined(separator: "\n")))
                    codeLines.removeAll()
                } else {
                    flushParagraph()
                }
                insideCode.toggle()
                continue
            }
            if insideCode {
                codeLines.append(line)
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                flushParagraph()
            } else if trimmed.hasPrefix("## ") {
                flushParagraph()
                result.append(MarkdownBlock(kind: .heading(2), content: String(trimmed.dropFirst(3))))
            } else if trimmed.hasPrefix("# ") {
                flushParagraph()
                result.append(MarkdownBlock(kind: .heading(1), content: String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                flushParagraph()
                result.append(MarkdownBlock(kind: .bullet, content: String(trimmed.dropFirst(2))))
            } else if let dot = trimmed.firstIndex(of: "."),
                      let number = Int(trimmed[..<dot]),
                      trimmed.index(after: dot) < trimmed.endIndex {
                flushParagraph()
                let content = trimmed[trimmed.index(after: dot)...].trimmingCharacters(in: .whitespaces)
                result.append(MarkdownBlock(kind: .numbered(number), content: content))
            } else {
                paragraphLines.append(line)
            }
        }
        flushParagraph()
        if !codeLines.isEmpty {
            result.append(MarkdownBlock(kind: .code, content: codeLines.joined(separator: "\n")))
        }
        return result
    }
}

private extension Text {
    init(markdown: String) {
        if let attributed = try? AttributedString(markdown: markdown) {
            self.init(attributed)
        } else {
            self.init(markdown)
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, point) in result.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, points: [CGPoint]) {
        let width = proposal.width ?? .infinity
        var points: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxWidth = max(maxWidth, x - spacing)
        }
        return (CGSize(width: min(maxWidth, width), height: y + rowHeight), points)
    }
}
