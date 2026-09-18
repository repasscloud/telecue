import Foundation

struct TeleCueSettings: Codable, Equatable, Sendable {
    var wordsPerMinute: Int
    var fontSize: Double
    var lineSpacing: Double
    var focusEnabled: Bool
    var focusPosition: Double
    var mirrorEnabled: Bool
    var borderlessPresentation: Bool

    static let `default` = TeleCueSettings(
        wordsPerMinute: 150,
        fontSize: 42,
        lineSpacing: 10,
        focusEnabled: true,
        focusPosition: 0.45,
        mirrorEnabled: false,
        borderlessPresentation: false
    )

    var normalized: TeleCueSettings {
        var copy = self
        copy.wordsPerMinute = min(250, max(80, nearestStep(wordsPerMinute, step: 5)))
        copy.fontSize = min(96, max(24, nearestStep(fontSize, step: 2)))
        copy.lineSpacing = min(24, max(2, lineSpacing))
        copy.focusPosition = min(0.8, max(0.2, focusPosition))
        return copy
    }

    private func nearestStep(_ value: Int, step: Int) -> Int {
        Int((Double(value) / Double(step)).rounded()) * step
    }

    private func nearestStep(_ value: Double, step: Double) -> Double {
        (value / step).rounded() * step
    }
}

struct TeleCueSettingsStore {
    private let defaults: UserDefaults
    private let key = "telecue.settings.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> TeleCueSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(TeleCueSettings.self, from: data) else {
            return .default
        }
        return settings.normalized
    }

    func save(_ settings: TeleCueSettings) {
        guard let data = try? JSONEncoder().encode(settings.normalized) else { return }
        defaults.set(data, forKey: key)
    }
}

