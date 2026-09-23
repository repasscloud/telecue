import Foundation
import Observation

@MainActor
@Observable
public final class TeleCueModel {
    public var script = "" {
        didSet {
            scriptDidChange()
        }
    }

    public private(set) var scriptFormat = ScriptFormat.plain {
        didSet {
            scriptDidChange()
        }
    }

    /// Cached because Markdown scripts must be parsed to count their words.
    public private(set) var wordCount = 0

    public private(set) var settings: TeleCueSettings
    public private(set) var alertMessage: String?
    private var engine: PrompterEngine
    @ObservationIgnored private let settingsStore: TeleCueSettingsStore?

    public init(
        settings: TeleCueSettings? = nil,
        settingsStore: TeleCueSettingsStore? = TeleCueSettingsStore()
    ) {
        let initialSettings = (settings ?? settingsStore?.load() ?? .default).normalized
        self.settingsStore = settingsStore
        self.settings = initialSettings
        self.engine = PrompterEngine(metrics: .init(
            wordCount: 0,
            wordsPerMinute: initialSettings.wordsPerMinute,
            contentHeight: 0,
            viewportHeight: 0
        ))
    }

    public var estimatedDuration: Double {
        ScriptMetrics.durationSeconds(
            wordCount: wordCount,
            wordsPerMinute: settings.wordsPerMinute
        )
    }

    public var formattedDuration: String {
        let totalSeconds = Int(estimatedDuration.rounded())
        let hours = totalSeconds / 3_600
        let minutes = totalSeconds % 3_600 / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        }
        return "\(minutes)m \(seconds)s"
    }

    public var isPlaying: Bool { engine.isPlaying }
    public var scrollPosition: Double { engine.position }
    public var scrollProgress: Double { engine.progress }

    public func loadScript(from url: URL) {
        do {
            let text = try ScriptFileLoader.load(from: url)
            scriptFormat = ScriptFormat(fileURL: url)
            script = text
            engine.restart()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    public func dismissAlert() {
        alertMessage = nil
    }

    public func clearScript() {
        script = ""
        scriptFormat = .plain
        engine.restart()
    }

    public func adjustWPM(by delta: Int) {
        settings.wordsPerMinute += delta
        commitSettings()
        refreshMetrics(at: Self.currentTimestamp)
    }

    public func adjustFontSize(by delta: Double) {
        settings.fontSize += delta
        commitSettings()
    }

    public func adjustLineSpacing(by delta: Double) {
        settings.lineSpacing += delta
        commitSettings()
    }

    public func toggleFocus() {
        settings.focusEnabled.toggle()
        commitSettings()
    }

    public func setFocusPosition(_ position: Double) {
        settings.focusPosition = position
        commitSettings()
    }

    public func toggleMirror() {
        settings.mirrorEnabled.toggle()
        commitSettings()
    }

    public func setBorderlessPresentation(_ enabled: Bool) {
        settings.borderlessPresentation = enabled
        commitSettings()
    }

    public func updateRenderedMetrics(
        contentHeight: Double,
        viewportHeight: Double,
        at timestamp: TimeInterval = TeleCueModel.currentTimestamp
    ) {
        engine.setMetrics(.init(
            wordCount: wordCount,
            wordsPerMinute: settings.wordsPerMinute,
            contentHeight: contentHeight,
            viewportHeight: viewportHeight
        ), at: timestamp)
    }

    public func togglePlayback(at timestamp: TimeInterval = TeleCueModel.currentTimestamp) {
        engine.togglePlayback(at: timestamp)
    }

    public func tick(at timestamp: TimeInterval = TeleCueModel.currentTimestamp) {
        engine.update(at: timestamp)
    }

    public func restart() {
        engine.restart()
    }

    public func seek(to position: Double, at timestamp: TimeInterval = TeleCueModel.currentTimestamp) {
        engine.seek(to: position, at: timestamp)
    }

    private func scriptDidChange() {
        wordCount = ScriptMetrics.wordCount(in: script, format: scriptFormat)
        refreshMetrics(at: Self.currentTimestamp)
    }

    private func refreshMetrics(at timestamp: TimeInterval) {
        updateRenderedMetrics(
            contentHeight: engine.metrics.contentHeight,
            viewportHeight: engine.metrics.viewportHeight,
            at: timestamp
        )
    }

    private func commitSettings() {
        settings = settings.normalized
        settingsStore?.save(settings)
    }

    /// Referenced from public default arguments, so it must be visible to inlinable code.
    @usableFromInline
    nonisolated static var currentTimestamp: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }
}
