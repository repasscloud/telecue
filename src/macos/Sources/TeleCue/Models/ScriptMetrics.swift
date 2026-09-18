import Foundation

enum ScriptMetrics {
    static func wordCount(in text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace }).count
    }

    static func durationSeconds(wordCount: Int, wordsPerMinute: Int) -> Double {
        guard wordCount > 0, wordsPerMinute > 0 else { return 0 }
        return Double(wordCount) / Double(wordsPerMinute) * 60
    }
}

