import AppKit
import SwiftUI

struct PrompterTextView: NSViewRepresentable {
    let text: String
    let format: ScriptFormat
    let fontSize: Double
    let lineSpacing: Double
    let position: Double
    let onMetricsChanged: @MainActor (Double, Double) -> Void
    let onManualScroll: @MainActor (Double) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .black
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.contentView.postsBoundsChangedNotifications = true

        let textView = NSTextView(frame: .zero)
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textColor = NSColor(calibratedWhite: 0.96, alpha: 1)
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        scrollView.documentView = textView

        context.coordinator.scrollView = scrollView
        context.coordinator.textView = textView
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.boundsDidChange),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = context.coordinator.textView else { return }
        context.coordinator.beginProgrammaticUpdate()
        defer { context.coordinator.endProgrammaticUpdate() }

        // updateNSView runs every frame during playback; only re-render when the input changes.
        let renderKey = RenderKey(text: text, format: format, fontSize: fontSize, lineSpacing: lineSpacing)
        if context.coordinator.lastRenderKey != renderKey {
            context.coordinator.lastRenderKey = renderKey
            let attributedText = text.isEmpty
                ? ScriptRenderer.render(
                    "Paste or open a script in the TeleCue editor.",
                    format: .plain,
                    fontSize: fontSize,
                    lineSpacing: lineSpacing
                )
                : ScriptRenderer.render(text, format: format, fontSize: fontSize, lineSpacing: lineSpacing)
            textView.textStorage?.setAttributedString(attributedText)
        }

        let viewport = scrollView.contentSize
        let horizontalInset = max(32, min(80, viewport.width * 0.07))
        let verticalInset = max(32, viewport.height * 0.35)
        textView.textContainerInset = NSSize(width: horizontalInset, height: verticalInset)
        textView.setFrameSize(NSSize(
            width: viewport.width,
            height: max(viewport.height, textView.frame.height)
        ))
        textView.textContainer?.containerSize = NSSize(
            width: max(1, viewport.width - horizontalInset * 2),
            height: .greatestFiniteMagnitude
        )
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        let usedHeight = textView.layoutManager?.usedRect(for: textView.textContainer!).height ?? 0
        let contentHeight = max(viewport.height, ceil(usedHeight + verticalInset * 2))
        textView.setFrameSize(NSSize(width: viewport.width, height: contentHeight))

        context.coordinator.reportMetricsIfChanged(
            contentHeight: contentHeight,
            viewportHeight: viewport.height
        )
        context.coordinator.setPosition(position)
    }

    static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
        NotificationCenter.default.removeObserver(coordinator)
    }

    struct RenderKey: Equatable {
        let text: String
        let format: ScriptFormat
        let fontSize: Double
        let lineSpacing: Double
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: PrompterTextView
        var lastRenderKey: RenderKey?
        weak var scrollView: NSScrollView?
        weak var textView: NSTextView?
        private var suppressScrollCallback = false
        private var lastContentHeight: Double = -1
        private var lastViewportHeight: Double = -1

        init(parent: PrompterTextView) {
            self.parent = parent
        }

        @objc func boundsDidChange() {
            guard !suppressScrollCallback, let scrollView else { return }
            parent.onManualScroll(scrollView.contentView.bounds.origin.y)
        }

        func setPosition(_ position: Double) {
            guard let scrollView else { return }
            let current = scrollView.contentView.bounds.origin.y
            guard abs(current - position) > 0.25 else { return }
            suppressScrollCallback = true
            scrollView.contentView.scroll(to: NSPoint(x: 0, y: position))
            scrollView.reflectScrolledClipView(scrollView.contentView)
            suppressScrollCallback = false
        }

        func beginProgrammaticUpdate() {
            suppressScrollCallback = true
        }

        func endProgrammaticUpdate() {
            suppressScrollCallback = false
        }

        func reportMetricsIfChanged(contentHeight: Double, viewportHeight: Double) {
            guard abs(contentHeight - lastContentHeight) > 0.5
                    || abs(viewportHeight - lastViewportHeight) > 0.5 else { return }
            lastContentHeight = contentHeight
            lastViewportHeight = viewportHeight
            parent.onMetricsChanged(contentHeight, viewportHeight)
        }
    }
}
