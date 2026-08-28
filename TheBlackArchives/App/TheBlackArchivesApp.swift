import SwiftUI

@main
struct TheBlackArchivesApp: App {
    @StateObject private var homeVM = HomeViewModel()
    @StateObject private var repoVM = RepositoryViewModel()
    @StateObject private var settingsVM = SettingsViewModel()
    @StateObject private var archiveVM = ArchiveViewModel()

    var body: some Scene {
        WindowGroup {
            OnboardingView()
                .environmentObject(homeVM)
                .environmentObject(repoVM)
                .environmentObject(settingsVM)
                .environmentObject(archiveVM)
        }
    }
}
