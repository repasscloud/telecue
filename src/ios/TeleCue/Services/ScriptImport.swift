import Foundation
import TeleCueCore
import UniformTypeIdentifiers

@MainActor
enum ScriptImport {
    /// Markdown is declared as an imported type in the app's Info.plist so the
    /// Files picker offers `.md` and `.markdown` files alongside plain text.
    static let contentTypes: [UTType] = [
        .plainText,
        UTType(importedAs: "net.daringfireball.markdown", conformingTo: .plainText)
    ]

    /// Files chosen in the document picker live outside the app sandbox, so they
    /// must be read inside a security-scoped access window.
    static func load(_ url: URL, into model: TeleCueModel) {
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        model.loadScript(from: url)
    }
}
