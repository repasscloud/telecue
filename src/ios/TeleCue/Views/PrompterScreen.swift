import SwiftUI
import TeleCueCore
import UIKit

struct PrompterScreen: View {
    @Bindable var model: TeleCueModel
    @Environment(\.dismiss) private var dismiss
    @State private var controlsVisible = true
    @State private var hideControlsTask: Task<Void, Never>?
    @FocusState private var keyboardFocused: Bool

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            ZStack {
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
                        },
                        onTap: toggleControls
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
            }

            if controlsVisible {
                controls
                    .transition(.opacity)
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .focusable()
        .focusEffectDisabled()
        .focused($keyboardFocused)
        .onKeyPress(phases: .down, action: handleKeyPress)
        .onChange(of: model.isPlaying) { _, isPlaying in
            if isPlaying {
                scheduleControlsHide()
            } else {
                showControls()
            }
        }
        .onAppear {
            // A teleprompter must never dim or lock mid-take.
            UIApplication.shared.isIdleTimerDisabled = true
            keyboardFocused = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            hideControlsTask?.cancel()
            if model.isPlaying {
                model.togglePlayback()
            }
        }
    }

    private var controls: some View {
        VStack {
            HStack(spacing: 4) {
                ControlButton("Close prompter", systemImage: "xmark") {
                    dismiss()
                }

                Spacer()

                ControlButton("Decrease font size", systemImage: "textformat.size.smaller") {
                    model.adjustFontSize(by: -2)
                }

                ControlButton("Increase font size", systemImage: "textformat.size.larger") {
                    model.adjustFontSize(by: 2)
                }

                ControlButton(
                    model.settings.focusEnabled ? "Hide focus guide" : "Show focus guide",
                    systemImage: "scope",
                    isOn: model.settings.focusEnabled
                ) {
                    model.toggleFocus()
                }

                ControlButton(
                    model.settings.mirrorEnabled ? "Disable mirror" : "Enable mirror",
                    systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right",
                    isOn: model.settings.mirrorEnabled
                ) {
                    model.toggleMirror()
                }
            }
            .controlBar()

            Spacer()

            if model.settings.focusEnabled {
                Slider(
                    value: Binding(
                        get: { model.settings.focusPosition },
                        set: { model.setFocusPosition($0) }
                    ),
                    in: 0.2...0.8
                ) {
                    Text("Focus position")
                } minimumValueLabel: {
                    Image(systemName: "arrow.up.to.line")
                } maximumValueLabel: {
                    Image(systemName: "arrow.down.to.line")
                }
                .tint(Color(red: 0.20, green: 0.76, blue: 0.92))
                .frame(maxWidth: 360)
                .controlBar()
            }

            HStack(spacing: 4) {
                ControlButton("Restart", systemImage: "backward.end.fill") {
                    model.restart()
                }

                ControlButton(
                    model.isPlaying ? "Pause" : "Play",
                    systemImage: model.isPlaying ? "pause.fill" : "play.fill",
                    prominent: true
                ) {
                    model.togglePlayback()
                }

                ControlButton("Decrease pace", systemImage: "minus") {
                    model.adjustWPM(by: -5)
                }

                VStack(spacing: 0) {
                    Text("\(model.settings.wordsPerMinute)")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                    Text("WPM")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(minWidth: 48)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(model.settings.wordsPerMinute) words per minute")

                ControlButton("Increase pace", systemImage: "plus") {
                    model.adjustWPM(by: 5)
                }
            }
            .controlBar()
        }
        .padding(12)
        .foregroundStyle(.white)
    }

    private func toggleControls() {
        if controlsVisible {
            hideControlsTask?.cancel()
            withAnimation(.easeOut(duration: 0.15)) {
                controlsVisible = false
            }
        } else {
            showControls()
            if model.isPlaying {
                scheduleControlsHide()
            }
        }
    }

    private func showControls() {
        hideControlsTask?.cancel()
        withAnimation(.easeOut(duration: 0.15)) {
            controlsVisible = true
        }
    }

    // Keep the controls out of the presenter's eyeline once the take is rolling.
    private func scheduleControlsHide() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled, model.isPlaying else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                controlsVisible = false
            }
        }
    }

    /// Hardware keyboards and Bluetooth page-turner remotes, matching the macOS prompter.
    private func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        guard press.modifiers.isDisjoint(with: [.command, .control, .option]) else { return .ignored }
        switch press.key {
        case .space:
            model.togglePlayback()
        case .upArrow:
            model.adjustWPM(by: 5)
        case .downArrow:
            model.adjustWPM(by: -5)
        case .escape:
            dismiss()
        default:
            switch press.characters.lowercased() {
            case "r": model.restart()
            case "m": model.toggleMirror()
            default: return .ignored
            }
        }
        return .handled
    }
}

private struct ControlButton: View {
    let title: String
    let systemImage: String
    var isOn = false
    var prominent = false
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String,
        isOn: Bool = false,
        prominent: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isOn = isOn
        self.prominent = prominent
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .symbolVariant(isOn ? .fill : .none)
                .font(prominent ? .title2 : .body)
                .frame(width: prominent ? 56 : 44, height: 44)
                .background {
                    if prominent || isOn {
                        Circle().fill(.white.opacity(prominent ? 0.2 : 0.12))
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private extension View {
    func controlBar() -> some View {
        padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(0.78), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.15)))
    }
}
