import AppKit
import SwiftUI
import XCTest
@testable import TeleCue

@MainActor
final class PrompterTextViewTests: XCTestCase {
    func testLayoutRefreshDoesNotReportProgrammaticMovementAsManualScrolling() throws {
        var manualPositions: [Double] = []
        let script = Array(repeating: "A teleprompter line long enough to wrap.", count: 250)
            .joined(separator: "\n")

        func makeView(position: Double) -> PrompterTextView {
            PrompterTextView(
                text: script,
                format: .plain,
                fontSize: 42,
                lineSpacing: 10,
                position: position,
                onMetricsChanged: { _, _ in },
                onManualScroll: { manualPositions.append($0) }
            )
        }

        let hostingView = NSHostingView(rootView: makeView(position: 0))
        hostingView.frame = NSRect(x: 0, y: 0, width: 900, height: 500)
        hostingView.layoutSubtreeIfNeeded()

        let scrollView = try XCTUnwrap(findScrollView(in: hostingView))
        scrollView.contentView.scroll(to: NSPoint(x: 0, y: 200))
        scrollView.reflectScrolledClipView(scrollView.contentView)
        manualPositions.removeAll()

        hostingView.rootView = makeView(position: 200)
        hostingView.layoutSubtreeIfNeeded()

        XCTAssertTrue(
            manualPositions.isEmpty,
            "A layout refresh must not be interpreted as manual scrolling: \(manualPositions)"
        )
        XCTAssertEqual(scrollView.contentView.bounds.origin.y, 200, accuracy: 0.25)
    }

    private func findScrollView(in view: NSView) -> NSScrollView? {
        if let scrollView = view as? NSScrollView {
            return scrollView
        }

        for subview in view.subviews {
            if let scrollView = findScrollView(in: subview) {
                return scrollView
            }
        }

        return nil
    }
}
