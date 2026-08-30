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
