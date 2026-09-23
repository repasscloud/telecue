import AppKit
import XCTest
@testable import TeleCue

final class ScriptRendererTests: XCTestCase {
    func testPlainScriptsAreRenderedLiterally() {
        let rendered = ScriptRenderer.render("# Not a heading **really**", format: .plain, fontSize: 40, lineSpacing: 8)

        XCTAssertEqual(rendered.string, "# Not a heading **really**")
        XCTAssertEqual(font(in: rendered, at: 0).pointSize, 40)
    }

    func testMarkdownHeadingsAreLargerAndBold() {
        let rendered = ScriptRenderer.render("# Title\n\nBody", format: .markdown, fontSize: 40, lineSpacing: 8)

        XCTAssertEqual(rendered.string, "Title\nBody")
        let headingFont = font(in: rendered, at: 0)
        XCTAssertGreaterThan(headingFont.pointSize, 40)
        XCTAssertTrue(headingFont.fontDescriptor.symbolicTraits.contains(.bold))
        XCTAssertEqual(font(in: rendered, at: 6).pointSize, 40)
    }

    func testMarkdownBoldItalicAndCodeUseMatchingFonts() {
        let rendered = ScriptRenderer.render("**b** *i* `c`", format: .markdown, fontSize: 40, lineSpacing: 8)

        XCTAssertEqual(rendered.string, "b i c")
        XCTAssertTrue(font(in: rendered, at: 0).fontDescriptor.symbolicTraits.contains(.bold))
        XCTAssertTrue(font(in: rendered, at: 2).fontDescriptor.symbolicTraits.contains(.italic))
        XCTAssertTrue(font(in: rendered, at: 4).fontDescriptor.symbolicTraits.contains(.monoSpace))
    }

    func testCodeBlocksAreLeftAlignedWhileProseIsCentred() {
        let rendered = ScriptRenderer.render("Prose\n\n```\ncode\n```", format: .markdown, fontSize: 40, lineSpacing: 8)

        XCTAssertEqual(paragraphStyle(in: rendered, at: 0).alignment, .center)
        XCTAssertEqual(paragraphStyle(in: rendered, at: rendered.length - 1).alignment, .left)
    }

    func testLineBreaksInsideABlockDoNotStartNewParagraphs() {
        let rendered = ScriptRenderer.render("one  \ntwo\n\n```\na\nb\n```", format: .markdown, fontSize: 40, lineSpacing: 8)

        XCTAssertEqual(rendered.string, "one\u{2028}two\na\u{2028}b")
    }

    private func font(in string: NSAttributedString, at index: Int) -> NSFont {
        string.attribute(.font, at: index, effectiveRange: nil) as! NSFont
    }

    private func paragraphStyle(in string: NSAttributedString, at index: Int) -> NSParagraphStyle {
        string.attribute(.paragraphStyle, at: index, effectiveRange: nil) as! NSParagraphStyle
    }
}
