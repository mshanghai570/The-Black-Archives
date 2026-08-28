import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var archiveVM: ArchiveViewModel
    @Binding var activeTab: Int
    @State private var showClearConfirm = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    ArchiveHeader(title: "Hardware Settings", subtitle: "Memory Throttling Rules")
                    Spacer()
                    Button(action: { 
                        HapticFeedback.light.trigger()
                        activeTab = 0 
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(ArchiveColors.bronze)
                    }
                }
                
                ArchiveCard(title: "Processing Directives", subtitle: "Offload Rules") {
                    VStack(spacing: 12) {
                        HStack {
                            Toggle(isOn: $settingsVM.useMetalGPU) {
                                Text("FORCE METAL GPU INSTEAD OF ANE")
                                    .font(ArchiveTypography.courier(size: 9.5))
                                    .foregroundColor(ArchiveColors.text)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: ArchiveColors.bronze))
                            .onChange(of: settingsVM.useMetalGPU) { oldValue, newValue in
                                HapticFeedback.selectionChanged()
                            }
                            
                            InfoTooltip(text: "Uses Apple Metal framework for GPU acceleration instead of Neural Engine for faster computation")
                        }
                        
                        HStack {
                            Toggle(isOn: $settingsVM.lowMemoryMode) {
                                Text("ENABLED 8GB LOW-MEMORY RAM OPT")
                                    .font(ArchiveTypography.courier(size: 9.5))
                                    .foregroundColor(ArchiveColors.text)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: ArchiveColors.bronze))
                            .onChange(of: settingsVM.lowMemoryMode) { oldValue, newValue in
                                HapticFeedback.selectionChanged()
                            }
                            
                            InfoTooltip(text: "Reduces memory usage for devices with limited RAM, may impact performance")
                        }
                    }
                }
                
                ArchiveCard(title: "System Housekeeping", subtitle: "Cache Flush") {
                    VStack(spacing: 8) {
                        ArchiveButton(title: "Clear Compiled CoreML Caches") {
                            settingsVM.clearCache()
                        }
                    }
                }
                
                ArchiveCard(title: "Archive Management") {
                    VStack(spacing: 10) {
                        HStack {
                            Text("Saved artifacts")
                                .font(ArchiveTypography.courier(size: 9.5))
                                .foregroundColor(ArchiveColors.textMuted)
                            Spacer()
                            Text("\(archiveVM.artifacts.count)")
                                .font(ArchiveTypography.courier(size: 10))
                                .foregroundColor(ArchiveColors.bronze)
                                .fontWeight(.bold)
                        }
                        
                        ArchiveButton(title: "Clear All Artifacts", icon: "trash") {
                            showClearConfirm = true
                        }
                    }
                }
                
                ArchiveCard(title: "About") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("THE BLACK ARCHIVES")
                            .font(ArchiveTypography.cinzel(size: 10))
                            .foregroundColor(ArchiveColors.bronze)
                        Text("Secure Local Generative Framework")
                            .font(ArchiveTypography.courier(size: 8.5))
                            .foregroundColor(ArchiveColors.textMuted)
                        Text("Models run entirely on-device via CoreML. No data leaves your device.")
                            .font(ArchiveTypography.courier(size: 8.5))
                            .foregroundColor(ArchiveColors.textMuted)
                    }
                }
            }
            .padding()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.width > 100 {
                        HapticFeedback.light.trigger()
                        activeTab = 0
                    }
                }
        )
        .alert("Clear All Artifacts", isPresented: $showClearConfirm) {
            Button("Clear All", role: .destructive) {
                HapticFeedback.heavy.trigger()
                archiveVM.clearAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all generated images and metadata.")
        }
    }
}
