import SwiftUI
import CoreGraphics
import UIKit

struct HomeView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var repoVM: RepositoryViewModel
    @EnvironmentObject var archiveVM: ArchiveViewModel
    @State private var activeTab = 0
    @Namespace private var tabNamespace
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TabView(selection: $activeTab) {
                    GeneratorTabView(activeTab: $activeTab)
                        .tabItem { 
                            Label("Console", systemImage: ArchiveIcons.generator)
                                .symbolEffect(.bounce, value: activeTab == 0)
                        }
                        .tag(0)
                    
                    RepositoryView(activeTab: $activeTab)
                        .tabItem { 
                            Label("Repository", systemImage: ArchiveIcons.repository)
                                .symbolEffect(.bounce, value: activeTab == 1)
                        }
                        .tag(1)
                    
                    ArchiveView(activeTab: $activeTab)
                        .tabItem { 
                            Label("Recoveries", systemImage: ArchiveIcons.history)
                                .symbolEffect(.bounce, value: activeTab == 2)
                        }
                        .tag(2)
                    
                    SettingsView(activeTab: $activeTab)
                        .tabItem { 
                            Label("Settings", systemImage: ArchiveIcons.settings)
                                .symbolEffect(.bounce, value: activeTab == 3)
                        }
                        .tag(3)
                }
                .accentColor(ArchiveColors.bronze)
            }
            
            if homeVM.isGenerating {
                LoadingOverlay(
                    progress: homeVM.generationProgress,
                    message: homeVM.logs.last ?? "Processing..."
                )
                .transition(.opacity)
            }
        }
        .background(ArchiveColors.background.edgesIgnoringSafeArea(.all))
    }
}

private enum OutputAspectRatio: String, CaseIterable, Identifiable {
    case square = "1:1"
    case portrait = "2:3"
    case landscape = "3:2"
    case wide = "16:9"

    var id: String { rawValue }
    var label: String { rawValue }

    func dimensions(base: Int) -> (width: Int, height: Int) {
        switch self {
        case .square: return (base, base)
        case .portrait: return (base, max(64, Int(Double(base) * 1.5)))
        case .landscape: return (max(64, Int(Double(base) * 1.5)), base)
        case .wide: return (max(64, Int(Double(base) * 1.777)), base)
        }
    }
}

