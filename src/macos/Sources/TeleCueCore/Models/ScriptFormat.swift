import Foundation

public enum ScriptFormat: Equatable, Sendable {
    case plain
    case markdown

    public init(fileURL: URL) {
        switch fileURL.pathExtension.lowercased() {
        case "md", "markdown":
            self = .markdown
        default:
            self = .plain
        }
    }
}

struct ScriptRun: Equatable, Sendable {
    struct Style: OptionSet, Hashable, Sendable {
        let rawValue: Int

        static let bold = Style(rawValue: 1 << 0)
        static let italic = Style(rawValue: 1 << 1)
        static let code = Style(rawValue: 1 << 2)
        /// Shown on screen but not spoken, such as list bullets and numbers.
        static let marker = Style(rawValue: 1 << 3)
    }

    var text: String
    var style: Style

    init(_ text: String, style: Style = []) {
        self.text = text
        self.style = style
    }
}

struct ScriptBlock: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case heading(Int)
        case paragraph
        case quote
        case code
    }

    var kind: Kind
    var runs: [ScriptRun]

    var text: String {
        runs.map(\.text).joined()
    }

    var spokenText: String {
        runs.filter { !$0.style.contains(.marker) }.map(\.text).joined()
    }
}
