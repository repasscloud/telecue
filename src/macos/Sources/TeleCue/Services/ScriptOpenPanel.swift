import AppKit
import UniformTypeIdentifiers
import TeleCueCore

@MainActor
enum ScriptOpenPanel {
    static func present(for model: TeleCueModel) {
        let panel = NSOpenPanel()
        panel.title = "Open a script"
        panel.message = "Choose a UTF-8 plain text or Markdown file."
        panel.prompt = "Open Script"
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            .plainText,
            UTType(filenameExtension: "md"),
            UTType(filenameExtension: "markdown")
        ].compactMap { $0 }

        guard panel.runModal() == .OK, let url = panel.url else { return }
        model.loadScript(from: url)
    }
}

