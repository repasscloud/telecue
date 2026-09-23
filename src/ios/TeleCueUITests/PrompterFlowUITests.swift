import XCTest

@MainActor
final class PrompterFlowUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testWriteAScriptAndRunThePrompter() throws {
        let app = XCUIApplication()
        app.launch()

        let editor = app.textViews["Script editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        let startButton = app.buttons["Start Prompter"]
        XCTAssertFalse(startButton.isEnabled, "An empty script cannot be prompted")

        if app.buttons["Clear"].isEnabled {
            app.buttons["Clear"].tap()
        }
        editor.tap()
        let lines = (1...24).map { "Line \($0): read this sentence clearly to the camera lens." }
        editor.typeText(lines.joined(separator: "\n"))
        attachScreenshot(of: app, named: "1-editor")

        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'words'")).firstMatch.exists)
        XCTAssertTrue(startButton.isEnabled)
        startButton.tap()

        let play = app.buttons["Play"]
        XCTAssertTrue(play.waitForExistence(timeout: 5), "Prompter controls should be visible on open")
        XCTAssertTrue(app.textViews["Prompter script"].exists)
        attachScreenshot(of: app, named: "2-prompter-ready")

        play.tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 2))

        // Controls fade out once playback is rolling.
        let controlsHidden = NSPredicate(format: "exists == false")
        expectation(for: controlsHidden, evaluatedWith: app.buttons["Pause"])
        waitForExpectations(timeout: 5)
        attachScreenshot(of: app, named: "3-playing-early")

        sleep(4)
        attachScreenshot(of: app, named: "4-playing-later")

        // A tap brings the controls back without stopping the take.
        app.textViews["Prompter script"].tap()
        let pause = app.buttons["Pause"]
        XCTAssertTrue(pause.waitForExistence(timeout: 2))
        pause.tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 2))

        app.buttons["Enable mirror"].tap()
        XCTAssertTrue(app.buttons["Disable mirror"].waitForExistence(timeout: 2))
        attachScreenshot(of: app, named: "5-mirrored")
        app.buttons["Disable mirror"].tap()

        app.buttons["Close prompter"].tap()
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
    }

    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
