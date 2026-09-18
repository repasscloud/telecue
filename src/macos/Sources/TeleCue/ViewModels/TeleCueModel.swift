import Foundation
import Observation

@MainActor
@Observable
final class TeleCueModel {
    var script = "" {
        didSet {
            refreshMetrics(at: Self.currentTimestamp)
        }
    }

    private(set) var settings: TeleCueSettings
    private(set) var alertMessage: String?
    private var engine: PrompterEngine
    @ObservationIgnored private let settingsStore: TeleCueSettingsStore?

    init(
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

    var wordCount: Int {
        ScriptMetrics.wordCount(in: script)
    }

    var estimatedDuration: Double {
        ScriptMetrics.durationSeconds(
            wordCount: wordCount,
            wordsPerMinute: settings.wordsPerMinute
        )
    }

    var formattedDuration: String {
        let totalSeconds = Int(estimatedDuration.rounded())
        let hours = totalSeconds / 3_600
        let minutes = totalSeconds % 3_600 / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        }
        return "\(minutes)m \(seconds)s"
    }

    var isPlaying: Bool { engine.isPlaying }
    var scrollPosition: Double { engine.position }
    var scrollProgress: Double { engine.progress }

    func loadScript(from url: URL) {
        do {
            script = try ScriptFileLoader.load(from: url)
            engine.restart()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func dismissAlert() {
        alertMessage = nil
    }

    func clearScript() {
        script = ""
        engine.restart()
    }

    func adjustWPM(by delta: Int) {
        settings.wordsPerMinute += delta
        commitSettings()
        refreshMetrics(at: Self.currentTimestamp)
    }

    func adjustFontSize(by delta: Double) {
        settings.fontSize += delta
        commitSettings()
    }

    func adjustLineSpacing(by delta: Double) {
        settings.lineSpacing += delta
        commitSettings()
    }

    func toggleFocus() {
        settings.focusEnabled.toggle()
        commitSettings()
    }

    func setFocusPosition(_ position: Double) {
        settings.focusPosition = position
        commitSettings()
    }

    func toggleMirror() {
        settings.mirrorEnabled.toggle()
        commitSettings()
    }

    func setBorderlessPresentation(_ enabled: Bool) {
        settings.borderlessPresentation = enabled
        commitSettings()
    }

    func updateRenderedMetrics(
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

    func togglePlayback(at timestamp: TimeInterval = TeleCueModel.currentTimestamp) {
        engine.togglePlayback(at: timestamp)
    }

    func tick(at timestamp: TimeInterval = TeleCueModel.currentTimestamp) {
        engine.update(at: timestamp)
    }

    func restart() {
        engine.restart()
    }

    func seek(to position: Double, at timestamp: TimeInterval = TeleCueModel.currentTimestamp) {
        engine.seek(to: position, at: timestamp)
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

    nonisolated private static var currentTimestamp: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }
}
