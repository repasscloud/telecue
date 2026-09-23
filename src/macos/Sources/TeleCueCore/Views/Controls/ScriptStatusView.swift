import SwiftUI

public struct ScriptStatusView: View {
    let wordCount: Int
    let duration: String
    let wordsPerMinute: Int

    public init(wordCount: Int, duration: String, wordsPerMinute: Int) {
        self.wordCount = wordCount
        self.duration = duration
        self.wordsPerMinute = wordsPerMinute
    }

    public var body: some View {
        Text(statusText)
            .font(.callout)
            .foregroundStyle(.secondary)
            .monospacedDigit()
            .accessibilityLabel(
                "\(wordCount) words, approximately \(duration) at \(wordsPerMinute) words per minute"
            )
    }

    private var statusText: String {
        "\(wordCount) \(wordCount == 1 ? "word" : "words") · approximately \(duration) at \(wordsPerMinute) WPM"
    }
}

