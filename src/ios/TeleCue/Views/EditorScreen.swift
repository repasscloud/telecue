import SwiftUI
import TeleCueCore

struct EditorScreen: View {
    @Bindable var model: TeleCueModel
    @State private var isImporting = false
    @State private var isPrompting = false
    @State private var importError: String?
    @FocusState private var editorFocused: Bool

    var body: some View {
        NavigationStack {
            editor
                .navigationTitle("TeleCue")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbar }
                .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: ScriptImport.contentTypes
        ) { result in
            switch result {
            case .success(let url):
                ScriptImport.load(url, into: model)
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
        .fullScreenCover(isPresented: $isPrompting) {
            PrompterScreen(model: model)
        }
        .alert(
            "Couldn’t open script",
            isPresented: Binding(
                get: { model.alertMessage != nil || importError != nil },
                set: { if !$0 { dismissAlert() } }
            )
        ) {
            Button("OK", role: .cancel) {
                dismissAlert()
            }
        } message: {
            Text(model.alertMessage ?? importError ?? "The file could not be opened.")
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button("Open", systemImage: "doc") {
                isImporting = true
            }

            Button("Clear", systemImage: "trash") {
                model.clearScript()
            }
            .disabled(model.script.isEmpty)
        }

        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") {
                editorFocused = false
            }
        }
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $model.script)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .lineSpacing(5)
                .focused($editorFocused)
                .scrollDismissesKeyboard(.interactively)
                .padding(.horizontal, 12)
                .accessibilityLabel("Script editor")

            if model.script.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Paste or write your script here")
                        .font(.system(.title3, design: .rounded, weight: .medium))
                    Text("You can also open a UTF-8 .txt or Markdown file.")
                        .font(.callout)
                }
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 17)
                .padding(.vertical, 8)
                .allowsHitTesting(false)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            ScriptStatusView(
                wordCount: model.wordCount,
                duration: model.formattedDuration,
                wordsPerMinute: model.settings.wordsPerMinute
            )
            .lineLimit(1)
            .minimumScaleFactor(0.75)

            HStack {
                WPMControl(model: model)

                Spacer()

                Button("Start Prompter", systemImage: "play.rectangle.fill") {
                    editorFocused = false
                    isPrompting = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.12, green: 0.48, blue: 0.72))
                .controlSize(.large)
                .disabled(model.wordCount == 0)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private func dismissAlert() {
        model.dismissAlert()
        importError = nil
    }
}
