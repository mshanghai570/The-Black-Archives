import Foundation

public struct AIModel: Identifiable, Codable {
    public let id: String
    public let name: String
    public let author: String
    public let description: String
    public let fileSizeBytes: Int64
    public var format: ModelFormat
    public var isInstalled: Bool
    public var localFileURL: String? // For imported models
    public let isLocalCatalog: Bool // True for built-in catalog entries (not HuggingFace search results)

    // Download manifest for catalog models. `repoId` is the real HuggingFace
    // repository and `downloadFiles` are the exact root-level filenames to
    // fetch from it. Kept separate from `id` (the catalog key) so persisted
    // install state and selection stay stable even if the source repo moves.
    public var repoId: String?
    public var downloadFiles: [String]?

    // Recommended generation defaults per model family. Turbo/distilled
    // models (SDXL-Turbo, LCM) want a handful of steps and CFG ≈ 1.0; full
    // SD1.5/SDXL want 20-30 steps and CFG 5-9. SD1.5 is trained at 512px,
    // SDXL-family at 1024px.
    public var defaultSteps: Int?
    public var defaultCfgScale: Float?
    public var recommendedSize: Int?
    
    public enum ModelFormat: String, Codable {
        case coreML = "CoreML"
        case mlx = "MLX"
        case gguf = "GGUF"
        case safetensors = "SafeTensor"
        case lora = "LoRA"
        case vae = "VAE"
        case clip = "CLIP"
        case tokenizer = "Tokenizer"
    }
}
