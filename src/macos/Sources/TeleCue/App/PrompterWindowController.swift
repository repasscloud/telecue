import AppKit
import SwiftUI

@MainActor
final class PrompterWindowController: NSObject, NSWindowDelegate {
    static let shared = PrompterWindowController()

    private let frameName = NSWindow.FrameAutosaveName("TeleCuePrompterWindow")
    private var panel: NSPanel?
    private var keyMonitor: Any?
    private weak var model: TeleCueModel?

    func show(model: TeleCueModel) {
        self.model = model

        if panel == nil {
            panel = makePanel(model: model)
        }

        guard let panel else { return }
        applyPresentationStyle(model.settings.borderlessPresentation, to: panel)
        installKeyMonitorIfNeeded()
        panel.orderFrontRegardless()
        panel.makeKey()
    }

    func togglePresentation(model: TeleCueModel) {
        show(model: model)
        let enabled = !model.settings.borderlessPresentation
        model.setBorderlessPresentation(enabled)
        if let panel {
            applyPresentationStyle(enabled, to: panel)
        }
    }

    func close() {
        panel?.orderOut(nil)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.saveFrame(usingName: frameName)
        sender.orderOut(nil)
        return false
    }

    func windowDidMove(_ notification: Notification) {
        panel?.saveFrame(usingName: frameName)
    }

    func windowDidResize(_ notification: Notification) {
        panel?.saveFrame(usingName: frameName)
    }

    private func makePanel(model: TeleCueModel) -> NSPanel {
        let defaultFrame = NSRect(x: 0, y: 0, width: 900, height: 250)
        let panel = NSPanel(
            contentRect: defaultFrame,
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "TeleCue Prompter"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.backgroundColor = .black
        panel.isOpaque = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.minSize = NSSize(width: 420, height: 150)
        panel.delegate = self
        panel.contentViewController = NSHostingController(rootView: PrompterView(model: model))

        if !panel.setFrameUsingName(frameName) {
            // Installing an NSHostingController can resize a new panel to its
            // fitting size, so restore the intended first-run frame afterward.
            panel.setFrame(defaultFrame, display: false)
            panel.center()
        }
        ensureVisible(panel)
        return panel
    }

    private func applyPresentationStyle(_ enabled: Bool, to panel: NSPanel) {
        let frame = panel.frame
        if enabled {
            panel.styleMask = [.borderless, .resizable, .fullSizeContentView]
            panel.hasShadow = true
        } else {
            panel.styleMask = [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView]
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
        }
        panel.setFrame(frame, display: true)
    }

    private func ensureVisible(_ panel: NSPanel) {
        let isVisibleOnScreen = NSScreen.screens.contains { screen in
            screen.visibleFrame.intersects(panel.frame)
        }
        if !isVisibleOnScreen {
            panel.setFrame(NSRect(x: 0, y: 0, width: 900, height: 250), display: false)
            panel.center()
        }
    }

    private func installKeyMonitorIfNeeded() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self,
                  event.window === self.panel,
                  let model = self.model else { return event }

            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if modifiers.contains(.command) || modifiers.contains(.control) || modifiers.contains(.option) {
                return event
            }

            switch event.keyCode {
            case 49: model.togglePlayback()
            case 15: model.restart()
            case 126: model.adjustWPM(by: 5)
            case 125: model.adjustWPM(by: -5)
            case 46: model.toggleMirror()
            case 3: self.togglePresentation(model: model)
            case 53:
                if model.settings.borderlessPresentation {
                    self.togglePresentation(model: model)
                } else {
                    return event
                }
            default: return event
            }
            return nil
        }
    }

}
