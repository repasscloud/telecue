import XCTest
@testable import TeleCue

final class MarkdownScriptTests: XCTestCase {
    func testHeadingsAndInlineEmphasisBecomeStyledRuns() {
        let blocks = MarkdownScript.blocks(from: "# Title\n\nSay *this* with **force**.")

        XCTAssertEqual(blocks, [
            ScriptBlock(kind: .heading(1), runs: [ScriptRun("Title")]),
            ScriptBlock(kind: .paragraph, runs: [
                ScriptRun("Say "),
                ScriptRun("this", style: .italic),
                ScriptRun(" with "),
                ScriptRun("force", style: .bold),
                ScriptRun(".")
            ])
        ])
    }

    func testLineBreaksInsideAParagraphAreKeptAsWritten() {
        let markdown = """
        # Cinturon360 v5 — CTO Status Update
        **Date:** 4 May 2026
        **From:** Danijel-James Wynyard
        **To:** Warren Lio
        """

        let blocks = MarkdownScript.blocks(from: markdown)

        XCTAssertEqual(blocks.map(\.text), [
            "Cinturon360 v5 — CTO Status Update",
            "Date: 4 May 2026\nFrom: Danijel-James Wynyard\nTo: Warren Lio"
        ])
        XCTAssertEqual(blocks[1].runs.first, ScriptRun("Date:", style: .bold))
    }

    func testListsQuotesAndLinksKeepOnlyReadableText() {
        let markdown = """
        - first
        - second with [a link](https://example.com)

        3. third
        4. fourth

        > quoted
        """

        let blocks = MarkdownScript.blocks(from: markdown)

        XCTAssertEqual(blocks.map(\.text), [
            "• first",
            "• second with a link",
            "3. third",
            "4. fourth",
            "quoted"
        ])
        XCTAssertEqual(blocks.last?.kind, .quote)
    }

    func testTablesDiagramsImagesHTMLAndFrontMatterAreHidden() {
        let markdown = """
        ---
        title: Hidden
        ---
        Before.

        | a | b |
        |---|---|
        | c | d |

        ```mermaid
        graph TD; A-->B
        ```

        ![diagram](chart.png)

        <div>html</div>

        ---

        After.
        """

        XCTAssertEqual(MarkdownScript.blocks(from: markdown).map(\.text), ["Before.", "After."])
    }

    func testCodeIsKeptAsCode() {
        let markdown = """
        Run `swift test` first.

        ```swift
        let x = 1
        print(x)
        ```
        """

        let blocks = MarkdownScript.blocks(from: markdown)

        XCTAssertEqual(blocks, [
            ScriptBlock(kind: .paragraph, runs: [
                ScriptRun("Run "),
                ScriptRun("swift test", style: .code),
                ScriptRun(" first.")
            ]),
            ScriptBlock(kind: .code, runs: [ScriptRun("let x = 1\nprint(x)", style: .code)])
        ])
    }

    func testWordCountIgnoresMarkdownSyntaxAndHiddenContent() {
        let markdown = """
        # Hello there

        **Bold** words *here*.

        | not | counted |
        |-----|---------|
        | at  | all     |
        """

        XCTAssertEqual(ScriptMetrics.wordCount(in: markdown, format: .markdown), 5)
        XCTAssertEqual(ScriptMetrics.wordCount(in: "# Hello there", format: .plain), 3)
    }

    func testWordCountIgnoresListMarkers() {
        let markdown = """
        - hello
        - there

        1. one
        2. two
        """

        XCTAssertEqual(ScriptMetrics.wordCount(in: markdown, format: .markdown), 4)
    }

    func testFormatIsChosenFromFileExtension() {
        XCTAssertEqual(ScriptFormat(fileURL: URL(fileURLWithPath: "/a/script.md")), .markdown)
        XCTAssertEqual(ScriptFormat(fileURL: URL(fileURLWithPath: "/a/script.MARKDOWN")), .markdown)
        XCTAssertEqual(ScriptFormat(fileURL: URL(fileURLWithPath: "/a/script.txt")), .plain)
    }
}
