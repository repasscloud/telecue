import SwiftUI
import UIKit
import XCTest
@testable import TeleCueiOS

@MainActor
final class PrompterTextViewTests: XCTestCase {
    private let script = Array(repeating: "A teleprompter line long enough to wrap.", count: 250)
        .joined(separator: "\n")

    func testLayoutReportsScrollableContentTallerThanTheViewport() throws {
        var metrics: [(content: Double, viewport: Double)] = []
        let host = makeHost(position: 0, onMetrics: { metrics.append(($0, $1)) })

        let textView = try XCTUnwrap(findTextView(in: host.view))
        let last = try XCTUnwrap(metrics.last)
        XCTAssertEqual(last.viewport, textView.bounds.height, accuracy: 0.5)
        XCTAssertGreaterThan(last.content, last.viewport * 4)
    }

    func testProgrammaticPositionMovesTheTextWithoutReportingManualScrolling() throws {
        var manualPositions: [Double] = []
        let host = makeHost(position: 0, onManualScroll: { manualPositions.append($0) })
        let textView = try XCTUnwrap(findTextView(in: host.view))

        host.rootView = makeView(position: 200, onManualScroll: { manualPositions.append($0) })
        flush(host)

        XCTAssertEqual(textView.contentOffset.y, 200, accuracy: 0.25)
        XCTAssertTrue(
            manualPositions.isEmpty,
            "Playback movement must not be interpreted as a manual reposition: \(manualPositions)"
        )
    }

    func testRestyleKeepsTheCurrentPosition() throws {
        let host = makeHost(position: 300)
        let textView = try XCTUnwrap(findTextView(in: host.view))
        XCTAssertEqual(textView.contentOffset.y, 300, accuracy: 0.25)

        host.rootView = makeView(position: 300, fontSize: 48)
        flush(host)

        XCTAssertEqual(textView.contentOffset.y, 300, accuracy: 0.25)
    }

    // MARK: - Helpers

    private var windows: [UIWindow] = []

    override func tearDown() {
        windows.forEach { $0.isHidden = true }
        windows.removeAll()
        super.tearDown()
    }

    private func makeView(
        position: Double,
        fontSize: Double = 42,
        onMetrics: @escaping @MainActor (Double, Double) -> Void = { _, _ in },
        onManualScroll: @escaping @MainActor (Double) -> Void = { _ in }
    ) -> PrompterTextView {
        PrompterTextView(
            text: script,
            format: .plain,
            fontSize: fontSize,
            lineSpacing: 10,
            position: position,
            onMetricsChanged: onMetrics,
            onManualScroll: onManualScroll
        )
    }

    private func makeHost(
        position: Double,
        onMetrics: @escaping @MainActor (Double, Double) -> Void = { _, _ in },
        onManualScroll: @escaping @MainActor (Double) -> Void = { _ in }
    ) -> UIHostingController<PrompterTextView> {
        let host = UIHostingController(
            rootView: makeView(position: position, onMetrics: onMetrics, onManualScroll: onManualScroll)
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 500))
        window.rootViewController = host
        window.isHidden = false
        windows.append(window)
        host.view.frame = window.bounds
        flush(host)
        return host
    }

    /// UIHostingController applies a new rootView on a later pass, so let it run.
    private func flush(_ host: UIHostingController<PrompterTextView>) {
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        host.view.layoutIfNeeded()
    }

    private func findTextView(in view: UIView) -> PrompterUITextView? {
        if let textView = view as? PrompterUITextView {
            return textView
        }
        for subview in view.subviews {
            if let textView = findTextView(in: subview) {
                return textView
            }
        }
        return nil
    }
}
