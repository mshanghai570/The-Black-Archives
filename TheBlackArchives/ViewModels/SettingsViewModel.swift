import SwiftUI

public final class SettingsViewModel: ObservableObject {
    @Published public var useMetalGPU: Bool {
        didSet { UserDefaults.standard.set(useMetalGPU, forKey: "settings_useMetalGPU") }
    }
    @Published public var lowMemoryMode: Bool {
        didSet { UserDefaults.standard.set(lowMemoryMode, forKey: "settings_lowMemoryMode") }
    }
    
    public init() {
        self.useMetalGPU = UserDefaults.standard.bool(forKey: "settings_useMetalGPU")
        self.lowMemoryMode = UserDefaults.standard.object(forKey: "settings_lowMemoryMode") as? Bool ?? true
    }
    
    public func clearCache() {
        StorageManager.shared.clearAllCaches()
        Logger.info("Cache cleared.")
    }
}
