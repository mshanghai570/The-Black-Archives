import React, { useState, useEffect } from "react";
import { 
  Cpu, Code, Sparkles, HardDrive, BookOpen, AlertCircle, RefreshCw, Eye, Save, Share2, Star, ExternalLink 
} from "lucide-react";
import PhoneSimulator from "./components/PhoneSimulator";
import CodeWorkspace from "./components/CodeWorkspace";
import TechSpecs from "./components/TechSpecs";
import { InstalledModel, GeneratedImage } from "./types";

export default function App() {
  // Developer Workspace Tab: "code" | "specs"
  const [activeWorkspaceTab, setActiveWorkspaceTab] = useState<"code" | "specs">("code");

  // Local device state for the Simulator, matching "The Black Archives"
  const [installedModels, setInstalledModels] = useState<InstalledModel[]>([
    {
      id: "flux-schnell-coreml",
      name: "Flux.1 Dev (CoreML-INT8)",
      author: "black-forest-labs",
      fileSize: "2.3 GB",
      installedPath: "sandboxed://LocalModels/flux-schnell-coreml.mlmodelc",
      dateInstalled: "2026-07-16",
      isFavorite: true,
      format: "Flux",
      capabilities: ["Text-to-Image"]
    },
    {
      id: "sdxl-turbo-ane",
      name: "SDXL-Turbo (CoreML-FP16)",
      author: "stabilityai",
      fileSize: "3.1 GB",
      installedPath: "sandboxed://LocalModels/sdxl-turbo-ane.mlmodelc",
      dateInstalled: "2026-07-10",
      isFavorite: false,
      format: "StableDiffusion",
      capabilities: ["Text-to-Image"]
    }
  ]);

  const [activeModelId, setActiveModelId] = useState<string>("flux-schnell-coreml");

  const [generatedImages, setGeneratedImages] = useState<GeneratedImage[]>([
    {
      id: "pre-1",
      imageUrl: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop&q=80",
      prompt: "A faded silver halide photograph of an ancient stone vault with mechanical brass lock mechanisms, dusty light beams breaking through a rusted iron grate, soft museum archive presentation, vintage analog feel.",
      negativePrompt: "neon, high contrast, text, digital render, 3d, cyberpunk, low quality",
      width: 1024,
      height: 1024,
      seed: 849204,
      modelId: "flux-schnell-coreml",
      modelName: "Flux.1 Dev",
      timestamp: "July 17",
      latencySeconds: 2.34,
      peakMemoryMB: 4850,
      isFavorite: true,
      engine: "CoreML [Local Archive]"
    },
    {
      id: "pre-2",
      imageUrl: "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=800&auto=format&fit=crop&q=80",
      prompt: "An analog close-up photograph of complex copper-bound gearwork resting on velvet, classified technical notation code #481-9A, soft natural lighting from above, mysterious undercroft setting.",
      negativePrompt: "drawing, painting, cartoon, 3d render, anime, saturated colors, neon, signature",
      width: 1024,
      height: 1024,
      seed: 481029,
      modelId: "sdxl-turbo-ane",
      modelName: "SDXL-Turbo",
      timestamp: "July 16",
      latencySeconds: 1.15,
      peakMemoryMB: 3120,
      isFavorite: false,
      engine: "CoreML [Local Archive]"
    }
  ]);

  const handleImageGenerated = (newImage: GeneratedImage) => {
    console.log("New visual record recovered in terminal session:", newImage);
  };

  return (
    <div className="min-h-screen bg-archive-bg text-archive-text flex flex-col font-sans selection:bg-archive-bronze/30 selection:text-archive-text paper-grain">
      
      {/* Premium Header styled like a Classified File Label */}
      <header className="bg-archive-card border-b border-archive-border px-6 py-5 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
          
          <div className="flex items-center gap-3.5 text-left">
            <div className="bg-[#202428] p-3 rounded-lg border border-archive-border flex items-center justify-center">
              <Cpu className="w-5 h-5 text-archive-bronze animate-pulse" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-[8px] font-mono tracking-widest text-archive-bronze uppercase block">PROJECT CORE</span>
              </div>
              <h1 className="text-xl font-serif font-semibold tracking-wider text-archive-text">THE BLACK ARCHIVES</h1>
              <p className="text-xs font-mono text-archive-text-muted mt-0.5">Recovered Knowledge & Local On-Device Inference Hub</p>
            </div>
          </div>

          {/* Quick Core/VRAM Statistics in classic analog terminal layout */}
          <div className="flex gap-6 items-center">
            <div className="text-right hidden md:block border-r border-archive-border pr-6">
              <span className="text-[8px] text-archive-text-muted font-mono uppercase tracking-widest block">SECURE RAM COMMITTED</span>
              <span className="text-xs font-mono font-bold text-archive-bronze">
                {(installedModels.length * 1.5 + 1.2).toFixed(1)} GB / 8.0 GB
              </span>
            </div>
            <div className="text-right">
              <span className="text-[8px] text-archive-text-muted font-mono uppercase tracking-widest block">RECOVERED RECORDINGS</span>
              <span className="text-xs font-mono font-bold text-archive-bronze">
                {generatedImages.length} visual files
              </span>
            </div>
          </div>

        </div>
      </header>

      {/* Primary Workspace Layout */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-4 sm:p-6 lg:p-8 flex flex-col lg:flex-row gap-8 items-stretch min-h-0">
        
        {/* Left Column: Interactive Mobile App Prototype */}
        <div className="lg:w-[380px] flex-shrink-0 flex flex-col items-center justify-center bg-archive-card/25 border border-archive-border rounded-2xl p-6 relative overflow-hidden">
          
          <div className="mb-4 text-center">
            <span className="text-[9px] font-mono tracking-widest text-archive-bronze border border-archive-border bg-[#181A1D] px-3.5 py-1 rounded uppercase">
              INTERACTIVE ARCHIVE CLIENT
            </span>
          </div>

          <PhoneSimulator 
            onImageGenerated={handleImageGenerated}
            installedModels={installedModels}
            setInstalledModels={setInstalledModels}
            activeModelId={activeModelId}
            setActiveModelId={setActiveModelId}
            generatedImages={generatedImages}
            setGeneratedImages={setGeneratedImages}
          />
          
          <p className="text-[10px] text-archive-text-muted text-center mt-4 max-w-[280px] leading-relaxed font-sans">
            Fully interactive simulator. Use the <strong className="text-archive-text font-mono">Repository</strong> to download new model weights, adjust prompt parameters in <strong className="text-archive-text font-mono">Transmit</strong>, and inspect results in <strong className="text-archive-text font-mono">Archive</strong>.
          </p>
        </div>

        {/* Right Column: Codebase Hub & CoreML Spec sheets */}
        <div className="flex-1 flex flex-col min-w-0 bg-archive-card/20 border border-archive-border rounded-2xl p-4 sm:p-6">
          
          {/* Understated Workspace Tabs */}
          <div className="flex items-center justify-between pb-4 border-b border-archive-border mb-6">
            <div className="flex bg-[#0F1012] p-1 rounded border border-archive-border">
              <button
                onClick={() => setActiveWorkspaceTab("code")}
                className={`text-xs px-4 py-2 rounded font-mono font-bold flex items-center gap-2 transition-all border ${
                  activeWorkspaceTab === "code"
                    ? "bg-[#181A1D] border-archive-border text-archive-text"
                    : "text-archive-text-muted hover:text-archive-text border-transparent button-depress"
                }`}
              >
                <Code className="w-3.5 h-3.5 text-archive-bronze" /> Xcode Code Hub
              </button>
              <button
                onClick={() => setActiveWorkspaceTab("specs")}
                className={`text-xs px-4 py-2 rounded font-mono font-bold flex items-center gap-2 transition-all border ${
                  activeWorkspaceTab === "specs"
                    ? "bg-[#181A1D] border-archive-border text-archive-text"
                    : "text-archive-text-muted hover:text-archive-text border-transparent button-depress"
                }`}
              >
                <BookOpen className="w-3.5 h-3.5 text-archive-bronze" /> CoreML Spec Sheet
              </button>
            </div>

            <div className="hidden sm:flex items-center gap-1.5 text-[10px] font-mono text-[#5C7A67] font-bold">
              <span className="w-1.5 h-1.5 rounded-full bg-[#5C7A67] animate-pulse"></span> TERMINAL CONNECTED
            </div>
          </div>

          {/* Dynamic Content Panel */}
          <div className="flex-1 flex flex-col min-h-0">
            {activeWorkspaceTab === "code" ? (
              <CodeWorkspace />
            ) : (
              <div className="overflow-y-auto flex-1 custom-scrollbar">
                <TechSpecs />
              </div>
            )}
          </div>

        </div>

      </main>

      {/* Classic Vintage Footer */}
      <footer className="bg-archive-card border-t border-archive-border py-6 px-6 mt-auto">
        <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4 text-[10px] text-archive-text-muted font-mono">
          <div className="flex items-center gap-1.5 text-left">
            <span>THE BLACK ARCHIVES</span>
            <span>•</span>
            <span>Recovered Knowledge Terminal v1.0.0</span>
            <span>•</span>
            <span className="text-archive-bronze">Classified Framework</span>
          </div>
          <div className="flex items-center gap-4">
            <span className="hover:text-archive-text cursor-pointer">Isolated Sandbox Certified</span>
            <span className="hover:text-archive-text cursor-pointer flex items-center gap-1 text-archive-bronze">
              Apple Silicon Neural Engine Optimized <ExternalLink className="w-3 h-3 text-archive-bronze-muted" />
            </span>
          </div>
        </div>
      </footer>

    </div>
  );
}
