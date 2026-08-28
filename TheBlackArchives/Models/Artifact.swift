import Foundation

public struct Artifact: Identifiable, Codable, Hashable {
    public let id: String
    public let prompt: String
    public let seed: UInt64
    public let modelId: String
    public let engine: String
    public let latencySeconds: Double
    public let timestamp: Date
    public let imageFileName: String // filename in documents/artifacts/
    
    public var imageURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("artifacts/\(imageFileName)")
    }
    
    public func loadImageData() -> Data? {
        try? Data(contentsOf: imageURL)
    }
    
    public static func create(prompt: String, seed: UInt64, modelId: String, engine: String, latencySeconds: Double, imageData: Data) -> Artifact {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let artifactsDir = docs.appendingPathComponent("artifacts")
        try? FileManager.default.createDirectory(at: artifactsDir, withIntermediateDirectories: true)
        
        let fileName = "\(UUID().uuidString).png"
        let fileURL = artifactsDir.appendingPathComponent(fileName)
        try? imageData.write(to: fileURL)
        
        return Artifact(
            id: UUID().uuidString,
            prompt: prompt,
            seed: seed,
            modelId: modelId,
            engine: engine,
            latencySeconds: latencySeconds,
            timestamp: Date(),
            imageFileName: fileName
        )
    }
}
