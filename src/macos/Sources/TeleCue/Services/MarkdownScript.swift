import Foundation
import Markdown

/// Reduces a Markdown document to the blocks a presenter reads aloud.
/// Tables, diagrams, images, raw HTML, rules, and front matter are dropped.
enum MarkdownScript {
    private static let diagramLanguages: Set<String> = [
        "mermaid", "plantuml", "puml", "dot", "graphviz", "d2", "diagram"
    ]

    static func blocks(from markdown: String) -> [ScriptBlock] {
        let document = Document(parsing: removingFrontMatter(from: markdown))
        var blocks: [ScriptBlock] = []
        for child in document.children {
            appendBlocks(for: child, kind: .paragraph, to: &blocks)
        }
        return blocks.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    static func spokenText(from markdown: String) -> String {
        blocks(from: markdown).map(\.text).joined(separator: "\n")
    }

    private static func appendBlocks(
        for markup: Markup,
        kind: ScriptBlock.Kind,
        to blocks: inout [ScriptBlock]
    ) {
        switch markup {
        case let heading as Heading:
            blocks.append(ScriptBlock(kind: .heading(heading.level), runs: runs(for: heading)))
        case let paragraph as Paragraph:
            blocks.append(ScriptBlock(kind: kind, runs: runs(for: paragraph)))
        case let quote as BlockQuote:
            for child in quote.children {
                appendBlocks(for: child, kind: .quote, to: &blocks)
            }
        case let list as UnorderedList:
            for item in list.listItems {
                appendListItem(item, marker: "• ", kind: kind, to: &blocks)
            }
        case let list as OrderedList:
            for (offset, item) in list.listItems.enumerated() {
                appendListItem(item, marker: "\(Int(list.startIndex) + offset). ", kind: kind, to: &blocks)
            }
        case let code as CodeBlock:
            let language = code.language?.lowercased() ?? ""
            guard !diagramLanguages.contains(language) else { return }
            let text = code.code.trimmingCharacters(in: .newlines)
            blocks.append(ScriptBlock(kind: .code, runs: [ScriptRun(text, style: .code)]))
        case is Table, is ThematicBreak, is HTMLBlock:
            return
        default:
            for child in markup.children {
                appendBlocks(for: child, kind: kind, to: &blocks)
            }
        }
    }

    private static func appendListItem(
        _ item: ListItem,
        marker: String,
        kind: ScriptBlock.Kind,
        to blocks: inout [ScriptBlock]
    ) {
        var needsMarker = true
        for child in item.children {
            if needsMarker, let paragraph = child as? Paragraph {
                blocks.append(ScriptBlock(kind: kind, runs: [ScriptRun(marker)] + runs(for: paragraph)))
                needsMarker = false
            } else {
                appendBlocks(for: child, kind: kind, to: &blocks)
            }
        }
    }

    private static func runs(for markup: Markup) -> [ScriptRun] {
        var runs: [ScriptRun] = []
        appendRuns(for: markup, style: [], to: &runs)
        return runs
    }

    private static func appendRuns(for markup: Markup, style: ScriptRun.Style, to runs: inout [ScriptRun]) {
        switch markup {
        case let text as Markdown.Text:
            append(text.string, style: style, to: &runs)
        case let code as InlineCode:
            append(code.code, style: style.union(.code), to: &runs)
        case is SoftBreak, is LineBreak:
            // Presenters write one thought per line, so keep line breaks as written.
            append("\n", style: style, to: &runs)
        case is Markdown.Image, is InlineHTML:
            return
        case is Strong:
            appendChildRuns(of: markup, style: style.union(.bold), to: &runs)
        case is Emphasis:
            appendChildRuns(of: markup, style: style.union(.italic), to: &runs)
        default:
            appendChildRuns(of: markup, style: style, to: &runs)
        }
    }

    private static func appendChildRuns(of markup: Markup, style: ScriptRun.Style, to runs: inout [ScriptRun]) {
        for child in markup.children {
            appendRuns(for: child, style: style, to: &runs)
        }
    }

    private static func append(_ text: String, style: ScriptRun.Style, to runs: inout [ScriptRun]) {
        guard !text.isEmpty else { return }
        if let last = runs.last, last.style == style {
            runs[runs.count - 1].text += text
        } else {
            runs.append(ScriptRun(text, style: style))
        }
    }

    private static func removingFrontMatter(from markdown: String) -> String {
        guard markdown.hasPrefix("---\n") || markdown.hasPrefix("---\r\n"),
              let match = markdown.firstMatch(of: /\A---\r?\n[\s\S]*?\r?\n---[ \t]*(\r?\n|\z)/)
        else { return markdown }
        return String(markdown[match.range.upperBound...])
    }
}
