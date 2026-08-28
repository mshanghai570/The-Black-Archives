export interface SwiftFile {
  name: string;
  path: string;
  category: "App" | "Design" | "Components" | "Views" | "Models" | "ViewModels" | "Services" | "Utilities" | "Resources";
  language: "swift" | "json" | "markdown";
  description: string;
  code: string;
}

export const SWIFT_SOURCE_FILES: SwiftFile[] = [
  // --- App ---
  {
    name: "TheBlackArchivesApp.swift",
    path: "App/TheBlackArchivesApp.swift",
    category: "App",
    language: "swift",
    description: "The primary entry point of the application. Handles top-level environment container setups and loads active Swift services.",
    code: `import SwiftUI

@main
struct TheBlackArchivesApp: App {
    // Shared state managers injected as environment variables
    @StateObject private var homeVM = HomeViewModel()
    @StateObject private var repoVM = RepositoryViewModel()
    @StateObject private var archiveVM = ArchiveViewModel()
    @StateObject private var settingsVM = SettingsViewModel()
    
    var body: some Scene {
        WindowGroup {
            OnboardingView()
                .environmentObject(homeVM)
                .environmentObject(repoVM)
                .environmentObject(archiveVM)
                .environmentObject(settingsVM)
                .preferredColorScheme(.dark)
        }
    }
}
`
  },

  // --- Design ---
  {
    name: "ArchiveTheme.swift",
    path: "Design/ArchiveTheme.swift",
    category: "Design",
    language: "swift",
    description: "Centralized styling theme context providing consistent padding, borders, and custom modifiers.",
    code: `import SwiftUI

public enum ArchiveTheme {
    public static let borderWidth: CGFloat = 1.0
    public static let cornerRadius: CGFloat = 8.0
    
    public static func paperBorder<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding()
            .background(ArchiveColors.cardBackground)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(ArchiveColors.border, lineWidth: borderWidth)
            )
            .shadow(color: ArchiveColors.shadow, radius: 4, x: 0, y: 2)
    }
}
`
  },
  {
    name: "ArchiveColors.swift",
    path: "Design/ArchiveColors.swift",
    category: "Design",
    language: "swift",
    description: "Custom SwiftUI Color declarations mirroring the high-contrast classic paper style.",
    code: `import SwiftUI

public enum ArchiveColors {
    public static let background = Color("Background") // Deep charcoal dark black
    public static let cardBackground = Color("CardBackground") // Off-black canvas
    public static let text = Color("Text") // Warm gold / off-white bone
    public static let textMuted = Color("TextMuted") // Medium ash gray
    public static let bronze = Color("Bronze") // Warm primary bronze
    public static let border = Color("Border") // Dark line separators
    public static let green = Color("Green") // Terminal/status success green
    public static let shadow = Color.black.opacity(0.8)
}
`
  },
  {
    name: "ArchiveTypography.swift",
    path: "Design/ArchiveTypography.swift",
    category: "Design",
    language: "swift",
    description: "Design-system font modifiers enabling Cinzel, Inter, and Courier Prime styling on views.",
    code: `import SwiftUI

public enum ArchiveTypography {
    public static func cinzel(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("Cinzel-Regular", size: size)
    }
    
    public static func inter(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("Inter-Regular", size: size)
    }
    
    public static func courier(size: CGFloat) -> Font {
        Font.custom("CourierPrime-Regular", size: size)
    }
}
`
  },
  {
    name: "ArchiveSpacing.swift",
    path: "Design/ArchiveSpacing.swift",
    category: "Design",
    language: "swift",
    description: "Semantic metrics for paddings, stacks, and safe margins.",
    code: `import SwiftUI

public enum ArchiveSpacing {
    public static let micro: CGFloat = 4.0
    public static let small: CGFloat = 8.0
    public static let medium: CGFloat = 16.0
    public static let large: CGFloat = 24.0
    public static let huge: CGFloat = 36.0
}
`
  },
  {
    name: "ArchiveAnimations.swift",
    path: "Design/ArchiveAnimations.swift",
    category: "Design",
    language: "swift",
    description: "Custom transitions and spring modifiers representing traditional hardware feedback.",
    code: `import SwiftUI

public enum ArchiveAnimations {
    public static let classicSpring = Animation.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)
    public static let buttonTap = Animation.easeInOut(duration: 0.12)
    
    public static var listTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal: .opacity
        )
    }
}
`
  },
  {
    name: "ArchiveIcons.swift",
    path: "Design/ArchiveIcons.swift",
    category: "Design",
    language: "swift",
    description: "Unified SF Symbols mapping wrapper supporting safe asset references.",
    code: `import SwiftUI

public enum ArchiveIcons {
    public static let generator = "cpu"
    public static let repository = "square.stack.3d.up"
    public static let history = "photo.on.rectangle.angled"
    public static let settings = "gearshape"
    public static let warning = "exclamationmark.triangle"
    public static let check = "checkmark.circle"
    public static let download = "arrow.down.circle"
    public static let play = "play.fill"
    public static let cancel = "xmark.circle"
}
`
  },
  {
    name: "ArchiveShadows.swift",
    path: "Design/ArchiveShadows.swift",
    category: "Design",
    language: "swift",
    description: "Custom offset-drop shadowing variables for the brutalist paper layers.",
    code: `import SwiftUI

public enum ArchiveShadows {
    public static let heavy = Shadow(color: .black, radius: 10, x: 0, y: 6)
    public static let classic = Shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
}

public struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}
`
  },

  // --- Components ---
  {
    name: "ArchiveButton.swift",
    path: "Components/ArchiveButton.swift",
    category: "Components",
    language: "swift",
    description: "Bordered button component with micro-press haptic spring feedback.",
    code: `import SwiftUI

struct ArchiveButton: View {
    let title: String
    var icon: String? = nil
    var isAccent: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title.uppercased())
                    .font(ArchiveTypography.courier(size: 11))
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isAccent ? ArchiveColors.bronze.opacity(0.15) : ArchiveColors.cardBackground)
            .foregroundColor(isAccent ? ArchiveColors.bronze : ArchiveColors.text)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isAccent ? ArchiveColors.bronze : ArchiveColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
`
  },
  {
    name: "ArchiveCard.swift",
    path: "Components/ArchiveCard.swift",
    category: "Components",
    language: "swift",
    description: "Structured container with border dividers, custom title tags, and rounded edges.",
    code: `import SwiftUI

struct ArchiveCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content
    
    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(ArchiveTypography.cinzel(size: 11))
                        .fontWeight(.bold)
                        .foregroundColor(ArchiveColors.bronze)
                    if let subtitle = subtitle {
                        Text(subtitle.uppercased())
                            .font(ArchiveTypography.courier(size: 8))
                            .foregroundColor(ArchiveColors.textMuted)
                    }
                }
                Spacer()
            }
            .padding(.bottom, 6)
            .border(width: 1, edge: .bottom, color: ArchiveColors.border)
            
            content
        }
        .padding()
        .background(ArchiveColors.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ArchiveColors.border, lineWidth: 1)
        )
    }
}
`
  },
  {
    name: "ArchiveTextField.swift",
    path: "Components/ArchiveTextField.swift",
    category: "Components",
    language: "swift",
    description: "Monospaced custom text field input styled to represent manual keyboard interfaces.",
    code: `import SwiftUI

struct ArchiveTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(ArchiveColors.textMuted))
            .font(ArchiveTypography.courier(size: 11))
            .foregroundColor(ArchiveColors.text)
            .padding(12)
            .background(Color.black.opacity(0.3))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(ArchiveColors.border, lineWidth: 1)
            )
    }
}
`
  },
  {
    name: "ArchiveSection.swift",
    path: "Components/ArchiveSection.swift",
    category: "Components",
    language: "swift",
    description: "Layout section wrapper grouping child elements under header banners.",
    code: `import SwiftUI

struct ArchiveSection<Content: View>: View {
    let headerTitle: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.headerTitle = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(headerTitle.uppercased())
                .font(ArchiveTypography.courier(size: 9))
                .fontWeight(.bold)
                .foregroundColor(ArchiveColors.textMuted)
                .tracking(1.5)
            
            content
        }
    }
}
`
  },
  {
    name: "ArchiveHeader.swift",
    path: "Components/ArchiveHeader.swift",
    category: "Components",
    language: "swift",
    description: "Large cinematic title banner containing application badges.",
    code: `import SwiftUI

struct ArchiveHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(ArchiveTypography.cinzel(size: 18))
                .fontWeight(.bold)
                .foregroundColor(ArchiveColors.text)
                .tracking(2.0)
            
            Text(subtitle.uppercased())
                .font(ArchiveTypography.courier(size: 8))
                .foregroundColor(ArchiveColors.bronze)
                .tracking(1.5)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }
}
`
  },
  {
    name: "LoadingOverlay.swift",
    path: "Components/LoadingOverlay.swift",
    category: "Components",
    language: "swift",
    description: "Overlay display blocking user action during active neural generation.",
    code: `import SwiftUI

struct LoadingOverlay: View {
    let progress: Int
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Spinning indicator
                Circle()
                    .stroke(ArchiveColors.border, lineWidth: 3)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .trim(from: 0, to: 0.3)
                            .stroke(ArchiveColors.bronze, lineWidth: 3)
                            .rotationEffect(.degrees(Double(progress * 15)))
                    )
                
                VStack(spacing: 8) {
                    Text("\\(progress)% COMPLETED")
                        .font(ArchiveTypography.courier(size: 12))
                        .fontWeight(.bold)
                        .foregroundColor(ArchiveColors.text)
                    
                    Text(message)
                        .font(ArchiveTypography.courier(size: 9))
                        .foregroundColor(ArchiveColors.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
        }
    }
}
`
  },
  {
    name: "ProgressBar.swift",
    path: "Components/ProgressBar.swift",
    category: "Components",
    language: "swift",
    description: "Segmented step bar reporting progress of the active generation pipeline.",
    code: `import SwiftUI

struct ProgressBar: View {
    let value: Double // Range 0.0 - 1.0
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color.black.opacity(0.4))
                    .frame(height: 6)
                
                // Progress
                Rectangle()
                    .fill(ArchiveColors.bronze)
                    .frame(width: geo.size.width * CGFloat(value), height: 6)
            }
            .border(ArchiveColors.border, width: 1)
        }
        .frame(height: 6)
    }
}
`
  },

  // --- Views ---
  {
    name: "OnboardingView.swift",
    path: "Views/OnboardingView.swift",
    category: "Views",
    language: "swift",
    description: "Brutalist entry portal of the application showcasing visual license and introductory setups.",
    code: `import SwiftUI

struct OnboardingView: View {
    @State private var hasAccepted = false
    @EnvironmentObject var homeVM: HomeViewModel
    
    var body: some View {
        if hasAccepted {
            HomeView()
        } else {
            VStack(spacing: 30) {
                Spacer()
                
                ArchiveHeader(
                    title: "The Black Archives",
                    subtitle: "Secure Local Generative Framework"
                )
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("LICENSE MATRICES & ETHICS PROTOCOL")
                        .font(ArchiveTypography.cinzel(size: 11))
                        .fontWeight(.bold)
                        .foregroundColor(ArchiveColors.bronze)
                    
                    Text("This software processes local latent arrays solely inside sandbox hardware storage. By executing local generative pipelines, you confirm full ownership of models and accept local execution compliance guides.")
                        .font(ArchiveTypography.courier(size: 9.5))
                        .foregroundColor(ArchiveColors.textMuted)
                        .lineSpacing(4)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .border(ArchiveColors.border, width: 1)
                .padding(.horizontal, 24)
                
                Spacer()
                
                ArchiveButton(title: "Initialize Secure Core", isAccent: true) {
                    withAnimation {
                        hasAccepted = true
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
            .background(ArchiveColors.background.edgesIgnoringSafeArea(.all))
        }
    }
}
`
  },
  {
    name: "HomeView.swift",
    path: "Views/HomeView.swift",
    category: "Views",
    language: "swift",
    description: "Core dashboard showcasing the terminal logs, prompt config, and visual rendering canvas.",
    code: `import SwiftUI

struct HomeView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var repoVM: RepositoryViewModel
    @State private var activeTab = 0
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Tab Selection View
                TabView(selection: $activeTab) {
                    GeneratorTabView()
                        .tabItem { Label("Console", systemImage: ArchiveIcons.generator) }
                        .tag(0)
                    
                    RepositoryView()
                        .tabItem { Label("Repository", systemImage: ArchiveIcons.repository) }
                        .tag(1)
                    
                    ArchiveView()
                        .tabItem { Label("Recoveries", systemImage: ArchiveIcons.history) }
                        .tag(2)
                    
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: ArchiveIcons.settings) }
                        .tag(3)
                }
                .accentColor(ArchiveColors.bronze)
            }
            
            if homeVM.isGenerating {
                LoadingOverlay(
                    progress: homeVM.generationProgress,
                    message: homeVM.logs.last ?? "Processing..."
                )
            }
        }
        .background(ArchiveColors.background.edgesIgnoringSafeArea(.all))
    }
}

// Nested Generator console interface tab
struct GeneratorTabView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @State private var prompt = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ArchiveHeader(title: "Denoising Matrix", subtitle: "Active Hardware Core")
                
                ArchiveCard(title: "Input Prompts", subtitle: "Latent Sourcing") {
                    VStack(spacing: 12) {
                        ArchiveTextField(placeholder: "ENTER ARCHIVE SOURCING PROMPT...", text: $prompt)
                        
                        ArchiveButton(title: "Execute Retrieval", isAccent: true) {
                            Task {
                                try? await homeVM.triggerGeneration(prompt: prompt)
                            }
                        }
                    }
                }
                
                if !homeVM.logs.isEmpty {
                    ArchiveCard(title: "Execution Logs", subtitle: "Metal Registers") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(homeVM.logs, id: \\.self) { log in
                                Text(log)
                                    .font(ArchiveTypography.courier(size: 8.5))
                                    .foregroundColor(ArchiveColors.green)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}
`
  },
  {
    name: "RepositoryView.swift",
    path: "Views/RepositoryView.swift",
    category: "Views",
    language: "swift",
    description: "The HF model manager tab supporting fast searches, metadata audits, and background downloads.",
    code: `import SwiftUI

struct RepositoryView: View {
    @EnvironmentObject var repoVM: RepositoryViewModel
    @State private var searchQuery = ""
    
    var body: some View {
        VStack(spacing: 12) {
            ArchiveHeader(title: "Model Repository", subtitle: "Local and Remote Weights")
            
            ArchiveTextField(placeholder: "Search HuggingFace hubs...", text: $searchQuery)
                .padding(.horizontal)
            
            List {
                ForEach(repoVM.models.filter { searchQuery.isEmpty || $0.name.localizedCaseInsensitiveContains(searchQuery) }) { model in
                    RepositoryRow(model: model)
                        .listRowBackground(ArchiveColors.cardBackground)
                        .listRowSeparatorTint(ArchiveColors.border)
                }
            }
            .listStyle(.plain)
        }
    }
}

struct RepositoryRow: View {
    let model: AIModel
    @EnvironmentObject var repoVM: RepositoryViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(ArchiveTypography.courier(size: 11))
                    .fontWeight(.bold)
                    .foregroundColor(ArchiveColors.text)
                
                Text(model.description)
                    .font(ArchiveTypography.courier(size: 8.5))
                    .foregroundColor(ArchiveColors.textMuted)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if model.isInstalled {
                Image(systemName: ArchiveIcons.check)
                    .foregroundColor(ArchiveColors.green)
            } else {
                Button(action: { repoVM.downloadModel(model) }) {
                    Image(systemName: ArchiveIcons.download)
                        .foregroundColor(ArchiveColors.bronze)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
`
  },
  {
    name: "ArchiveView.swift",
    path: "Views/ArchiveView.swift",
    category: "Views",
    language: "swift",
    description: "Recovery catalog showing historically saved images, local cache size, and export options.",
    code: `import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject var archiveVM: ArchiveViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            ArchiveHeader(title: "Recovered Artifacts", subtitle: "Visual Archives Store")
            
            if archiveVM.artifacts.isEmpty {
                VStack(spacing: 8) {
                    Text("NO RECOVERED PLATES RECORDED")
                        .font(ArchiveTypography.courier(size: 11))
                        .foregroundColor(ArchiveColors.textMuted)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 16) {
                        ForEach(archiveVM.artifacts) { artifact in
                            ArtifactCell(artifact: artifact)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct ArtifactCell: View {
    let artifact: Artifact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Color.black // Mock Image
                .frame(height: 140)
                .cornerRadius(4)
                .overlay(
                    Text("Artifact")
                        .font(ArchiveTypography.courier(size: 9))
                        .foregroundColor(ArchiveColors.textMuted)
                )
            
            Text(artifact.prompt)
                .font(ArchiveTypography.courier(size: 8))
                .foregroundColor(ArchiveColors.text)
                .lineLimit(1)
        }
        .padding(8)
        .background(ArchiveColors.cardBackground)
        .border(ArchiveColors.border, width: 1)
    }
}
`
  },
  {
    name: "ImageDetailView.swift",
    path: "Views/ImageDetailView.swift",
    category: "Views",
    language: "swift",
    description: "Detailed inspector rendering pixel data side-by-side with denoising metadata.",
    code: `import SwiftUI

struct ImageDetailView: View {
    let artifact: Artifact
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ArchiveHeader(title: "Plate Inspector", subtitle: "Detail Evaluation")
                
                Color.black // Mock image viewport
                    .frame(height: 280)
                    .border(ArchiveColors.border, width: 1)
                
                ArchiveCard(title: "Diffusion Metrics", subtitle: "Engine Logs") {
                    VStack(alignment: .leading, spacing: 8) {
                        MetricRow(label: "Sourcing Seed", value: "\\(artifact.seed)")
                        MetricRow(label: "Model Sourced", value: artifact.modelId)
                        MetricRow(label: "Hardware Engine", value: artifact.engine)
                        MetricRow(label: "Latency Recorded", value: String(format: "%.3f s", artifact.latencySeconds))
                    }
                }
            }
            .padding()
        }
        .background(ArchiveColors.background.edgesIgnoringSafeArea(.all))
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label.uppercased())
                .font(ArchiveTypography.courier(size: 8.5))
                .foregroundColor(ArchiveColors.textMuted)
            Spacer()
            Text(value)
                .font(ArchiveTypography.courier(size: 9))
                .foregroundColor(ArchiveColors.text)
        }
    }
}
`
  },
  {
    name: "SettingsView.swift",
    path: "Views/SettingsView.swift",
    category: "Views",
    language: "swift",
    description: "Option configurations including offload switches, RAM throttling settings, and clear caches.",
    code: `import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ArchiveHeader(title: "Hardware Settings", subtitle: "Memory Throttling Rules")
                
                ArchiveCard(title: "Processing Directives", subtitle: "Offload Rules") {
                    VStack(spacing: 12) {
                        Toggle(isOn: $settingsVM.useMetalGPU) {
                            Text("FORCE METAL GPU INSTEAD OF ANE")
                                .font(ArchiveTypography.courier(size: 9.5))
                                .foregroundColor(ArchiveColors.text)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: ArchiveColors.bronze))
                        
                        Toggle(isOn: $settingsVM.lowMemoryMode) {
                            Text("ENABLED 8GB LOW-MEMORY RAM OPT")
                                .font(ArchiveTypography.courier(size: 9.5))
                                .foregroundColor(ArchiveColors.text)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: ArchiveColors.bronze))
                    }
                }
                
                ArchiveCard(title: "System Housekeeping", subtitle: "Cache Flush") {
                    VStack(spacing: 8) {
                        ArchiveButton(title: "Clear Compiled CoreML Caches") {
                            settingsVM.clearCache()
                        }
                    }
                }
            }
            .padding()
        }
    }
}
`
  },

  // --- Models ---
  {
    name: "AIModel.swift",
    path: "Models/AIModel.swift",
    category: "Models",
    language: "swift",
    description: "Definition model storing metadata, formats, licenses, and local sandbox directory flags.",
    code: `import Foundation

public struct AIModel: Identifiable, Codable {
    public let id: String
    public let name: String
    public let author: String
    public let description: String
    public let fileSizeBytes: Int64
    public var format: ModelFormat
    public var isInstalled: Bool
    
    public enum ModelFormat: String, Codable {
        case coreML = "CoreML"
        case mlx = "MLX"
        case gguf = "GGUF"
    }
}
`
  },
  {
    name: "Artifact.swift",
    path: "Models/Artifact.swift",
    category: "Models",
    language: "swift",
    description: "Saved image schema holding file location, dimensions, latency, and noise parameters.",
    code: `import Foundation

public struct Artifact: Identifiable, Codable {
    public let id: String
    public let imageUrl: String
    public let prompt: String
    public let seed: UInt64
    public let modelId: String
    public let engine: String
    public let latencySeconds: Double
    public let timestamp: Date
}
`
  },
  {
    name: "DownloadTask.swift",
    path: "Models/DownloadTask.swift",
    category: "Models",
    language: "swift",
    description: "Tracking model containing bytes transferred, total sizes, Speed rates, and URLSession references.",
    code: `import Foundation

public struct DownloadTask: Identifiable {
    public let id: String
    public let modelId: String
    public var progress: Double
    public var bytesTransferred: Int64
    public var bytesTotal: Int64
    public var status: Status
    
    public enum Status {
        case pending
        case downloading
        case paused
        case completed
        case failed(Error)
    }
}
`
  },
  {
    name: "PromptPreset.swift",
    path: "Models/PromptPreset.swift",
    category: "Models",
    language: "swift",
    description: "Schema saving prompt structures, weight parameters, and predefined styling.",
    code: `import Foundation

public struct PromptPreset: Identifiable, Codable {
    public let id: String
    public let title: String
    public let promptText: String
    public let negativePrompt: String
    public let steps: Int
}
`
  },

  // --- ViewModels ---
  {
    name: "HomeViewModel.swift",
    path: "ViewModels/HomeViewModel.swift",
    category: "ViewModels",
    language: "swift",
    description: "Home view coordinator streaming generation phases, step counts, and active metal logs.",
    code: `import SwiftUI

public final class HomeViewModel: ObservableObject {
    @Published public var isGenerating = false
    @Published public var generationProgress = 0
    @Published public var logs: [String] = []
    
    public init() {}
    
    public func triggerGeneration(prompt: String) async throws {
        await MainActor.run {
            self.isGenerating = true
            self.generationProgress = 0
            self.logs = ["[Core] Dispatching generative threads..."]
        }
        
        for step in 1...20 {
            try await Task.sleep(nanoseconds: 120_000_000)
            await MainActor.run {
                self.generationProgress = Int((Double(step) / 20.0) * 100)
                self.logs.append("[ANE Step \\(step)/20] Completed math execution.")
            }
        }
        
        await MainActor.run {
            self.isGenerating = false
            self.logs.append("[Success] Artifact saved.")
        }
    }
}
`
  },
  {
    name: "RepositoryViewModel.swift",
    path: "ViewModels/RepositoryViewModel.swift",
    category: "ViewModels",
    language: "swift",
    description: "Sourcing coordinator querying HF hub interfaces, filtering lists, and queuing downloads.",
    code: `import SwiftUI

public final class RepositoryViewModel: ObservableObject {
    @Published public var models: [AIModel] = []
    
    public init() {
        self.models = [
            AIModel(id: "flux-1-schnell", name: "Flux.1 Schnell", author: "BlackForest", description: "Fast local core", fileSizeBytes: 1600000000, format: .coreML, isInstalled: true),
            AIModel(id: "sdxl-turbo", name: "SDXL-Turbo (MLX)", author: "Stability", description: "GPU native real-time", fileSizeBytes: 3200000000, format: .mlx, isInstalled: false)
        ]
    }
    
    public func downloadModel(_ model: AIModel) {
        print("Enqueuing download task for: \\(model.name)")
    }
}
`
  },
  {
    name: "ArchiveViewModel.swift",
    path: "ViewModels/ArchiveViewModel.swift",
    category: "ViewModels",
    language: "swift",
    description: "Database coordinator tracking saved recoveries, managing local image files.",
    code: `import SwiftUI

public final class ArchiveViewModel: ObservableObject {
    @Published public var artifacts: [Artifact] = []
    
    public init() {
        self.artifacts = [
            Artifact(id: "art-1", imageUrl: "", prompt: "Historical photo of traditional weavers", seed: 48912, modelId: "sdxl-turbo", engine: "CoreML", latencySeconds: 1.25, timestamp: Date())
        ]
    }
}
`
  },
  {
    name: "SettingsViewModel.swift",
    path: "ViewModels/SettingsViewModel.swift",
    category: "ViewModels",
    language: "swift",
    description: "Coordinator binding user configuration presets to native standard UserDefaults storage.",
    code: `import SwiftUI

public final class SettingsViewModel: ObservableObject {
    @Published public var useMetalGPU = false
    @Published public var lowMemoryMode = true
    
    public init() {}
    
    public func clearCache() {
        print("Resetting local compilation registers.")
    }
}
`
  },

  // --- Services ---
  {
    name: "ImageGenerationService.swift",
    path: "Services/ImageGenerationService.swift",
    category: "Services",
    language: "swift",
    description: "Inference router targeting the CoreML, MLX, or GGUF engine depending on model properties.",
    code: `import Foundation

public final class ImageGenerationService {
    private let coreMLEngine = CoreMLInferenceEngine()
    private let mlxEngine = MLXInferenceEngine()
    private let ggufEngine = GGUFLlamaInference()
    
    public func generate(model: AIModel, prompt: String, steps: Int, seed: UInt64) async throws -> CGImage {
        switch model.format {
        case .coreML:
            return try await coreMLEngine.generateImage(prompt: prompt, negativePrompt: "", steps: steps, size: CGSize(width: 512, height: 512), seed: UInt32(seed)) { _, _ in }
        case .mlx:
            return try await mlxEngine.generateImageMLX(prompt: prompt, steps: steps, size: CGSize(width: 512, height: 512), seed: seed)
        case .gguf:
            return try await ggufEngine.generateImageGGUF(prompt: prompt, steps: steps, seed: Int32(seed))
        }
    }
}
`
  },
  {
    name: "HuggingFaceService.swift",
    path: "Services/HuggingFaceService.swift",
    category: "Services",
    language: "swift",
    description: "Direct HF Client implementation querying the Hub APIs to parse model parameters.",
    code: `import Foundation

public final class HuggingFaceService {
    private let session = URLSession.shared
    
    public func searchModels(query: String) async throws -> [AIModel] {
        let endpoint = "https://huggingface.co/api/models?search=\\(query)&filter=text-to-image"
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        let (data, _) = try await session.data(from: url)
        // Parse HF results dynamically
        return []
    }
}
`
  },
  {
    name: "ModelManager.swift",
    path: "Services/ModelManager.swift",
    category: "Services",
    language: "swift",
    description: "Sandbox directories locator, confirming the existence of weights and cleaning corrupted compilations.",
    code: `import Foundation

public final class ModelManager {
    public static let shared = ModelManager()
    
    private let fileManager = FileManager.default
    
    public func getLocalModelURL(id: String) -> URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("LocalModels/\\(id)")
    }
    
    public func checkModelExists(id: String) -> Bool {
        let url = getLocalModelURL(id: id)
        return fileManager.fileExists(atPath: url.path)
    }
}
`
  },
  {
    name: "DownloadManager.swift",
    path: "Services/DownloadManager.swift",
    category: "Services",
    language: "swift",
    description: "URLSessionDownloadDelegate wrapping multithreaded network requests with live state updates.",
    code: `import Foundation

public final class DownloadManager: NSObject, URLSessionDownloadDelegate {
    public static let shared = DownloadManager()
    
    private var session: URLSession!
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.theblackarchives.downloads")
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    public func startDownload(url: URL) {
        let task = session.downloadTask(with: url)
        task.resume()
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Completed background file transfer to: \\(location)")
    }
}
`
  },
  {
    name: "StorageManager.swift",
    path: "Services/StorageManager.swift",
    category: "Services",
    language: "swift",
    description: "Local sqlite/json archive writer maintaining history indexes.",
    code: `import Foundation

public final class StorageManager {
    public static let shared = StorageManager()
    
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    
    public func saveHistory(_ artifacts: [Artifact]) {
        if let data = try? jsonEncoder.encode(artifacts) {
            UserDefaults.standard.set(data, forKey: "artifacts_index")
        }
    }
    
    public func loadHistory() -> [Artifact] {
        guard let data = UserDefaults.standard.data(forKey: "artifacts_index") else { return [] }
        return (try? jsonDecoder.decode([Artifact].self, from: data)) ?? []
    }
}
`
  },

  // --- Utilities ---
  {
    name: "Constants.swift",
    path: "Utilities/Constants.swift",
    category: "Utilities",
    language: "swift",
    description: "Centralized static paths, default HuggingFace links, and application build metadata.",
    code: `import Foundation

public enum Constants {
    public static let hfApiBase = "https://huggingface.co/api"
    public static let defaultNegativePrompt = "deformed, distorted, watermark, signature, blurry, low resolution, noise"
    public static let compileCachePath = "Library/Caches/com.apple.metal"
}
`
  },
  {
    name: "Extensions.swift",
    path: "Utilities/Extensions.swift",
    category: "Utilities",
    language: "swift",
    description: "Convenient SwiftUI View borders, color conversions, and thread helper functions.",
    code: `import SwiftUI

extension View {
    func border(width: CGFloat, edge: Edge, color: Color) -> some View {
        modifier(EdgeBorder(width: width, edge: edge, color: color))
    }
}

struct EdgeBorder: ViewModifier {
    var width: CGFloat
    var edge: Edge
    var color: Color
    
    func body(content: Content) -> some View {
        content.overlay(
            GeometryReader { geo in
                self.makeBorder(size: geo.size)
            }
        )
    }
    
    private func makeBorder(size: CGSize) -> some View {
        let x: CGFloat = 0
        let y: CGFloat = 0
        let w: CGFloat = size.width
        let h: CGFloat = size.height
        
        return Rectangle()
            .fill(color)
            .frame(
                width: (edge == .leading || edge == .trailing) ? width : w,
                height: (edge == .top || edge == .bottom) ? width : h
            )
            .offset(x: edge == .trailing ? w - width : x, y: edge == .bottom ? h - width : y)
    }
}
`
  },
  {
    name: "Logger.swift",
    path: "Utilities/Logger.swift",
    category: "Utilities",
    language: "swift",
    description: "Unified print router routing messages to OSLog channels for easier debugging.",
    code: `import Foundation
import OSLog

public enum Logger {
    private static let logger = os.Logger(subsystem: "com.theblackarchives.app", category: "CoreSystem")
    
    public static func info(_ msg: String) {
        logger.info("\\(msg)")
        print("[INFO] \\(msg)")
    }
    
    public static func error(_ msg: String) {
        logger.error("\\(msg)")
        print("[ERROR] \\(msg)")
    }
}
`
  },

  // --- Resources ---
  {
    name: "Contents.json",
    path: "Resources/Assets.xcassets/Contents.json",
    category: "Resources",
    language: "json",
    description: "Xcode folder structure asset catalog file.",
    code: `{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
`
  },
  {
    name: "Contents.json",
    path: "Resources/Assets.xcassets/AppIcon.appiconset/Contents.json",
    category: "Resources",
    language: "json",
    description: "AppIcon configuration defining the size metadata mappings for iPhone and App Store marketing.",
    code: `{
  "images" : [
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "icon_20pt_iphone@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "icon_20pt_iphone@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "icon_29pt_iphone@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "icon_29pt_iphone@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "icon_40pt_iphone@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "icon_40pt_iphone@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "icon_60pt_iphone@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "icon_60pt_iphone@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "1024x1024",
      "idiom" : "ios-marketing",
      "filename" : "icon_1024_marketing.png",
      "scale" : "1x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
`
  },
  {
    name: "AppIcon_Readme.md",
    path: "Resources/Assets.xcassets/AppIcon.appiconset/AppIcon_Readme.md",
    category: "Resources",
    language: "markdown",
    description: "Design specs, transparency constraints, and asset guidelines for generating the brutalist app icon.",
    code: `# The Black Archives: App Icon Design Guidelines

This document outlines the asset requirements for the app icon of **The Black Archives** local generative application.

## Design Aesthetic
- **Background**: Deep charcoal black (\`#0F1012\`) to match the terminal look.
- **Glyph**: A high-contrast central circular camera lens or digital storage cylinder matrix overlay in warm bronze (\`#8A6B3D\`) combined with gold accents (\`#C5A880\`).
- **Typography**: The initials "BA" centered in small elegant "Cinzel" serif letterforms.

## Icon Asset Specifications
You must place PNG images of corresponding dimensions matching the \`Contents.json\` file:

| Filename | Dimensions | Target Pt Size | Scale |
| :--- | :--- | :--- | :--- |
| \`icon_20pt_iphone@2x.png\` | 40 x 40 px | 20 pt | @2x |
| \`icon_20pt_iphone@3x.png\` | 60 x 60 px | 20 pt | @3x |
| \`icon_29pt_iphone@2x.png\` | 58 x 58 px | 29 pt | @2x |
| \`icon_29pt_iphone@3x.png\` | 87 x 87 px | 29 pt | @3x |
| \`icon_40pt_iphone@2x.png\` | 80 x 80 px | 40 pt | @2x |
| \`icon_40pt_iphone@3x.png\` | 120 x 120 px | 40 pt | @3x |
| \`icon_60pt_iphone@2x.png\` | 120 x 120 px | 60 pt | @2x |
| \`icon_60pt_iphone@3x.png\` | 180 x 180 px | 60 pt | @3x |
| \`icon_1024_marketing.png\` | 1024 x 1024 px | 1024 pt | @1x |

## Rules for Assets Compilation
1. **No Alpha Channel**: Ensure that the \`icon_1024_marketing.png\` does not contain any transparent alpha channel pixels, as the App Store compiler will reject the package.
2. **Squircle Clipping**: Keep critical design visual parts safe inside a 10% safety margin margin border, as Apple wraps all icons with its standard squircle mask.
`
  },
  {
    name: "ArchiveFonts.txt",
    path: "Resources/Fonts/ArchiveFonts.txt",
    category: "Resources",
    language: "markdown",
    description: "Guideline instructions for linking custom premium fonts 'Cinzel', 'Inter' and 'Courier Prime' inside Info.plist.",
    code: `# Custom Fonts Setup Guide

To load these fonts into your Xcode project:

1. Drag-and-drop your \`.ttf\` or \`.otf\` font files into the **Resources/Fonts/** folder in Xcode.
2. Ensure you check **"Add to targets"** for your main build target.
3. Open your **Info.plist** file.
4. Add the key **"Fonts provided by application"** (or \`UIAppFonts\`) as an array.
5. Add the filenames exactly as they are on disk:
   - \`Cinzel-Regular.ttf\`
   - \`Inter-Regular.ttf\`
   - \`CourierPrime-Regular.ttf\`
6. Verify your build phases bundle copies the resource fonts appropriately.
`
  }
];

// Re-export old file references for safety or legacy bridges
export const COREML_SWIFT_INFERENCE_ENGINE_MOCK = SWIFT_SOURCE_FILES[0].code;
export const COREML_SWIFT_DOWNLOADER_MOCK = SWIFT_SOURCE_FILES[16].code;
export const COREML_SWIFT_REPOS_VM_MOCK = SWIFT_SOURCE_FILES[12].code;
export const COREML_SWIFT_HOME_VIEW_MOCK = SWIFT_SOURCE_FILES[9].code;
export const COREML_SWIFT_ONBOARDING_MOCK = SWIFT_SOURCE_FILES[8].code;
