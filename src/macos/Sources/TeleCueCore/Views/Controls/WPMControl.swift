import SwiftUI

public struct WPMControl: View {
    @Bindable var model: TeleCueModel

    public init(model: TeleCueModel) {
        self.model = model
    }

    public var body: some View {
        HStack(spacing: 6) {
            Button {
                model.adjustWPM(by: -5)
            } label: {
                Image(systemName: "minus")
            }
            .help("Decrease speaking pace")

            VStack(spacing: 0) {
                Text("\(model.settings.wordsPerMinute)")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                Text("WPM")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 52)

            Button {
                model.adjustWPM(by: 5)
            } label: {
                Image(systemName: "plus")
            }
            .help("Increase speaking pace")
        }
        .buttonStyle(.borderless)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Speaking pace")
    }
}

