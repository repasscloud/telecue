import Foundation

public struct TeleCueSettings: Codable, Equatable, Sendable {
    public var wordsPerMinute: Int
    public var fontSize: Double
    public var lineSpacing: Double
    public var focusEnabled: Bool
    public var focusPosition: Double
    public var mirrorEnabled: Bool
    public var borderlessPresentation: Bool

    public static let `default` = TeleCueSettings(
        wordsPerMinute: 150,
        fontSize: 42,
        lineSpacing: 10,
        focusEnabled: true,
        focusPosition: 0.45,
        mirrorEnabled: false,
        borderlessPresentation: false
    )

    public var normalized: TeleCueSettings {
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

public struct TeleCueSettingsStore {
    private let defaults: UserDefaults
    private let key = "telecue.settings.v1"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> TeleCueSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(TeleCueSettings.self, from: data) else {
            return .default
        }
        return settings.normalized
    }

    public func save(_ settings: TeleCueSettings) {
        guard let data = try? JSONEncoder().encode(settings.normalized) else { return }
        defaults.set(data, forKey: key)
    }
}

