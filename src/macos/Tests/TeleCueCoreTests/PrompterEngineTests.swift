import XCTest
@testable import TeleCueCore

final class PrompterEngineTests: XCTestCase {
    func testMetricsDeriveDurationDistanceAndVelocity() {
        let metrics = PrompterMetrics(
            wordCount: 100,
            wordsPerMinute: 100,
            contentHeight: 1_000,
            viewportHeight: 200
        )

        XCTAssertEqual(metrics.durationSeconds, 60, accuracy: 0.000_1)
        XCTAssertEqual(metrics.scrollableDistance, 800, accuracy: 0.000_1)
        XCTAssertEqual(metrics.pixelsPerSecond, 13.333_333, accuracy: 0.000_1)
    }

    func testMetricsDoNotProduceInvalidVelocityForEmptyOrShortDocuments() {
        let empty = PrompterMetrics(
            wordCount: 0,
            wordsPerMinute: 150,
            contentHeight: 500,
            viewportHeight: 200
        )
        let short = PrompterMetrics(
            wordCount: 20,
            wordsPerMinute: 150,
            contentHeight: 100,
            viewportHeight: 250
        )

        XCTAssertEqual(empty.pixelsPerSecond, 0)
        XCTAssertEqual(short.scrollableDistance, 0)
        XCTAssertEqual(short.pixelsPerSecond, 0)
    }

    func testPauseAndResumeUseElapsedTimeWithoutJumping() {
        var engine = PrompterEngine(metrics: .init(
            wordCount: 60,
            wordsPerMinute: 60,
            contentHeight: 800,
            viewportHeight: 200
        ))

        engine.play(at: 100)
        engine.update(at: 105)
        XCTAssertEqual(engine.position, 50, accuracy: 0.000_1)

        engine.pause(at: 106)
        XCTAssertEqual(engine.position, 60, accuracy: 0.000_1)
        engine.update(at: 200)
        XCTAssertEqual(engine.position, 60, accuracy: 0.000_1)

        engine.play(at: 200)
        engine.update(at: 203)
        XCTAssertEqual(engine.position, 90, accuracy: 0.000_1)
    }

    func testRestartReturnsToBeginningAndStopsPlayback() {
        var engine = PrompterEngine(metrics: .init(
            wordCount: 60,
            wordsPerMinute: 60,
            contentHeight: 800,
            viewportHeight: 200
        ))
        engine.play(at: 0)
        engine.update(at: 10)

        engine.restart()

        XCTAssertEqual(engine.position, 0)
        XCTAssertFalse(engine.isPlaying)
    }

    func testSeekWhilePlayingRebasesElapsedTime() {
        var engine = PrompterEngine(metrics: .init(
            wordCount: 60,
            wordsPerMinute: 60,
            contentHeight: 800,
            viewportHeight: 200
        ))
        engine.play(at: 10)
        engine.update(at: 12)

        engine.seek(to: 300, at: 20)
        engine.update(at: 21)

        XCTAssertEqual(engine.position, 310, accuracy: 0.000_1)
    }

    func testChangingWPMChangesVelocityWithoutMovingPosition() {
        var engine = PrompterEngine(metrics: .init(
            wordCount: 100,
            wordsPerMinute: 100,
            contentHeight: 800,
            viewportHeight: 200
        ))
        engine.seek(to: 150, at: 0)

        engine.setMetrics(.init(
            wordCount: 100,
            wordsPerMinute: 200,
            contentHeight: 800,
            viewportHeight: 200
        ), at: 0)

        XCTAssertEqual(engine.position, 150, accuracy: 0.000_1)
        XCTAssertEqual(engine.metrics.pixelsPerSecond, 20, accuracy: 0.000_1)
    }

    func testChangingRenderedHeightPreservesProgress() {
        var engine = PrompterEngine(metrics: .init(
            wordCount: 100,
            wordsPerMinute: 100,
            contentHeight: 1_000,
            viewportHeight: 200
        ))
        engine.seek(to: 200, at: 0)

        engine.setMetrics(.init(
            wordCount: 100,
            wordsPerMinute: 100,
            contentHeight: 1_800,
            viewportHeight: 200
        ), at: 0)

        XCTAssertEqual(engine.position, 400, accuracy: 0.000_1)
        XCTAssertEqual(engine.progress, 0.25, accuracy: 0.000_1)
    }

    func testPlaybackStopsAtEndOfDocument() {
        var engine = PrompterEngine(metrics: .init(
            wordCount: 1,
            wordsPerMinute: 60,
            contentHeight: 300,
            viewportHeight: 200
        ))

        engine.play(at: 0)
        engine.update(at: 2)

        XCTAssertEqual(engine.position, 100)
        XCTAssertFalse(engine.isPlaying)
    }
}
