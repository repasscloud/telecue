import Foundation

struct PrompterMetrics: Equatable, Sendable {
    let wordCount: Int
    let wordsPerMinute: Int
    let contentHeight: Double
    let viewportHeight: Double

    var durationSeconds: Double {
        ScriptMetrics.durationSeconds(
            wordCount: wordCount,
            wordsPerMinute: wordsPerMinute
        )
    }

    var scrollableDistance: Double {
        max(0, finite(contentHeight) - finite(viewportHeight))
    }

    var pixelsPerSecond: Double {
        guard durationSeconds > 0, scrollableDistance > 0 else { return 0 }
        return scrollableDistance / durationSeconds
    }

    private func finite(_ value: Double) -> Double {
        value.isFinite ? max(0, value) : 0
    }
}

struct PrompterEngine: Equatable, Sendable {
    private(set) var metrics: PrompterMetrics
    private(set) var position: Double = 0
    private(set) var isPlaying = false
    private var lastTimestamp: TimeInterval?

    init(metrics: PrompterMetrics) {
        self.metrics = metrics
    }

    var progress: Double {
        guard metrics.scrollableDistance > 0 else { return 0 }
        return min(1, max(0, position / metrics.scrollableDistance))
    }

    mutating func play(at timestamp: TimeInterval) {
        guard metrics.pixelsPerSecond > 0,
              position < metrics.scrollableDistance else { return }
        isPlaying = true
        lastTimestamp = timestamp
    }

    mutating func pause(at timestamp: TimeInterval) {
        update(at: timestamp)
        isPlaying = false
        lastTimestamp = nil
    }

    mutating func togglePlayback(at timestamp: TimeInterval) {
        if isPlaying {
            pause(at: timestamp)
        } else {
            play(at: timestamp)
        }
    }

    mutating func restart() {
        position = 0
        isPlaying = false
        lastTimestamp = nil
    }

    mutating func seek(to newPosition: Double, at timestamp: TimeInterval) {
        position = clampedPosition(newPosition)
        if isPlaying {
            lastTimestamp = timestamp
        }
    }

    mutating func setMetrics(_ newMetrics: PrompterMetrics, at timestamp: TimeInterval) {
        update(at: timestamp)
        let oldDistance = metrics.scrollableDistance
        let oldProgress = oldDistance > 0 ? position / oldDistance : 0
        metrics = newMetrics

        if oldDistance != newMetrics.scrollableDistance {
            position = clampedPosition(oldProgress * newMetrics.scrollableDistance)
        } else {
            position = clampedPosition(position)
        }

        if isPlaying {
            guard metrics.pixelsPerSecond > 0,
                  position < metrics.scrollableDistance else {
                isPlaying = false
                lastTimestamp = nil
                return
            }
            lastTimestamp = timestamp
        }
    }

    mutating func update(at timestamp: TimeInterval) {
        guard isPlaying, let lastTimestamp else { return }
        let elapsed = max(0, timestamp - lastTimestamp)
        position = clampedPosition(position + metrics.pixelsPerSecond * elapsed)
        self.lastTimestamp = timestamp

        if position >= metrics.scrollableDistance {
            isPlaying = false
            self.lastTimestamp = nil
        }
    }

    private func clampedPosition(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(metrics.scrollableDistance, max(0, value))
    }
}
