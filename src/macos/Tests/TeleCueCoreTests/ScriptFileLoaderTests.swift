import Foundation
import XCTest
@testable import TeleCueCore

final class ScriptFileLoaderTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: temporaryDirectory)
    }

    func testLoadsUTF8TextAndMarkdownFiles() throws {
        for fileExtension in ["txt", "md", "markdown"] {
            let url = temporaryDirectory.appendingPathComponent("script.\(fileExtension)")
            try Data("Hello, TeleCue — café".utf8).write(to: url)

            XCTAssertEqual(
                try ScriptFileLoader.load(from: url),
                "Hello, TeleCue — café"
            )
        }
    }

    func testLoadsAnEmptyFileWithoutFailure() throws {
        let url = temporaryDirectory.appendingPathComponent("empty.txt")
        try Data().write(to: url)

        XCTAssertEqual(try ScriptFileLoader.load(from: url), "")
    }

    func testRejectsUnsupportedFileTypes() throws {
        let url = temporaryDirectory.appendingPathComponent("script.rtf")
        try Data("text".utf8).write(to: url)

        XCTAssertThrowsError(try ScriptFileLoader.load(from: url)) { error in
            XCTAssertEqual(error as? ScriptFileError, .unsupportedFileType("rtf"))
        }
    }

    func testRejectsMalformedUTF8() throws {
        let url = temporaryDirectory.appendingPathComponent("script.txt")
        try Data([0xC3, 0x28]).write(to: url)

        XCTAssertThrowsError(try ScriptFileLoader.load(from: url)) { error in
            XCTAssertEqual(error as? ScriptFileError, .invalidUTF8)
        }
    }
}
