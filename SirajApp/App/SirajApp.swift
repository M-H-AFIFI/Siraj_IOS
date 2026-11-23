import SwiftUI
import SirajCore

@main
struct SirajApp: App {
    @State private var appState = AppState()
    @State private var locationService = LocationService()

    var body: some Scene {
        WindowGroup {
            SirajThemeProvider(settings: appState.settings, localizer: appState.localizer) {
                RootView(appState: appState, locationService: locationService)
            }
        }
    }
}
