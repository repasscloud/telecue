import XCTest
@testable import TeleCue

final class SettingsTests: XCTestCase {
    func testDefaultsMatchTheMVP() {
        let settings = TeleCueSettings.default

        XCTAssertEqual(settings.wordsPerMinute, 150)
        XCTAssertEqual(settings.fontSize, 42)
        XCTAssertTrue(settings.focusEnabled)
        XCTAssertEqual(settings.focusPosition, 0.45)
        XCTAssertFalse(settings.mirrorEnabled)
    }

    func testNormalizationClampsAndRoundsUserControlledValues() {
        let settings = TeleCueSettings(
            wordsPerMinute: 253,
            fontSize: 9,
            lineSpacing: 80,
            focusEnabled: true,
            focusPosition: 0.99,
            mirrorEnabled: false,
            borderlessPresentation: false
        ).normalized

        XCTAssertEqual(settings.wordsPerMinute, 250)
        XCTAssertEqual(settings.fontSize, 24)
        XCTAssertEqual(settings.lineSpacing, 24)
        XCTAssertEqual(settings.focusPosition, 0.8)
    }

    func testNormalizationUsesFiveWPMAndTwoPointFontSteps() {
        let settings = TeleCueSettings(
            wordsPerMinute: 147,
            fontSize: 51,
            lineSpacing: 9,
            focusEnabled: false,
            focusPosition: 0.5,
            mirrorEnabled: true,
            borderlessPresentation: true
        ).normalized

        XCTAssertEqual(settings.wordsPerMinute, 145)
        XCTAssertEqual(settings.fontSize, 52)
        XCTAssertEqual(settings.lineSpacing, 9)
    }

    func testSettingsRoundTripThroughJSON() throws {
        let original = TeleCueSettings.default
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TeleCueSettings.self, from: encoded)

        XCTAssertEqual(decoded, original)
    }
}

