import Foundation

enum ScriptFileError: LocalizedError, Equatable {
    case unsupportedFileType(String)
    case invalidUTF8
    case unreadable(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFileType(let fileExtension):
            return fileExtension.isEmpty
                ? "Choose a .txt, .md, or .markdown file."
                : ".\(fileExtension) files are not supported. Choose a .txt, .md, or .markdown file."
        case .invalidUTF8:
            return "The file is not valid UTF-8 text."
        case .unreadable(let message):
            return "The file could not be read: \(message)"
        }
    }
}

enum ScriptFileLoader {
    private static let supportedExtensions = Set(["txt", "md", "markdown"])

    static func load(from url: URL) throws -> String {
        let fileExtension = url.pathExtension.lowercased()
        guard supportedExtensions.contains(fileExtension) else {
            throw ScriptFileError.unsupportedFileType(fileExtension)
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ScriptFileError.unreadable(error.localizedDescription)
        }

        guard let text = String(data: data, encoding: .utf8) else {
            throw ScriptFileError.invalidUTF8
        }
        return text
    }
}
