import Foundation

// Reserved for future prompt preset management.
public struct PromptPreset: Identifiable, Codable {
    public let id: String
    public let title: String
    public let promptText: String
    public let negativePrompt: String
    public let steps: Int
}
