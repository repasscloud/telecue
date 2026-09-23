import SwiftUI
import TeleCueCore
import UIKit

struct PrompterTextView: UIViewRepresentable {
    let text: String
    let format: ScriptFormat
    let fontSize: Double
    let lineSpacing: Double
    let position: Double
    let onMetricsChanged: @MainActor (Double, Double) -> Void
    let onManualScroll: @MainActor (Double) -> Void
    var onTap: @MainActor () -> Void = {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PrompterUITextView {
        // TextKit 1 lays out the whole script eagerly, so the measured content
        // height (and therefore the scroll speed) is exact rather than estimated.
        let textView = PrompterUITextView(usingTextLayoutManager: false)
        textView.isEditable = false
        textView.isSelectable = false
        textView.backgroundColor = .black
        textView.indicatorStyle = .white
        textView.alwaysBounceVertical = true
        textView.contentInsetAdjustmentBehavior = .never
        textView.textContainer.lineFragmentPadding = 0
        textView.accessibilityLabel = "Prompter script"
        textView.delegate = context.coordinator

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap)
        )
        textView.addGestureRecognizer(tap)

        textView.onSizeChange = { [weak coordinator = context.coordinator] in
            coordinator?.layout()
        }
        context.coordinator.textView = textView
        return textView
    }

    func updateUIView(_ textView: PrompterUITextView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.renderIfNeeded()
        context.coordinator.layout()
    }

    struct RenderKey: Equatable {
        let text: String
        let format: ScriptFormat
        let fontSize: Double
        let lineSpacing: Double
    }

    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: PrompterTextView
        weak var textView: PrompterUITextView?
        private var lastRenderKey: RenderKey?
        private var lastContentHeight: Double = -1
        private var lastViewportHeight: Double = -1

        init(parent: PrompterTextView) {
            self.parent = parent
        }

        // updateUIView runs every frame during playback; only re-render when the input changes.
        func renderIfNeeded() {
            guard let textView else { return }
            let key = RenderKey(
                text: parent.text,
                format: parent.format,
                fontSize: parent.fontSize,
                lineSpacing: parent.lineSpacing
            )
            guard key != lastRenderKey else { return }
            lastRenderKey = key
            textView.attributedText = parent.text.isEmpty
                ? ScriptRenderer.render(
                    "Write or open a script in the TeleCue editor.",
                    format: .plain,
                    fontSize: parent.fontSize,
                    lineSpacing: parent.lineSpacing
                )
                : ScriptRenderer.render(
                    parent.text,
                    format: parent.format,
                    fontSize: parent.fontSize,
                    lineSpacing: parent.lineSpacing
                )
        }

        func layout() {
            guard let textView, textView.bounds.width > 0, textView.bounds.height > 0 else { return }
            let viewport = textView.bounds.size
            let horizontalInset = max(24, min(80, viewport.width * 0.07))
            let verticalInset = max(32, viewport.height * 0.35)
            let inset = UIEdgeInsets(
                top: verticalInset,
                left: horizontalInset,
                bottom: verticalInset,
                right: horizontalInset
            )
            if textView.textContainerInset != inset {
                textView.textContainerInset = inset
            }

            textView.layoutManager.ensureLayout(for: textView.textContainer)
            let usedHeight = textView.layoutManager.usedRect(for: textView.textContainer).height
            let contentHeight = max(viewport.height, ceil(usedHeight + verticalInset * 2))

            reportMetricsIfChanged(contentHeight: contentHeight, viewportHeight: viewport.height)
            setPosition(parent.position)
        }

        private func setPosition(_ position: Double) {
            // While the presenter is dragging, their finger owns the offset.
            guard let textView, !isUserScrolling(textView) else { return }
            guard abs(textView.contentOffset.y - position) > 0.25 else { return }
            textView.contentOffset = CGPoint(x: 0, y: position)
        }

        private func reportMetricsIfChanged(contentHeight: Double, viewportHeight: Double) {
            guard abs(contentHeight - lastContentHeight) > 0.5
                    || abs(viewportHeight - lastViewportHeight) > 0.5 else { return }
            lastContentHeight = contentHeight
            lastViewportHeight = viewportHeight
            parent.onMetricsChanged(contentHeight, viewportHeight)
        }

        private func isUserScrolling(_ scrollView: UIScrollView) -> Bool {
            scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating
        }

        // Programmatic offset changes also land here, so only touch-driven
        // movement is reported as a manual reposition.
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard isUserScrolling(scrollView) else { return }
            parent.onManualScroll(scrollView.contentOffset.y)
        }

        @objc func handleTap() {
            parent.onTap()
        }
    }
}

final class PrompterUITextView: UITextView {
    var onSizeChange: (() -> Void)?
    private var lastLayoutSize = CGSize.zero

    // UIScrollView lays out on every offset change; only a new size needs re-measuring.
    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != lastLayoutSize else { return }
        lastLayoutSize = bounds.size
        onSizeChange?()
    }
}
