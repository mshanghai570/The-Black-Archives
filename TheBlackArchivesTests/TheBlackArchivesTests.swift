//
//  TheBlackArchivesTests.swift
//  TheBlackArchivesTests
//
//  Created by Michael Shingara on 8/9/26.
//

import Testing
@testable import TheBlackArchives

struct TheBlackArchivesTests {

    @Test func builtInPresetsAreUsefulAndStable() async throws {
        #expect(PromptPreset.builtIns.count >= 3)
        #expect(PromptPreset.builtIns.allSatisfy { !$0.promptText.isEmpty })
        #expect(PromptPreset.builtIns.allSatisfy { $0.steps > 0 })
    }

    @Test func modelPackageValidationFindsNestedGeneratorFiles() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let wrapper = root.appendingPathComponent("downloaded-generator")
        try FileManager.default.createDirectory(at: wrapper, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let weights = wrapper.appendingPathComponent("model.gguf")
        try Data([0x47, 0x47, 0x55, 0x46]).write(to: weights)
        #expect(ModelManager.hasUsableModelFiles(at: root))

        try FileManager.default.removeItem(at: weights)
        #expect(!ModelManager.hasUsableModelFiles(at: root))
    }

    @Test func presetRoundTripsThroughCodable() async throws {
        let original = PromptPreset(
            title: "Test preset",
            promptText: "a moonlit observatory",
            negativePrompt: "blurry",
            steps: 18,
            cfgScale: 6.5
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PromptPreset.self, from: data)
        #expect(decoded == original)
    }

}