struct GeneratorTabView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var repoVM: RepositoryViewModel
    @EnvironmentObject var archiveVM: ArchiveViewModel
    @EnvironmentObject var presetStore: PromptPresetStore
    @Binding var activeTab: Int
    @State private var prompt = ""
    @State private var negativePrompt = Constants.defaultNegativePrompt
    @State private var steps = 20
    @State private var cfgScale: Double = 7.0
    @State private var aspectRatio: OutputAspectRatio = .square
    @State private var seedText = ""
    @State private var lockSeed = false
    @State private var presetTitle = ""
    @State private var showSavePreset = false
    @State private var showDocumentPicker = false
    @FocusState private var isPromptFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ArchiveHeader(title: "Denoising Matrix", subtitle: "Active Hardware Core")
                
                // Model Picker
                ArchiveCard(title: "Engine Core", subtitle: "Select Model") {
                    VStack(spacing: 8) {
                        ForEach(repoVM.models.filter { $0.isInstalled }) { model in
                            Button(action: { repoVM.selectModel(id: model.id) }) {
                                HStack {
                                    Circle()
                                        .fill(repoVM.selectedModelId == model.id ? ArchiveColors.bronze : ArchiveColors.border)
                                        .frame(width: 10, height: 10)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(model.name)
                                            .font(ArchiveTypography.courier(size: 10))
                                            .foregroundColor(ArchiveColors.text)
                                            .fontWeight(.bold)
                                        Text(model.format.rawValue)
                                            .font(ArchiveTypography.courier(size: 8))
                                            .foregroundColor(ArchiveColors.textMuted)
                                    }
                                    Spacer()
                                    if repoVM.selectedModelId == model.id {
                                        Image(systemName: ArchiveIcons.check)
                                            .foregroundColor(ArchiveColors.green)
                                            .font(.system(size: 14))
                                    }
                                }
                                .padding(10)
                                .background(repoVM.selectedModelId == model.id
                                    ? ArchiveColors.bronze.opacity(0.1)
                                    : Color.clear)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(repoVM.selectedModelId == model.id
                                            ? ArchiveColors.bronze.opacity(0.4)
                                            : ArchiveColors.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if repoVM.models.filter({ $0.isInstalled }).isEmpty {
                            @State var appearsCount = 0
                            
                            VStack(spacing: 20) {
                                Image(systemName: "server.rack")
                                    .font(.system(size: 40))
                                    .foregroundColor(ArchiveColors.textMuted)
                                    .symbolEffect(.bounce, value: appearsCount)
                                    .onAppear {
                                        appearsCount += 1
                                    }
                                
                                Text("NO MODELS INSTALLED")
                                    .font(ArchiveTypography.courier(size: 12))
                                    .foregroundColor(ArchiveColors.textMuted)
                                    .fontWeight(.bold)
                                
                                Text("Download from Repository or import local files")
                                    .font(ArchiveTypography.courier(size: 9))
                                    .foregroundColor(ArchiveColors.textMuted.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                
                                VStack(spacing: 12) {
                                    ArchiveButton(title: "Open Repository", icon: "arrow.right") {
                                        activeTab = 1
                                    }
                                    
                                    Button(action: { 
                                        HapticFeedback.light.trigger()
                                        showDocumentPicker = true 
                                    }) {
                                        HStack {
                                            Image(systemName: "folder.badge.plus")
                                                .foregroundColor(ArchiveColors.bronze)
                                            Text("IMPORT LOCAL MODEL FILE")
                                                .font(ArchiveTypography.courier(size: 9))
                                                .foregroundColor(ArchiveColors.bronze)
                                                .fontWeight(.bold)
                                        }
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(ArchiveColors.bronze.opacity(0.12))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(ArchiveColors.bronze.opacity(0.4), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            Divider()
                                .background(ArchiveColors.border)
                                .padding(.vertical, 4)
                            
                            Button(action: { 
                                HapticFeedback.light.trigger()
                                showDocumentPicker = true 
                            }) {
                                HStack {
                                    Image(systemName: "folder.badge.plus")
                                        .foregroundColor(ArchiveColors.bronze)
                                    Text("IMPORT LOCAL MODEL FILE")
                                        .font(ArchiveTypography.courier(size: 9))
                                        .foregroundColor(ArchiveColors.bronze)
                                        .fontWeight(.bold)
                                    Spacer()
                                }
                                .padding(10)
                                .background(ArchiveColors.cardBackground)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(ArchiveColors.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                
                // Prompt + Steps + Generate
                ArchiveCard(title: "Input Prompts", subtitle: "Latent Sourcing") {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            ArchiveTextField(placeholder: "ENTER ARCHIVE SOURCING PROMPT...", text: $prompt)
                                .focused($isPromptFocused)
                            Menu {
                                ForEach(presetStore.allPresets) { preset in
                                    Button(preset.title) { applyPreset(preset) }
                                }
                            } label: {
                                Image(systemName: "text.book.closed")
                                    .foregroundColor(ArchiveColors.bronze)
                                    .frame(width: 36, height: 36)
                                    .background(ArchiveColors.bronze.opacity(0.12))
                                    .cornerRadius(6)
                            }
                            .accessibilityLabel("Prompt presets")
                        }

                        HStack {
                            Text("PROMPT LIBRARY")
                                .font(ArchiveTypography.courier(size: 8))
                                .foregroundColor(ArchiveColors.textMuted)
                            Spacer()
                            Button("SAVE AS PRESET") { showSavePreset = true }
                                .font(ArchiveTypography.courier(size: 8))
                                .foregroundColor(ArchiveColors.bronze)
                                .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }

                        DisclosureGroup {
                            VStack(spacing: 12) {
                                ArchiveTextField(placeholder: "NEGATIVE PROMPT (OPTIONAL)...", text: $negativePrompt)
                                HStack {
                                    Text("ASPECT")
                                        .font(ArchiveTypography.courier(size: 8))
                                        .foregroundColor(ArchiveColors.textMuted)
                                    Spacer()
                                    Picker("Aspect ratio", selection: $aspectRatio) {
                                        ForEach(OutputAspectRatio.allCases) { ratio in
                                            Text(ratio.label).tag(ratio)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(ArchiveColors.bronze)
                                }
                                HStack {
                                    Text("SEED")
                                        .font(ArchiveTypography.courier(size: 8))
                                        .foregroundColor(ArchiveColors.textMuted)
                                    TextField("Random", text: $seedText)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .font(ArchiveTypography.courier(size: 9))
                                        .foregroundColor(ArchiveColors.text)
                                    Toggle("Lock", isOn: $lockSeed)
                                        .labelsHidden()
                                        .tint(ArchiveColors.bronze)
                                }
                            }
                            .padding(.top, 8)
                        } label: {
                            Text("ADVANCED CONTROLS")
                                .font(ArchiveTypography.courier(size: 8))
                                .foregroundColor(ArchiveColors.bronze)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("STEPS")
                                    .font(ArchiveTypography.courier(size: 8))
                                    .foregroundColor(ArchiveColors.textMuted)
                                Spacer()
                                Text("\(steps)")
                                    .font(ArchiveTypography.courier(size: 9))
                                    .foregroundColor(ArchiveColors.bronze)
                                    .fontWeight(.bold)
                            }
                            Slider(value: Binding(
                                get: { Double(steps) },
                                set: { steps = Int($0) }
                            ), in: 1...50, step: 1)
                            .accentColor(ArchiveColors.bronze)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("CFG SCALE")
                                    .font(ArchiveTypography.courier(size: 8))
                                    .foregroundColor(ArchiveColors.textMuted)
                                Spacer()
                                Text(String(format: "%.1f", cfgScale))
                                    .font(ArchiveTypography.courier(size: 9))
                                    .foregroundColor(ArchiveColors.bronze)
                                    .fontWeight(.bold)
                            }
                            Slider(value: $cfgScale, in: 1...12, step: 0.5)
                                .accentColor(ArchiveColors.bronze)
                        }
                        
                        ArchiveButton(title: "Execute Retrieval", isAccent: true) {
                            HapticFeedback.medium.trigger()
                            SoundManager.shared.playGenerate()
                            runGeneration()
                        }
                        .disabled(homeVM.isGenerating)
                    }
                }
                
                // Model Status Bar
                ArchiveCard(title: "Engine Status", subtitle: "Active Core") {
                    if let model = repoVM.selectedModel {
                        HStack(spacing: 12) {
                            Image(systemName: "cpu")
                                .font(.system(size: 16))
                                .foregroundColor(ArchiveColors.bronze)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.name)
                                    .font(ArchiveTypography.courier(size: 10))
                                    .fontWeight(.bold)
                                    .foregroundColor(ArchiveColors.text)
                                Text("\(model.format.rawValue) · Ready")
                                    .font(ArchiveTypography.courier(size: 8))
                                    .foregroundColor(ArchiveColors.green)
                            }
                            
                            Spacer()
                            
                            Circle()
                                .fill(ArchiveColors.green)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(ArchiveColors.green.opacity(0.4), lineWidth: 3)
                                )
                        }
                        .padding(10)
                        .background(ArchiveColors.green.opacity(0.05))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(ArchiveColors.green.opacity(0.2), lineWidth: 1)
                        )
                    } else {
                        HStack(spacing: 12) {
                            Image(systemName: ArchiveIcons.warning)
                                .font(.system(size: 16))
                                .foregroundColor(ArchiveColors.textMuted)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("No model selected")
                                    .font(ArchiveTypography.courier(size: 10))
                                    .fontWeight(.bold)
                                    .foregroundColor(ArchiveColors.textMuted)
                                Text("Import or select a model above")
                                    .font(ArchiveTypography.courier(size: 8))
                                    .foregroundColor(ArchiveColors.textMuted)
                            }
                            
                            Spacer()
                            
                            Button(action: { activeTab = 1 }) {
                                Text("Repository")
                                    .font(ArchiveTypography.courier(size: 8))
                                    .foregroundColor(ArchiveColors.bronze)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(ArchiveColors.bronze.opacity(0.1))
                                    .cornerRadius(4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(ArchiveColors.bronze.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(10)
                        .background(ArchiveColors.textMuted.opacity(0.05))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(ArchiveColors.border, lineWidth: 1)
                        )
                    }
                }
                
                // Error
                if let error = homeVM.errorMessage {
                    ArchiveCard(title: "Error", subtitle: "System Fault") {
                        Text(error)
                            .font(ArchiveTypography.courier(size: 9))
                            .foregroundColor(.red)
                            .lineLimit(4)
                    }
                }
                
                // Result Preview
                if let result = homeVM.lastResult {
                    ArchiveCard(title: "Last Generated", subtitle: "Preview") {
                            let uiImage = UIImage(cgImage: result.image)
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(4)
                                .transition(.opacity.combined(with: .scale))
                                .id(result.image)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(ArchiveColors.border, lineWidth: 1)
                                )
                                .shadow(color: ArchiveColors.bronze.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            HStack(spacing: 16) {
                                MetricPill(label: "Seed", value: "\(result.seed)")
                                MetricPill(label: "Time", value: String(format: "%.2fs", result.latencySeconds))
                                MetricPill(label: "Steps", value: "\(steps)")
                            }
                            
                            ArchiveButton(title: "Save to Archive") {
                                saveToArchive(result: result)
                            }
                            .disabled(result.isPlaceholder)
                        }
                    }
                                
                    // Logs
                if !homeVM.logs.isEmpty {
                    ArchiveCard(title: "Execution Logs", subtitle: "Metal Registers") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(homeVM.logs.suffix(10), id: \.self) { log in
                                Text(log)
                                    .font(ArchiveTypography.courier(size: 8.5))
                                    .foregroundColor(log.contains("ERROR") ? .red : ArchiveColors.green)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isPromptFocused = false
        }
        .onAppear {
            applyModelDefaults()
        }
        .onChange(of: repoVM.selectedModelId) { _, _ in
            applyModelDefaults()
        }
        .alert("Save Prompt Preset", isPresented: $showSavePreset) {
            TextField("Preset name", text: $presetTitle)
            Button("Save") {
                presetStore.save(title: presetTitle, prompt: prompt, negativePrompt: negativePrompt, steps: steps, cfgScale: cfgScale)
                presetTitle = ""
            }
            Button("Cancel", role: .cancel) { presetTitle = "" }
        } message: {
            Text("Keep this prompt and its generation settings in your local library.")
        }
        .sheet(isPresented: $showDocumentPicker) {
            LocalModelImporter(isPresented: $showDocumentPicker) { urls in
                guard let url = urls.first else { return }
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                repoVM.importLocalModel(url: url)
            }
        }
    }
    
    private func runGeneration() {
        let trimmed = prompt.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard let model = repoVM.selectedModel else {
            homeVM.errorMessage = "Select a model from the Repository first."
            return
        }
        
        Task {
            do {
                let dimensions = aspectRatio.dimensions(base: model.recommendedSize ?? 512)
                let lockedSeed = lockSeed ? UInt64(seedText) : nil
                try await homeVM.triggerGeneration(
                    prompt: prompt,
                    negativePrompt: negativePrompt,
                    model: model,
                    steps: steps,
                    cfgScale: Float(cfgScale),
                    width: dimensions.width,
                    height: dimensions.height,
                    seed: lockedSeed
                )
            } catch {
                homeVM.errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Applies the selected model's recommended steps/CFG when the active
    /// model changes, so the sliders always start at sensible values for the
    /// architecture in use (turbo ≈ 1-4 steps / CFG 1, full ≈ 25-30 / CFG 7).
    private func applyPreset(_ preset: PromptPreset) {
        prompt = preset.promptText
        negativePrompt = preset.negativePrompt
        steps = preset.steps
        cfgScale = preset.cfgScale
    }

    private func applyModelDefaults() {
        guard let model = repoVM.selectedModel else { return }
        if let defaultSteps = model.defaultSteps {
            steps = defaultSteps
        }
        if let defaultCfg = model.defaultCfgScale {
            cfgScale = Double(defaultCfg)
        }
    }
    
    private func saveToArchive(result: GenerationResult) {
        // Never persist placeholder renders as if they were real artifacts.
        guard !result.isPlaceholder else { return }
        guard let pngData = ImageGenerationService.encodePNGData(from: result.image) else { return }
        let artifact = Artifact.create(
            prompt: prompt,
            seed: result.seed,
            modelId: repoVM.selectedModel?.id ?? "unknown",
            engine: repoVM.selectedModel?.format.rawValue ?? "CoreML",
            latencySeconds: result.latencySeconds,
            imageData: pngData
        )
        archiveVM.saveArtifact(artifact)
        homeVM.resetResult()
    }
}

struct MetricPill: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(ArchiveTypography.courier(size: 9))
                .foregroundColor(ArchiveColors.text)
                .fontWeight(.bold)
            Text(label.uppercased())
                .font(ArchiveTypography.courier(size: 7))
                .foregroundColor(ArchiveColors.textMuted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(ArchiveColors.cardBackground)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(ArchiveColors.border, lineWidth: 1)
        )
    }
}
