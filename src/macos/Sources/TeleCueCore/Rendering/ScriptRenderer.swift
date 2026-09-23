#if os(macOS)
import AppKit

public typealias PlatformFont = NSFont
public typealias PlatformColor = NSColor
#else
import UIKit

public typealias PlatformFont = UIFont
public typealias PlatformColor = UIColor
#endif

public enum ScriptRenderer {
    #if os(macOS)
    private static let textColor = NSColor(calibratedWhite: 0.96, alpha: 1)
    private static let quoteColor = NSColor(calibratedWhite: 0.8, alpha: 1)
    private static let codeColor = NSColor(calibratedRed: 0.55, green: 0.85, blue: 1, alpha: 1)
    #else
    private static let textColor = UIColor(white: 0.96, alpha: 1)
    private static let quoteColor = UIColor(white: 0.8, alpha: 1)
    private static let codeColor = UIColor(red: 0.55, green: 0.85, blue: 1, alpha: 1)
    #endif

    public static func render(
        _ text: String,
        format: ScriptFormat,
        fontSize: Double,
        lineSpacing: Double
    ) -> NSAttributedString {
        switch format {
        case .plain:
            return NSAttributedString(string: text, attributes: [
                .font: PlatformFont.systemFont(ofSize: fontSize, weight: .medium),
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle(lineSpacing: lineSpacing)
            ])
        case .markdown:
            return renderMarkdown(text, fontSize: fontSize, lineSpacing: lineSpacing)
        }
    }

    private static func renderMarkdown(_ text: String, fontSize: Double, lineSpacing: Double) -> NSAttributedString {
        let output = NSMutableAttributedString()
        var paragraphEnd: [NSAttributedString.Key: Any]?
        for (index, block) in MarkdownScript.blocks(from: text).enumerated() {
            let paragraph = paragraphStyle(lineSpacing: lineSpacing)
            paragraph.paragraphSpacing = fontSize * 0.5
            var blockSize = fontSize
            var blockStyle: ScriptRun.Style = []
            var color = textColor

            switch block.kind {
            case .heading(let level):
                blockSize = fontSize * headingScale(level)
                blockStyle = .bold
                if index > 0 { paragraph.paragraphSpacingBefore = fontSize * 0.6 }
            case .paragraph:
                break
            case .quote:
                blockStyle = .italic
                color = quoteColor
            case .code:
                paragraph.alignment = .left
            }

            if let paragraphEnd {
                output.append(NSAttributedString(string: "\n", attributes: paragraphEnd))
            }
            paragraphEnd = [.font: font(size: blockSize, style: blockStyle), .paragraphStyle: paragraph]
            for run in block.runs {
                let style = run.style.union(blockStyle)
                // A line separator keeps line breaks inside the block without paragraph spacing.
                let text = run.text.replacingOccurrences(of: "\n", with: "\u{2028}")
                output.append(NSAttributedString(string: text, attributes: [
                    .font: font(size: blockSize, style: style),
                    .foregroundColor: style.contains(.code) ? codeColor : color,
                    .paragraphStyle: paragraph
                ]))
            }
        }
        return output
    }

    private static func headingScale(_ level: Int) -> Double {
        switch level {
        case 1: return 1.4
        case 2: return 1.25
        case 3: return 1.1
        default: return 1
        }
    }

    private static func font(size: Double, style: ScriptRun.Style) -> PlatformFont {
        if style.contains(.code) {
            return PlatformFont.monospacedSystemFont(ofSize: size * 0.85, weight: style.contains(.bold) ? .bold : .regular)
        }
        let font = PlatformFont.systemFont(ofSize: size, weight: style.contains(.bold) ? .bold : .medium)
        guard style.contains(.italic) else { return font }
        #if os(macOS)
        return NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
        #else
        let traits = font.fontDescriptor.symbolicTraits.union(.traitItalic)
        guard let descriptor = font.fontDescriptor.withSymbolicTraits(traits) else { return font }
        return UIFont(descriptor: descriptor, size: size)
        #endif
    }

    private static func paragraphStyle(lineSpacing: Double) -> NSMutableParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSpacing
        paragraph.alignment = .center
        return paragraph
    }
}
