import XCTest
@testable import TeleCue

final class ScriptMetricsTests: XCTestCase {
    func testWordCountTreatsPunctuationAsPartOfWhitespaceSeparatedWords() {
        XCTAssertEqual(
            ScriptMetrics.wordCount(in: "Hello, world!\nIt’s TeleCue."),
            4
        )
    }

    func testWordCountIgnoresRepeatedAndUnicodeWhitespace() {
        XCTAssertEqual(
            ScriptMetrics.wordCount(in: "  one\t two\n\nthree\u{00a0}four  "),
            4
        )
    }

    func testWordCountReturnsZeroForEmptyOrWhitespaceOnlyText() {
        XCTAssertEqual(ScriptMetrics.wordCount(in: ""), 0)
        XCTAssertEqual(ScriptMetrics.wordCount(in: " \n\t "), 0)
    }

    func testDurationUsesWordsPerMinute() {
        XCTAssertEqual(
            ScriptMetrics.durationSeconds(wordCount: 742, wordsPerMinute: 150),
            296.8,
            accuracy: 0.000_1
        )
    }

    func testDurationReturnsZeroForEmptyTextOrInvalidPace() {
        XCTAssertEqual(ScriptMetrics.durationSeconds(wordCount: 0, wordsPerMinute: 150), 0)
        XCTAssertEqual(ScriptMetrics.durationSeconds(wordCount: 100, wordsPerMinute: 0), 0)
        XCTAssertEqual(ScriptMetrics.durationSeconds(wordCount: -1, wordsPerMinute: 150), 0)
    }
}

