import SwiftUI
import CoreGraphics

public struct GenerationResult {
    public let image: CGImage
    public let seed: UInt64
    public let latencySeconds: Double
    /// True when the image is a procedural placeholder produced because real
    /// inference failed — never save it to the archive as a real artifact.
    public let isPlaceholder: Bool
    
    public init(image: CGImage, seed: UInt64, latencySeconds: Double, isPlaceholder: Bool = false) {
        self.image = image
        self.seed = seed
        self.latencySeconds = latencySeconds
        self.isPlaceholder = isPlaceholder
    }
}

public final class HomeViewModel: ObservableObject {
    @Published public var isGenerating = false
    @Published public var generationProgress = 0
    @Published public var logs: [String] = []
    @Published public var lastResult: GenerationResult?
    @Published public var errorMessage: String?
    
    private let generationService = ImageGenerationService()
    private var pipelineLoaded = false
    private var loadedModelId: String?
    
    public init() {}
    
    public func loadPipelineIfNeeded(model: AIModel) async {
        guard loadedModelId != model.id else { return }
        
        await MainActor.run {
            self.logs.append("[Core] Loading \(model.name) pipeline...")
        }
        
        do {
            try generationService.loadPipeline(for: model)
            await MainActor.run {
                self.loadedModelId = model.id
                self.pipelineLoaded = true
                self.logs.append("[Core] \(model.name) pipeline ready.")
            }
        } catch {
            await MainActor.run {
                self.logs.append("[WARN] Pipeline not loadable: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    public func triggerGeneration(
        prompt: String,
        negativePrompt: String = Constants.defaultNegativePrompt,
        model: AIModel,
        steps: Int = 20,
        cfgScale: Float? = nil,
        width: Int? = nil,
        height: Int? = nil,
        seed: UInt64? = nil
    ) async throws {
        // Re-entrancy guard: the Generate button is disabled while running,
        // but protect against double-taps racing on the shared engine.
        guard !isGenerating else {
            self.logs.append("[WARN] Generation already in progress — request ignored.")
            return
        }
        self.isGenerating = true
        self.generationProgress = 0
        self.logs = ["[Core] Dispatching generative threads..."]
        self.errorMessage = nil
        
        if !pipelineLoaded || loadedModelId != model.id {
            await loadPipelineIfNeeded(model: model)
        }
        
        let actualSeed = seed ?? UInt64.random(in: 0...UInt64.max)
        let resolvedCfg = cfgScale ?? model.defaultCfgScale ?? 1.0
        let dimension = model.recommendedSize ?? 512
        let outputWidth = width ?? dimension
        let outputHeight = height ?? dimension
        
        self.logs.append("[Core] Seed: \(actualSeed)")
        self.logs.append("[Core] Steps: \(steps)")
        self.logs.append("[Core] CFG: \(String(format: "%.1f", resolvedCfg))")
        self.logs.append("[Core] Size: \(outputWidth)x\(outputHeight)")
        self.logs.append("[Core] Prompt: \(prompt.prefix(60))...")
        
        let startTime = CFAbsoluteTimeGetCurrent()

        // Run the heavy real inference off the main actor so the UI (and the
        // prompt button) stays responsive.
        let realImage: CGImage?
        do {
            realImage = try await Task.detached(priority: .userInitiated) {
                try await self.generationService.generate(
                    model: model,
                    prompt: prompt,
                    steps: steps,
                    cfgScale: resolvedCfg,
                    size: CGSize(width: outputWidth, height: outputHeight),
                    seed: actualSeed,
                    progressHandler: { fraction, message in
                        Task { @MainActor in
                            self.generationProgress = Int(fraction * 100)
                            self.logs.append(message)
                        }
                    }
                )
            }.value
        } catch {
            realImage = nil
            self.errorMessage = "Inference failed: \(error.localizedDescription)"
            self.logs.append("[ERROR] \(error.localizedDescription)")
        }

        let cgImage: CGImage
        if let realImage {
            cgImage = realImage
            self.errorMessage = nil
            self.logs.append("[Success] Artifact generated.")
        } else {
            // Honest placeholder: only produced when real inference failed, and
            // clearly labeled so it is never mistaken for a real generation.
            cgImage = ProceduralImageGenerator.shared.generate(
                prompt: prompt,
                negativePrompt: negativePrompt,
                steps: steps,
                size: CGSize(width: outputWidth, height: outputHeight),
                seed: actualSeed
            ) { fraction, message in
                Task { @MainActor in
                    self.generationProgress = Int(fraction * 100)
                    self.logs.append(message)
                }
            }
            self.logs.append("[WARN] Placeholder render produced — not a real generation. See error above.")
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        self.lastResult = GenerationResult(
            image: cgImage,
            seed: actualSeed,
            latencySeconds: elapsed,
            isPlaceholder: realImage == nil
        )
        self.generationProgress = 100
        self.logs.append("[Done] Completed in \(String(format: "%.2f", elapsed))s.")

        self.isGenerating = false
    }
    
    @MainActor
    public func resetResult() {
        lastResult = nil
        errorMessage = nil
    }
}
