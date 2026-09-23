import SwiftUI

struct PrompterView: View {
    @Bindable var model: TeleCueModel
    @State private var controlsVisible = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .ignoresSafeArea()

            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !model.isPlaying)) { context in
                PrompterTextView(
                    text: model.script,
                    format: model.scriptFormat,
                    fontSize: model.settings.fontSize,
                    lineSpacing: model.settings.lineSpacing,
                    position: model.scrollPosition,
                    onMetricsChanged: { contentHeight, viewportHeight in
                        model.updateRenderedMetrics(
                            contentHeight: contentHeight,
                            viewportHeight: viewportHeight
                        )
                    },
                    onManualScroll: { position in
                        model.seek(to: position)
                    }
                )
                .scaleEffect(x: model.settings.mirrorEnabled ? -1 : 1, y: 1)
                .onChange(of: context.date) { _, _ in
                    model.tick()
                }
            }

            if model.settings.focusEnabled {
                FocusGuideOverlay(
                    position: model.settings.focusPosition,
                    fontSize: model.settings.fontSize
                )
            }

            if controlsVisible {
                controls
                    .transition(.opacity)
            }
        }
        .background(Color.black)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                controlsVisible = hovering
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button {
                model.togglePlayback()
            } label: {
                Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
            }
            .help(model.isPlaying ? "Pause (Space)" : "Play (Space)")

            Button {
                model.restart()
            } label: {
                Image(systemName: "backward.end.fill")
            }
            .help("Restart (R)")

            Text("\(model.settings.wordsPerMinute) WPM")
                .font(.caption.monospacedDigit())
                .frame(minWidth: 62)

            Button {
                model.adjustFontSize(by: -2)
            } label: {
                Image(systemName: "textformat.size.smaller")
            }
            .help("Decrease font size (Command-minus)")

            Button {
                model.adjustFontSize(by: 2)
            } label: {
                Image(systemName: "textformat.size.larger")
            }
            .help("Increase font size (Command-plus)")

            Button {
                model.toggleFocus()
            } label: {
                Image(systemName: model.settings.focusEnabled ? "scope" : "scope")
                    .symbolVariant(model.settings.focusEnabled ? .fill : .none)
            }
            .help("Toggle focus guide")

            if model.settings.focusEnabled {
                Slider(
                    value: Binding(
                        get: { model.settings.focusPosition },
                        set: { model.setFocusPosition($0) }
                    ),
                    in: 0.2...0.8
                )
                .frame(width: 90)
                .help("Focus position")
            }

            Button {
                model.toggleMirror()
            } label: {
                Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                    .symbolVariant(model.settings.mirrorEnabled ? .fill : .none)
            }
            .help("Toggle mirror mode (M)")

            Button {
                PrompterWindowController.shared.togglePresentation(model: model)
            } label: {
                Image(systemName: model.settings.borderlessPresentation
                      ? "arrow.down.right.and.arrow.up.left"
                      : "arrow.up.left.and.arrow.down.right")
            }
            .help("Toggle presentation mode (F)")

            Button {
                PrompterWindowController.shared.close()
            } label: {
                Image(systemName: "xmark")
            }
            .help("Close prompter")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.black.opacity(0.78), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.15)))
        .padding(12)
    }
}
