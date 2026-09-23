import SwiftUI

public struct FocusGuideOverlay: View {
    let position: Double
    let fontSize: Double

    public init(position: Double, fontSize: Double) {
        self.position = position
        self.fontSize = fontSize
    }

    public var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let center = height * position
            let bandHeight = min(max(fontSize * 2.5, 72), height * 0.62)
            let topHeight = max(0, center - bandHeight / 2)
            let bottomStart = min(height, center + bandHeight / 2)

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    Color.black.opacity(0.62)
                        .frame(height: topHeight)
                    Color.clear
                        .frame(height: max(0, bottomStart - topHeight))
                    Color.black.opacity(0.62)
                }

                Rectangle()
                    .fill(Color(red: 0.20, green: 0.76, blue: 0.92).opacity(0.9))
                    .frame(width: max(0, proxy.size.width - 60), height: 2)
                    .position(x: proxy.size.width / 2, y: bottomStart)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

