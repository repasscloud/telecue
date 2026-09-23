import XCTest
@testable import TeleCueCore

@MainActor
final class TeleCueModelTests: XCTestCase {
    func testScriptChangesUpdateWordCountAndDuration() {
        let model = TeleCueModel(settings: .default, settingsStore: nil)

        model.script = "one two three four five"

        XCTAssertEqual(model.wordCount, 5)
        XCTAssertEqual(model.estimatedDuration, 2, accuracy: 0.000_1)
    }

    func testWPMAdjustmentsUseFiveWordStepsAndClampToRange() {
        let model = TeleCueModel(settings: .default, settingsStore: nil)

        model.adjustWPM(by: 5)
        XCTAssertEqual(model.settings.wordsPerMinute, 155)

        for _ in 0..<30 { model.adjustWPM(by: 5) }
        XCTAssertEqual(model.settings.wordsPerMinute, 250)

        for _ in 0..<50 { model.adjustWPM(by: -5) }
        XCTAssertEqual(model.settings.wordsPerMinute, 80)
    }

    func testFontAdjustmentsUseTwoPointStepsAndClampToRange() {
        let model = TeleCueModel(settings: .default, settingsStore: nil)

        model.adjustFontSize(by: 2)
        XCTAssertEqual(model.settings.fontSize, 44)

        for _ in 0..<100 { model.adjustFontSize(by: -2) }
        XCTAssertEqual(model.settings.fontSize, 24)
    }

    func testPlaybackActionsExposeEngineState() {
        let model = TeleCueModel(settings: .default, settingsStore: nil)
        model.script = "one two three four five six"
        model.updateRenderedMetrics(contentHeight: 800, viewportHeight: 200, at: 0)

        model.togglePlayback(at: 0)
        model.tick(at: 1)
        XCTAssertTrue(model.isPlaying)
        XCTAssertGreaterThan(model.scrollPosition, 0)

        let pausedPosition = model.scrollPosition
        model.togglePlayback(at: 1)
        model.tick(at: 50)
        XCTAssertFalse(model.isPlaying)
        XCTAssertEqual(model.scrollPosition, pausedPosition, accuracy: 0.000_1)

        model.restart()
        XCTAssertEqual(model.scrollPosition, 0)
    }

    func testFormattedDurationUsesHoursWhenNeeded() {
        let model = TeleCueModel(settings: .default, settingsStore: nil)
        model.script = Array(repeating: "word", count: 9_000).joined(separator: " ")

        XCTAssertEqual(model.formattedDuration, "1h 0m 0s")
    }

    func testMarkdownFilesAreFormattedAndTextFilesAreNot() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let markdownURL = directory.appendingPathComponent("script.md")
        let textURL = directory.appendingPathComponent("script.txt")
        try Data("# One\n\n**two**".utf8).write(to: markdownURL)
        try Data("# One\n\n**two**".utf8).write(to: textURL)
        let model = TeleCueModel(settings: .default, settingsStore: nil)

        model.loadScript(from: markdownURL)
        XCTAssertEqual(model.scriptFormat, .markdown)
        XCTAssertEqual(model.wordCount, 2)

        model.loadScript(from: textURL)
        XCTAssertEqual(model.scriptFormat, .plain)
        XCTAssertEqual(model.wordCount, 3)

        model.loadScript(from: markdownURL)
        model.clearScript()
        XCTAssertEqual(model.scriptFormat, .plain)
    }
}
