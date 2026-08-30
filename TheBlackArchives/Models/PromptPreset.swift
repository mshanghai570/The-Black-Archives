import Foundation

public struct PromptPreset: Identifiable, Codable, Equatable {
    public let id: String
    public var title: String
    public var promptText: String
    public var negativePrompt: String
    public var steps: Int
    public var cfgScale: Double

    public init(
        id: String = UUID().uuidString,
        title: String,
        promptText: String,
        negativePrompt: String = Constants.defaultNegativePrompt,
        steps: Int = 20,
        cfgScale: Double = 7.0
    ) {
        self.id = id
        self.title = title
        self.promptText = promptText
        self.negativePrompt = negativePrompt
        self.steps = steps
        self.cfgScale = cfgScale
    }

    public static let builtIns: [PromptPreset] = [
        PromptPreset(
            id: "cinematic-portrait",
            title: "Cinematic Portrait",
            promptText: "cinematic portrait, expressive eyes, soft rim light, detailed skin, 85mm lens, editorial color grade",
            steps: 28,
            cfgScale: 7.0
        ),
        PromptPreset(
            id: "concept-environment",
            title: "Concept Environment",
            promptText: "vast atmospheric environment, architectural details, dramatic volumetric light, matte painting, high detail",
            steps: 30,
            cfgScale: 7.5
        ),
        PromptPreset(
            id: "product-studio",
            title: "Product Studio",
            promptText: "premium product photograph on a clean studio set, softbox lighting, subtle shadows, sharp focus",
            steps: 24,
            cfgScale: 6.5
        )
    ]
}

@MainActor
public final class PromptPresetStore: ObservableObject {
    @Published public private(set) var customPresets: [PromptPreset] = []

    private let storageKey = "blackArchives.promptPresets"

    public init() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([PromptPreset].self, from: data) else { return }
        customPresets = decoded
    }

    public var allPresets: [PromptPreset] {
        PromptPreset.builtIns + customPresets
    }

    public func save(title: String, prompt: String, negativePrompt: String, steps: Int, cfgScale: Double) {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty, !cleanedPrompt.isEmpty else { return }

        customPresets.removeAll { $0.title.caseInsensitiveCompare(cleanedTitle) == .orderedSame }
        customPresets.insert(
            PromptPreset(
                title: cleanedTitle,
                promptText: cleanedPrompt,
                negativePrompt: negativePrompt,
                steps: steps,
                cfgScale: cfgScale
            ),
            at: 0
        )
        persist()
    }

    public func delete(_ preset: PromptPreset) {
        guard !PromptPreset.builtIns.contains(preset) else { return }
        customPresets.removeAll { $0.id == preset.id }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(customPresets) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
