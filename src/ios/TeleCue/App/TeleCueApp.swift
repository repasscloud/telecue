import SwiftUI
import TeleCueCore

@main
struct TeleCueApp: App {
    @State private var model = TeleCueModel()

    var body: some Scene {
        WindowGroup {
            EditorScreen(model: model)
        }
    }
}
