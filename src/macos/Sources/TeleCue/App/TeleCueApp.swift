import AppKit
import SwiftUI
import TeleCueCore

@main
struct TeleCueApp: App {
    @State private var model = TeleCueModel()

    var body: some Scene {
        WindowGroup("TeleCue") {
            EditorView(model: model)
                .frame(minWidth: 680, minHeight: 480)
        }
        .defaultSize(width: 900, height: 650)
        .commands {
            TeleCueCommands(model: model)
        }
    }
}

private struct TeleCueCommands: Commands {
    let model: TeleCueModel

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Open Script…") {
                ScriptOpenPanel.present(for: model)
            }
            .keyboardShortcut("o", modifiers: .command)

            Button("Open Prompter") {
                PrompterWindowController.shared.show(model: model)
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
        }

        CommandMenu("Prompter") {
            Button(model.isPlaying ? "Pause" : "Play") {
                model.togglePlayback()
            }

            Button("Restart") {
                model.restart()
            }

            Divider()

            Button("Increase WPM") {
                model.adjustWPM(by: 5)
            }
            .keyboardShortcut(.upArrow, modifiers: .option)

            Button("Decrease WPM") {
                model.adjustWPM(by: -5)
            }
            .keyboardShortcut(.downArrow, modifiers: .option)

            Button("Increase Font Size") {
                model.adjustFontSize(by: 2)
            }
            .keyboardShortcut("+", modifiers: .command)

            Button("Decrease Font Size") {
                model.adjustFontSize(by: -2)
            }
            .keyboardShortcut("-", modifiers: .command)

            Divider()

            Button(model.settings.focusEnabled ? "Hide Focus Guide" : "Show Focus Guide") {
                model.toggleFocus()
            }

            Button(model.settings.mirrorEnabled ? "Disable Mirror" : "Enable Mirror") {
                model.toggleMirror()
            }

            Button("Toggle Presentation Mode") {
                PrompterWindowController.shared.togglePresentation(model: model)
            }
        }

        CommandGroup(replacing: .help) {
            Button("TeleCue Help") {
                if let url = URL(string: "https://example.com/telecue/help") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
