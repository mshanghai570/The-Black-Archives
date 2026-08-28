import Foundation

public final class StorageManager {
    public static let shared = StorageManager()
    
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    private let artifactsKey = "artifacts_index"
    
    public func saveHistory(_ artifacts: [Artifact]) {
        if let data = try? jsonEncoder.encode(artifacts) {
            UserDefaults.standard.set(data, forKey: artifactsKey)
        }
    }
    
    public func loadHistory() -> [Artifact] {
        guard let data = UserDefaults.standard.data(forKey: artifactsKey) else { return [] }
        return (try? jsonDecoder.decode([Artifact].self, from: data)) ?? []
    }
    
    public func removeArtifact(id: String) {
        var artifacts = loadHistory()
        if let artifact = artifacts.first(where: { $0.id == id }) {
            try? FileManager.default.removeItem(at: artifact.imageURL)
        }
        artifacts.removeAll { $0.id == id }
        saveHistory(artifacts)
    }
    
    public func clearAllArtifacts() {
        let artifacts = loadHistory()
        for artifact in artifacts {
            try? FileManager.default.removeItem(at: artifact.imageURL)
        }
        UserDefaults.standard.removeObject(forKey: artifactsKey)
    }
    
    public func clearCoreMLCache() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let metalCache = caches.appendingPathComponent("com.apple.metal")
        try? FileManager.default.removeItem(at: metalCache)
    }
    
    public func clearAllCaches() {
        clearCoreMLCache()
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        try? FileManager.default.removeItem(at: caches.appendingPathComponent("StableDiffusion"))
        try? FileManager.default.removeItem(at: caches.appendingPathComponent("neuralnetwork"))
    }
}
