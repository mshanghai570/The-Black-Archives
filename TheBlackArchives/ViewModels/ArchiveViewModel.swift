import SwiftUI

public final class ArchiveViewModel: ObservableObject {
    @Published public var artifacts: [Artifact] = []
    
    public init() {
        self.artifacts = StorageManager.shared.loadHistory()
    }
    
    public func saveArtifact(_ artifact: Artifact) {
        artifacts.insert(artifact, at: 0)
        StorageManager.shared.saveHistory(artifacts)
    }
    
    public func removeArtifact(id: String) {
        artifacts.removeAll { $0.id == id }
        StorageManager.shared.removeArtifact(id: id)
    }
    
    public func clearAll() {
        artifacts.removeAll()
        StorageManager.shared.clearAllArtifacts()
    }
    
    public func refreshFromDisk() {
        artifacts = StorageManager.shared.loadHistory()
    }
}
