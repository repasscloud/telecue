import SwiftUI
import TeleCueCore

struct EditorView: View {
    @Bindable var model: TeleCueModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            editor
            Divider()
            footer
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .alert(
            "Couldn’t open script",
            isPresented: Binding(
                get: { model.alertMessage != nil },
                set: { if !$0 { model.dismissAlert() } }
            )
        ) {
            Button("OK", role: .cancel) {
                model.dismissAlert()
            }
        } message: {
            Text(model.alertMessage ?? "The file could not be opened.")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TeleCue")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                Text("Write at your pace. Read to the lens.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Open…", systemImage: "doc") {
                ScriptOpenPanel.present(for: model)
            }

            Button("Clear", systemImage: "trash") {
                model.clearScript()
            }
            .disabled(model.script.isEmpty)

            Divider()
                .frame(height: 28)

            WPMControl(model: model)

            Button {
                model.togglePlayback()
            } label: {
                Label(
                    model.isPlaying ? "Pause" : "Play",
                    systemImage: model.isPlaying ? "pause.fill" : "play.fill"
                )
                .frame(minWidth: 62)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.12, green: 0.48, blue: 0.72))
            .disabled(model.wordCount == 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $model.script)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .lineSpacing(5)
                .scrollContentBackground(.hidden)
                .padding(14)
                .accessibilityLabel("Script editor")

            if model.script.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Paste or write your script here")
                        .font(.system(.title3, design: .rounded, weight: .medium))
                    Text("You can also open a UTF-8 .txt or Markdown file.")
                        .font(.callout)
                }
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 34)
                .padding(.vertical, 32)
                .allowsHitTesting(false)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var footer: some View {
        HStack(spacing: 16) {
            ScriptStatusView(
                wordCount: model.wordCount,
                duration: model.formattedDuration,
                wordsPerMinute: model.settings.wordsPerMinute
            )

            Spacer()

            Button("Open Prompter", systemImage: "rectangle.on.rectangle") {
                PrompterWindowController.shared.show(model: model)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(model.wordCount == 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
