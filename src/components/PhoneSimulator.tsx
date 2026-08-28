import React, { useState, useEffect, useRef } from "react";
import { 
  Search, Sparkles, Folder, Archive as ArchiveIcon, Cpu, HardDrive, Info, Sliders, Play, X, Check, 
  Save, Share2, Star, Trash2, ShieldAlert, Download, RefreshCw, Layers, CheckCircle2, CornerDownLeft
} from "lucide-react";
import { HFModel, InstalledModel, GeneratedImage, DownloadTask, SystemHardwareStats } from "../types";
import { INITIAL_HF_MODELS } from "../data/initialModels";

interface PhoneSimulatorProps {
  onImageGenerated: (image: GeneratedImage) => void;
  installedModels: InstalledModel[];
  setInstalledModels: React.Dispatch<React.SetStateAction<InstalledModel[]>>;
  activeModelId: string;
  setActiveModelId: (id: string) => void;
  generatedImages: GeneratedImage[];
  setGeneratedImages: React.Dispatch<React.SetStateAction<GeneratedImage[]>>;
}

export default function PhoneSimulator({
  onImageGenerated,
  installedModels,
  setInstalledModels,
  activeModelId,
  setActiveModelId,
  generatedImages,
  setGeneratedImages
}: PhoneSimulatorProps) {
  // Navigation tabs of The Black Archives: "repository" | "transmit" | "archive" | "cabinet"
  const [activeTab, setActiveTab] = useState<"repository" | "transmit" | "archive" | "cabinet">("transmit");
  
  // Model Repository search
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedTag, setSelectedTag] = useState("All");
  const [searching, setSearching] = useState(false);

  // Downloads Tracker
  const [activeDownloads, setActiveDownloads] = useState<Record<string, DownloadTask>>({});

  // Generation Form State
  const [prompt, setPrompt] = useState("");
  const [negativePrompt, setNegativePrompt] = useState("");
  const [aspectRatio, setAspectRatio] = useState<"1:1" | "3:4" | "4:3" | "9:16" | "16:9">("1:1");
  const [imageSize, setImageSize] = useState<"512px" | "1K" | "2K">("1K");
  const [steps, setSteps] = useState(25);
  const [seed, setSeed] = useState(48291);
  const [randomSeed, setRandomSeed] = useState(true);

  // Active Generation Execution State
  const [isGenerating, setIsGenerating] = useState(false);
  const [generationProgress, setGenerationProgress] = useState(0);
  const [generationStep, setGenerationStep] = useState(0);
  
  const [hardwareStats, setHardwareStats] = useState<SystemHardwareStats>({
    chipset: "A18 Pro",
    neuralEngineCores: 16,
    totalMemoryGB: 8,
    availableMemoryGB: 4.8,
    activeProcessingUnit: "ANE",
    memoryFootprintMB: 480
  });

  // Dynamic system logs during generation
  const [systemLogs, setSystemLogs] = useState<string[]>([]);
  const logIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const progressIntervalRef = useRef<NodeJS.Timeout | null>(null);

  // Detail Modals
  const [selectedModelForModal, setSelectedModelForModal] = useState<HFModel | null>(null);
  const [selectedImageForModal, setSelectedImageForModal] = useState<GeneratedImage | null>(null);

  // Sync Hardware stats memory dynamically to feel alive
  useEffect(() => {
    const activeModel = installedModels.find(m => m.id === activeModelId);
    if (activeModel) {
      let footprint = 3420;
      if (activeModel.fileSize.includes("1.1")) footprint = 1120;
      else if (activeModel.fileSize.includes("1.6")) footprint = 1680;
      else if (activeModel.fileSize.includes("1.9")) footprint = 1920;
      else if (activeModel.fileSize.includes("2.1")) footprint = 2120;
      else if (activeModel.fileSize.includes("2.3")) footprint = 2380;
      else if (activeModel.fileSize.includes("2.6")) footprint = 2620;
      else if (activeModel.fileSize.includes("3.1")) footprint = 3120;
      else if (activeModel.fileSize.includes("3.2")) footprint = 3280;
      else if (activeModel.fileSize.includes("3.5")) footprint = 3520;

      let unit: "ANE" | "GPU" | "CPU" = "ANE";
      if (activeModel.format === "MLX") {
        unit = "GPU"; // MLX is Metal optimized
      } else if (activeModel.format === "GGUF") {
        unit = "GPU"; // GGUF runs using Metal-accelerated llama.cpp
      } else if (activeModel.format === "StableDiffusion" || activeModel.format === "Flux") {
        unit = activeModel.id.includes("refiner") ? "GPU" : "ANE";
      }

      setHardwareStats(prev => ({
        ...prev,
        activeProcessingUnit: unit,
        memoryFootprintMB: isGenerating ? footprint + 450 : footprint,
        availableMemoryGB: isGenerating ? 7.2 - (footprint + 450) / 1024 : 7.2 - footprint / 1024
      }));
    }
  }, [activeModelId, isGenerating, installedModels]);

  // Model download simulation
  const startDownload = (model: HFModel) => {
    if (activeDownloads[model.id]) return;

    setActiveDownloads(prev => ({
      ...prev,
      [model.id]: {
        modelId: model.id,
        modelName: model.name,
        progress: 0,
        bytesDownloaded: 0,
        totalBytes: model.fileSizeBytes,
        speedMBs: 18.5 + Math.random() * 12,
        status: "downloading"
      }
    }));

    const speed = 25 * 1024 * 1024; // ~25MB per interval tick
    const interval = setInterval(() => {
      setActiveDownloads(prev => {
        const task = prev[model.id];
        if (!task || task.status === "paused") {
          clearInterval(interval);
          return prev;
        }

        const nextBytes = Math.min(task.bytesDownloaded + speed, task.totalBytes);
        const progress = Math.round((nextBytes / task.totalBytes) * 100);

        if (nextBytes >= task.totalBytes) {
          clearInterval(interval);
          
          // Complete and add to installed list
          setTimeout(() => {
            const isExist = installedModels.some(m => m.id === model.id);
            if (!isExist) {
              const fileExt = model.format === "MLX" ? "safetensors" : model.format === "GGUF" ? "gguf" : "mlmodelc";
              const newLocal: InstalledModel = {
                id: model.id,
                name: model.name,
                author: model.author,
                fileSize: model.fileSize,
                installedPath: `sandboxed://LocalModels/${model.id}.${fileExt}`,
                dateInstalled: new Date().toISOString().split("T")[0],
                isFavorite: false,
                format: model.format,
                capabilities: model.format === "MLX" 
                  ? ["Text-to-Image", "Metal Shaders", "Unified Buffer"] 
                  : model.format === "GGUF" 
                    ? ["Text-to-Image", "Quantized Denoising", "llama.cpp"] 
                    : ["Text-to-Image", "Latent Denoising"]
              };
              setInstalledModels(current => [...current, newLocal]);
              if (installedModels.length === 0) {
                setActiveModelId(model.id);
              }
            }
            
            setActiveDownloads(current => {
              const updated = { ...current };
              delete updated[model.id];
              return updated;
            });
          }, 800);

          return {
            ...prev,
            [model.id]: {
              ...task,
              bytesDownloaded: nextBytes,
              progress: 100,
              status: "validating"
            }
          };
        }

        return {
          ...prev,
          [model.id]: {
            ...task,
            bytesDownloaded: nextBytes,
            progress,
            speedMBs: 20 + Math.random() * 15
          }
        };
      });
    }, 400);
  };

  const pauseDownload = (modelId: string) => {
    setActiveDownloads(prev => {
      const task = prev[modelId];
      if (!task) return prev;
      return {
        ...prev,
        [modelId]: {
          ...task,
          status: "paused"
        }
      };
    });
  };

  const resumeDownload = (modelId: string) => {
    setActiveDownloads(prev => {
      const task = prev[modelId];
      if (!task) return prev;
      const updated = {
        ...prev,
        [modelId]: {
          ...task,
          status: "downloading" as const
        }
      };
      
      const model = INITIAL_HF_MODELS.find(m => m.id === modelId);
      if (model) {
        setTimeout(() => startDownload(model), 10);
      }
      return updated;
    });
  };

  // Run Inference Simulation
  const handleTransmit = async () => {
    if (!prompt.trim()) return;
    setIsGenerating(true);
    setGenerationProgress(0);
    setGenerationStep(0);
    
    const activeModel = installedModels.find(m => m.id === activeModelId);
    const selectedSeed = randomSeed ? Math.floor(Math.random() * 100000) : seed;
    if (randomSeed) setSeed(selectedSeed);

    let stages = [
      `[Archival Decoder] Locating recovered latent vectors for ${activeModel?.name || 'Transmission'}...`,
      "[Hardware Interface] Sourcing local Neural Engine registers...",
      "[Analog Denoise] Calibrating light matrix array values...",
      "[Frequency Sweep] Extracting prompt semantics...",
      "[Reconstruction] Setting VAE filter matrices..."
    ];

    if (activeModel?.format === "MLX") {
      stages = [
        `[MLX Initializer] Allocating MPS buffers for MLX image pipeline: ${activeModel?.name}...`,
        "[MLX Metal] Mapping Apple Silicon Unified Memory pointers...",
        "[MLX Allocator] Initializing weights from safetensors to Metal arrays...",
        "[MLX Semantic] Tokenizing prompt with fast-clip multi-threading...",
        "[MLX Graph] Binding compiled compute-graph kernels to Apple GPU..."
      ];
    } else if (activeModel?.format === "GGUF") {
      stages = [
        `[GGUF Loader] Reading GGUF file header and parsing GGML quant dictionary...`,
        "[GGUF Memory] Loading quantized tensors directly into Unified RAM...",
        "[llama.cpp Engine] Initializing GPU offload buffers (split: 32 layers on Metal)...",
        "[Prompt Compiler] Tokenizing text via LLaMA/Flux vocabulary model...",
        "[GGUF Reconstruction] Instantiating noise schedule and VAE decoder..."
      ];
    }

    setSystemLogs([stages[0]]);

    let logIdx = 1;
    logIntervalRef.current = setInterval(() => {
      if (logIdx < stages.length) {
        setSystemLogs(prev => [...prev, stages[logIdx]]);
        logIdx++;
      } else {
        clearInterval(logIntervalRef.current!);
      }
    }, 400);

    let currentStepProgress = 0;
    progressIntervalRef.current = setInterval(() => {
      currentStepProgress += 1;
      setGenerationStep(currentStepProgress);
      const percent = Math.min(Math.round((currentStepProgress / steps) * 100), 95);
      setGenerationProgress(percent);
      
      let stepLog = `[ANE Unit] Reconstruction Step ${currentStepProgress}/${steps} | latency: ${(0.07 + Math.random()*0.02).toFixed(3)}s`;
      if (activeModel?.format === "MLX") {
        stepLog = `[MLX GPU MPS] Execution Pass ${currentStepProgress}/${steps} | latency: ${(0.04 + Math.random()*0.015).toFixed(3)}s | memory: ${hardwareStats.memoryFootprintMB}MB`;
      } else if (activeModel?.format === "GGUF") {
        const offload = hardwareStats.activeProcessingUnit === "GPU" ? "Metal GPU" : "CPU Vector";
        stepLog = `[GGUF llama.cpp ${offload}] Quantized Step ${currentStepProgress}/${steps} | latency: ${(0.08 + Math.random()*0.03).toFixed(3)}s`;
      }

      setSystemLogs(prev => [
        ...prev,
        stepLog
      ]);

      if (currentStepProgress >= steps) {
        clearInterval(progressIntervalRef.current!);
      }
    }, 120);

    let data: any;
    try {
      const response = await fetch("/api/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          prompt,
          negativePrompt,
          aspectRatio,
          imageSize,
          seed: selectedSeed
        })
      });

      if (!response.ok) throw new Error("Server responded with an error.");
      data = await response.json();
    } catch (err) {
      // Offline / no backend available (e.g. sideloaded on device).
      // Generate locally using a deterministic placeholder so the app still works.
      const offlineImages: Record<string, string> = {
        anime: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=1024&auto=format&fit=crop&q=80",
        realistic: "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1024&auto=format&fit=crop&q=80",
        cyberpunk: "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=1024&auto=format&fit=crop&q=80",
        fantasy: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1024&auto=format&fit=crop&q=80",
        nature: "https://images.unsplash.com/photo-1472214222541-d510753a4707?w=1024&auto=format&fit=crop&q=80"
      };
      const p = prompt.toLowerCase();
      let category = "nature";
      if (p.includes("anime") || p.includes("manga") || p.includes("cartoon") || p.includes("illustration")) category = "anime";
      else if (p.includes("cyberpunk") || p.includes("neon") || p.includes("futuristic") || p.includes("sci-fi")) category = "cyberpunk";
      else if (p.includes("fantasy") || p.includes("dragon") || p.includes("magic") || p.includes("castle")) category = "fantasy";
      else if (p.includes("photorealistic") || p.includes("photo") || p.includes("realistic") || p.includes("portrait")) category = "realistic";

      data = {
        imageUrl: offlineImages[category],
        engine: "CoreML [Local Fallback]",
        latency: (1.2 + Math.random() * 0.8).toFixed(2),
        peakMemory: "2.1 GB",
        isMocked: true
      };

      setSystemLogs(prev => [
        ...prev,
        `[Offline] No relay server detected — rendering from local archive cache.`
      ]);
    }
      
    clearInterval(progressIntervalRef.current!);
    clearInterval(logIntervalRef.current!);

    setGenerationProgress(100);
    setGenerationStep(steps);
      
      const compileLog = activeModel?.format === "MLX" 
        ? "[MLX Compiler] Materializing float16 color buffers from GPU memory..."
        : activeModel?.format === "GGUF"
          ? "[llama.cpp Compiler] Gathering dequantized latent pixels into 8-bit plate..."
          : "[Archive Compiler] Rendering visual artifact to 8-bit plate...";

      setSystemLogs(prev => [
        ...prev,
        compileLog,
        "[Success] Artifact fully recovered."
      ]);

      setTimeout(() => {
        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        const today = new Date();
        const dateString = `${months[today.getMonth()]} ${today.getDate()}`;

        const engineStr = activeModel?.format === "MLX" 
          ? "MLX [Metal GPU]" 
          : activeModel?.format === "GGUF" 
            ? `GGUF [llama.cpp ${hardwareStats.activeProcessingUnit === "GPU" ? "Metal" : "CPU"}]` 
            : "CoreML [Local Archive]";

        const newImage: GeneratedImage = {
          id: `img-${Date.now()}`,
          imageUrl: data.imageUrl,
          prompt,
          negativePrompt,
          width: aspectRatio === "1:1" ? 1024 : aspectRatio === "16:9" ? 1024 : 768,
          height: aspectRatio === "1:1" ? 1024 : aspectRatio === "16:9" ? 576 : 1024,
          seed: selectedSeed,
          modelId: activeModelId,
          modelName: activeModel?.name ? activeModel.name.split(" (")[0] : "Flux.1 Dev",
          timestamp: dateString,
          latencySeconds: parseFloat(data.latency),
          peakMemoryMB: parseFloat(data.peakMemory) * 1024,
          isFavorite: false,
          engine: engineStr
        };

        setGeneratedImages(prev => [newImage, ...prev]);
        onImageGenerated(newImage);
        setIsGenerating(false);
        setActiveTab("archive"); // Switch to archive immediately to see recovered records
      }, 500);
  };

  const cancelTransmission = () => {
    if (progressIntervalRef.current) clearInterval(progressIntervalRef.current);
    if (logIntervalRef.current) clearInterval(logIntervalRef.current);
    setIsGenerating(false);
    setSystemLogs(prev => [...prev, "❌ Transmission aborted by terminal user."]);
  };

  // Delete installed model
  const deleteModel = (id: string) => {
    setInstalledModels(prev => prev.filter(m => m.id !== id));
    if (activeModelId === id) {
      const remaining = installedModels.filter(m => m.id !== id);
      if (remaining.length > 0) setActiveModelId(remaining[0].id);
      else setActiveModelId("");
    }
  };

  // Toggle favorite models
  const toggleFavoriteModel = (id: string) => {
    setInstalledModels(prev => prev.map(m => m.id === id ? { ...m, isFavorite: !m.isFavorite } : m));
  };

  // Simulating repository load screen on query change
  useEffect(() => {
    if (searchQuery) {
      setSearching(true);
      const timer = setTimeout(() => setSearching(false), 600);
      return () => clearTimeout(timer);
    }
  }, [searchQuery, selectedTag]);

  // Filter list of Hugging Face Models
  const filteredHFModels = INITIAL_HF_MODELS.filter(model => {
    const matchesSearch = model.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
                          model.author.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesTag = selectedTag === "All" || model.tags.includes(selectedTag);
    return matchesSearch && matchesTag;
  });

  const allTags = ["All", "Flux", "SDXL", "MLX", "GGUF", "Distilled", "ANE-optimized", "Real-Time"];

  return (
    <div className="relative mx-auto max-w-[340px] w-full aspect-[9/19.5] bg-[#0F1012] rounded-[52px] border-[10px] border-[#2D3136] shadow-[0_25px_60px_-15px_rgba(0,0,0,0.9)] overflow-hidden flex flex-col select-none ring-1 ring-white/5 paper-grain animate-fade-slow">
      
      {/* iPhone Dynamic Island / Speaker */}
      <div className="absolute top-2 left-1/2 -translate-x-1/2 w-28 h-6 bg-black rounded-full z-50 flex items-center justify-between px-3.5">
        <div className="w-1.5 h-1.5 bg-[#2D3136] rounded-full"></div>
        <div className="w-10 h-1 bg-[#181A1D] rounded-full"></div>
        <div className="w-3 h-3 bg-neutral-900/60 rounded-full flex items-center justify-center">
          <div className="w-1.5 h-1.5 bg-neutral-950 rounded-full"></div>
        </div>
      </div>

      {/* iPhone Screen Header / Status Bar */}
      <div className="pt-8 px-5 pb-2 bg-[#0F1012] flex justify-between items-center text-[9px] text-[#B8AE95] font-mono z-40 border-b border-[#2D3136]/40">
        <span>09:15 / SECURE</span>
        <div className="flex items-center gap-1.5">
          <Cpu className="w-3 h-3 text-[#B38B4D]" />
          <span className="text-[#B38B4D] font-mono text-[9px] uppercase tracking-wider">{hardwareStats.activeProcessingUnit}</span>
          <div className="w-5 h-2.5 border border-[#2D3136] rounded-[3px] p-0.5 flex items-center">
            <div className="h-full w-3.5 bg-[#B8AE95] rounded-[1px]"></div>
          </div>
        </div>
      </div>

      {/* Primary Screen Content Area */}
      <div className="flex-1 bg-[#0F1012] text-[#E5D7B4] overflow-y-auto overflow-x-hidden relative flex flex-col text-sm custom-scrollbar p-4">
        
        {/* TAB 1: REPOSITORY (HUGGING FACE MODEL CATALOG) */}
        {activeTab === "repository" && (
          <div className="flex-1 flex flex-col pt-1">
             <div className="flex items-start justify-between mb-3">
               <div className="text-left">
                 <span className="text-[8px] font-mono tracking-widest text-[#B38B4D] uppercase block">HF INDEX</span>
                 <h1 className="text-base font-serif font-bold text-[#E5D7B4]">Repository</h1>
                 <p className="text-[10px] text-[#B8AE95] mt-0.5 leading-relaxed">Sourced weights database for isolated local deployment</p>
               </div>
               <button
                 onClick={(e) => { e.stopPropagation(); setActiveTab("transmit"); }}
                 className="bg-[#202428] p-1.5 rounded-full text-[#B8AE95] hover:text-[#E5D7B4] border border-[#2D3136] mt-1 button-depress"
                 aria-label="Back to Transmit"
               >
                 <X className="w-3.5 h-3.5" />
               </button>
             </div>

            {/* Apple Store Style Feature Banner */}
            <div 
              className="relative w-full rounded-xl overflow-hidden mb-4 aspect-[16/9] cursor-pointer group border border-[#2D3136]"
              onClick={() => setSelectedModelForModal(INITIAL_HF_MODELS[0])}
            >
              <img 
                src="https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop&q=80" 
                alt="Featured model" 
                className="absolute inset-0 w-full h-full object-cover brightness-[0.35] transition-transform duration-500 group-hover:scale-102"
                referrerPolicy="no-referrer"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-[#0F1012] via-transparent to-transparent"></div>
              <div className="absolute bottom-3 left-3 right-3 text-left">
                <span className="text-[8px] font-mono text-[#B38B4D] tracking-widest uppercase">Catalog Spotlight</span>
                <h2 className="text-xs font-serif font-bold text-[#E5D7B4] mt-0.5">Flux.1 Dev</h2>
                <p className="text-[9px] text-[#B8AE95] line-clamp-1 font-sans">Sourced from Black Forest Labs • High fidelity output</p>
              </div>
            </div>

            {/* Understated Search Bar */}
            <div className="relative mb-3.5">
              <span className="absolute inset-y-0 left-3 flex items-center text-[#8A6B3D]">
                <Search className="w-3.5 h-3.5" />
              </span>
              <input
                type="text"
                placeholder="Query database records..."
                className="w-full pl-9 pr-3 py-1.5 bg-[#181A1D] border border-[#2D3136] rounded-lg text-xs text-[#E5D7B4] placeholder-[#8A6B3D]/70 focus:outline-none focus:border-[#B38B4D] transition-colors font-mono"
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
              />
              {searchQuery && (
                <button onClick={() => setSearchQuery("")} className="absolute right-2.5 top-2.5 p-1 text-[#B8AE95] hover:text-[#E5D7B4]">
                  <X className="w-3 h-3" />
                </button>
              )}
            </div>

            {/* Tag Pills */}
            <div className="flex gap-1.5 overflow-x-auto pb-2.5 mb-1 -mx-4 px-4 custom-scrollbar">
              {allTags.map(tag => (
                <button
                  key={tag}
                  onClick={() => setSelectedTag(tag)}
                  className={`text-[9px] px-2.5 py-1 rounded-md whitespace-nowrap transition-all border font-mono ${
                    selectedTag === tag
                      ? "bg-[#202428] border-[#B38B4D] text-[#E5D7B4] font-bold"
                      : "bg-[#181A1D]/60 border-[#2D3136] text-[#B8AE95] hover:text-[#E5D7B4]"
                  }`}
                >
                  {tag}
                </button>
              ))}
            </div>

            {/* Searching Repository Loader State */}
            {searching ? (
              <div className="flex-1 flex flex-col items-center justify-center py-12 text-[#B8AE95] space-y-2">
                <RefreshCw className="w-5 h-5 text-[#B38B4D] animate-spin" />
                <span className="text-[10px] font-mono tracking-widest uppercase">Searching Repository...</span>
              </div>
            ) : (
              /* Hugging Face Model Rows styled like Catalog entries */
              <div className="space-y-3 flex-1">
                {filteredHFModels.map(model => {
                  const isInstalled = installedModels.some(m => m.id === model.id);
                  const activeDownload = activeDownloads[model.id];

                  return (
                    <div 
                      key={model.id}
                      className="p-3 bg-[#181A1D] border border-[#2D3136] rounded-xl flex flex-col gap-2 hover:border-[#B38B4D]/40 transition-colors cursor-pointer group"
                      onClick={() => setSelectedModelForModal(model)}
                    >
                      <div className="flex gap-2.5 items-start">
                        <div className="w-10 h-10 rounded-lg bg-[#202428] border border-[#2D3136] overflow-hidden flex-shrink-0">
                          <img 
                            src={model.previewImage} 
                            alt={model.name} 
                            className="w-full h-full object-cover filter sepia brightness-90 group-hover:filter-none transition-all"
                            referrerPolicy="no-referrer"
                          />
                        </div>
                        <div className="flex-1 min-w-0 text-left">
                          <div className="flex items-center gap-1">
                            <h3 className="text-xs font-serif font-bold text-[#E5D7B4] line-clamp-1 group-hover:text-[#B38B4D] transition-colors">{model.name}</h3>
                          </div>
                          <p className="text-[9px] text-[#B8AE95] font-mono">by @{model.author}</p>
                          
                          {/* Star Ratings & Downloads */}
                          <div className="flex items-center gap-1.5 mt-1 text-[9px]">
                            <div className="flex text-[#B38B4D] gap-0.5">
                              <Star className="w-2 h-2 fill-current" />
                              <Star className="w-2 h-2 fill-current" />
                              <Star className="w-2 h-2 fill-current" />
                              <Star className="w-2 h-2 fill-current" />
                              <Star className="w-2 h-2 fill-current" />
                            </div>
                            <span className="text-[#8A6B3D] font-mono">•</span>
                            <span className="text-[#8A6B3D] font-mono">{(model.downloads / 1000).toFixed(0)}k records</span>
                          </div>
                        </div>

                        {/* Classic Vintage button style */}
                        <div className="text-right" onClick={e => e.stopPropagation()}>
                          {isInstalled ? (
                            <span className="inline-flex items-center gap-0.5 text-[8px] font-mono font-bold text-[#5C7A67] bg-[#5C7A67]/10 border border-[#5C7A67]/20 px-1.5 py-0.5 rounded">
                              Downloaded
                            </span>
                          ) : activeDownload ? (
                            <button 
                              className="relative flex items-center justify-center w-7 h-7 rounded-full border border-[#B38B4D] bg-[#202428] text-[#B38B4D]"
                              onClick={(e) => {
                                e.stopPropagation();
                                activeDownload.status === "downloading" ? pauseDownload(model.id) : resumeDownload(model.id);
                              }}
                            >
                              <span className="text-[8px] font-mono">{activeDownload.progress}%</span>
                            </button>
                          ) : (
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                startDownload(model);
                              }}
                              className="bg-[#202428] hover:bg-[#2D3136] text-[#B38B4D] text-[9px] font-mono font-bold px-2 py-1 rounded border border-[#2D3136] button-depress"
                            >
                              GET
                            </button>
                          )}
                        </div>
                      </div>

                      {/* Download Progress Bar */}
                      {activeDownload && (
                        <div className="pt-1.5 border-t border-[#2D3136]/60 mt-1">
                          <div className="w-full bg-[#0F1012] h-1 rounded-full overflow-hidden">
                            <div 
                              className={`h-full transition-all duration-300 ${activeDownload.status === "validating" ? "bg-[#C38F2C] animate-pulse" : "bg-[#B38B4D]"}`}
                              style={{ width: `${activeDownload.progress}%` }}
                            ></div>
                          </div>
                          <div className="flex justify-between items-center text-[7.5px] text-[#B8AE95] mt-1 font-mono">
                            <span>{activeDownload.status === "validating" ? "Validating Checksum..." : `${activeDownload.speedMBs.toFixed(1)} MB/s`}</span>
                            <span>{activeDownload.status === "paused" ? "Paused" : `${activeDownload.progress}%`}</span>
                          </div>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {/* TAB 2: TRANSMIT (GENERATION) */}
        {activeTab === "transmit" && (
          <div className="flex-1 flex flex-col pt-1">
            <div className="text-left mb-3">
              <span className="text-[8px] font-mono tracking-widest text-[#B38B4D] uppercase block">TRANSMISSION CORE</span>
              <h1 className="text-base font-serif font-bold text-[#E5D7B4]">Recovered Knowledge</h1>
              <p className="text-[10px] text-[#B8AE95] mt-0.5 leading-relaxed">Execute localized mathematical matrix reconstruction</p>
            </div>

            {/* Archive Select Model */}
            <div className="p-3 bg-[#181A1D] border border-[#2D3136] rounded-xl mb-4 text-left">
              <div className="flex items-center justify-between mb-1.5">
                <span className="text-[8.5px] text-[#B8AE95] uppercase font-mono tracking-wider">Target Weights Record</span>
                <HardDrive className="w-3.5 h-3.5 text-[#B38B4D]" />
              </div>
              
              {installedModels.length === 0 ? (
                <div className="text-center py-2">
                  <p className="text-[10px] text-[#B8AE95] mb-2 font-mono">No catalog weights detected.</p>
                  <button 
                    onClick={(e) => { e.stopPropagation(); setActiveTab("repository"); }}
                    className="text-[9px] text-[#B38B4D] bg-[#202428] border border-[#2D3136] px-2.5 py-1 rounded font-mono font-bold hover:bg-[#2D3136]"
                  >
                    Locate in Repository
                  </button>
                </div>
              ) : (
                <select
                  value={activeModelId}
                  onChange={e => setActiveModelId(e.target.value)}
                  className="w-full bg-[#0F1012] text-xs font-serif font-bold text-[#E5D7B4] rounded-lg p-2 border border-[#2D3136] focus:outline-none focus:border-[#B38B4D]"
                >
                  {installedModels.map(model => (
                    <option key={model.id} value={model.id} className="bg-[#181A1D]">
                      {model.name.split(" ")[0]} ({model.fileSize})
                    </option>
                  ))}
                </select>
              )}
            </div>

            {/* Form Fields */}
            <div className="space-y-3.5 text-left flex-1">
              
              {/* Prompt Input */}
              <div className="flex flex-col gap-1">
                <label className="text-[9px] font-mono text-[#B8AE95] uppercase tracking-wider">Prompt</label>
                <textarea
                  placeholder="Inscribe desired visual parameters (e.g. A faded antique photograph of a forgotten research vault)..."
                  className="w-full h-20 p-2.5 bg-[#181A1D] border border-[#2D3136] rounded-xl text-xs text-[#E5D7B4] placeholder-[#8A6B3D]/60 focus:outline-none focus:border-[#B38B4D] focus:ring-1 focus:ring-[#B38B4D]/30 transition-all resize-none font-sans leading-relaxed"
                  value={prompt}
                  onChange={e => setPrompt(e.target.value)}
                  disabled={isGenerating}
                />
              </div>

              {/* Negative Prompt */}
              <div className="flex flex-col gap-1">
                <label className="text-[9px] font-mono text-[#B8AE95] uppercase tracking-wider">Negative Prompt</label>
                <input
                  type="text"
                  placeholder="avoid: neon, high contrast, text, signature..."
                  className="w-full px-2.5 py-1.5 bg-[#181A1D] border border-[#2D3136] rounded-xl text-xs text-[#E5D7B4] placeholder-[#8A6B3D]/60 focus:outline-none focus:border-[#B38B4D] transition-all font-sans"
                  value={negativePrompt}
                  onChange={e => setNegativePrompt(e.target.value)}
                  disabled={isGenerating}
                />
              </div>

              {/* Understated Parameters Panel */}
              <div className="p-3 bg-[#181A1D]/60 border border-[#2D3136] rounded-xl space-y-3.5">
                <div className="flex items-center gap-1.5 text-[10px] font-mono font-bold text-[#B8AE95]">
                  <Sliders className="w-3.5 h-3.5 text-[#B38B4D]" />
                  <span>MATRIX PARAMETERS</span>
                </div>

                {/* Image Size Selector (requested in prompt: Image Size 1024 x 1024) */}
                <div className="space-y-1">
                  <div className="flex justify-between items-center text-[8px] text-[#B8AE95] font-mono uppercase tracking-wider">
                    <span>Image Size</span>
                    <span className="text-[#B38B4D] font-bold">1024 × 1024</span>
                  </div>
                  <div className="grid grid-cols-2 gap-1.5">
                    <button
                      type="button"
                      onClick={() => setImageSize("1K")}
                      className={`text-[9px] px-2 py-1 rounded border font-mono ${imageSize === "1K" ? "bg-[#202428] border-[#B38B4D] text-[#E5D7B4] font-bold" : "bg-[#0F1012] border-[#2D3136] text-[#B8AE95]"}`}
                    >
                      1024 × 1024
                    </button>
                    <button
                      type="button"
                      onClick={() => setImageSize("512px")}
                      className={`text-[9px] px-2 py-1 rounded border font-mono ${imageSize === "512px" ? "bg-[#202428] border-[#B38B4D] text-[#E5D7B4] font-bold" : "bg-[#0F1012] border-[#2D3136] text-[#B8AE95]"}`}
                    >
                      512 × 512
                    </button>
                  </div>
                </div>

                {/* Aspect Ratio Selector */}
                <div className="space-y-1">
                  <span className="text-[8px] text-[#B8AE95] font-mono uppercase tracking-wider block">Aspect Ratio</span>
                  <div className="grid grid-cols-5 gap-1">
                    {(["1:1", "3:4", "4:3", "9:16", "16:9"] as const).map(ratio => (
                      <button
                        key={ratio}
                        onClick={() => setAspectRatio(ratio)}
                        className={`text-[8.5px] px-1 py-0.5 rounded border font-mono ${
                          aspectRatio === ratio
                            ? "bg-[#202428] border-[#B38B4D] text-[#E5D7B4] font-bold"
                            : "bg-[#0F1012] border-[#2D3136] text-[#B8AE95]"
                        }`}
                        disabled={isGenerating}
                      >
                        {ratio}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Seed Controls */}
                <div className="space-y-1">
                  <div className="flex justify-between items-center text-[8px] text-[#B8AE95] font-mono uppercase tracking-wider">
                    <span>Seed</span>
                    <button 
                      onClick={() => setRandomSeed(!randomSeed)}
                      className={`text-[8px] font-mono px-1.5 py-0.5 rounded border ${randomSeed ? "bg-[#5C7A67]/10 text-[#E5D7B4] border-[#5C7A67]" : "bg-[#0F1012] text-[#B8AE95] border-[#2D3136]"}`}
                      disabled={isGenerating}
                    >
                      {randomSeed ? "Random" : "Static"}
                    </button>
                  </div>
                  {!randomSeed && (
                    <input
                      type="number"
                      className="w-full px-2 py-1 bg-[#0F1012] border border-[#2D3136] rounded text-xs text-[#E5D7B4] font-mono focus:outline-none focus:border-[#B38B4D]"
                      value={seed}
                      onChange={e => setSeed(parseInt(e.target.value) || 0)}
                      disabled={isGenerating}
                    />
                  )}
                </div>
              </div>
            </div>

            {/* Recovering Image Screen / Loading Overlay during generation */}
            {isGenerating && (
              <div className="absolute inset-0 bg-[#0F1012] z-50 flex flex-col justify-center p-6 text-center paper-grain">
                {/* Slow elegant progress indicator */}
                <div className="relative mx-auto w-24 h-24 mb-6">
                  <svg className="w-full h-full transform -rotate-90">
                    <circle cx="48" cy="48" r="40" stroke="#181A1D" strokeWidth="3" fill="transparent" />
                    <circle 
                      cx="48" 
                      cy="48" 
                      r="40" 
                      stroke="#B38B4D" 
                      strokeWidth="3" 
                      fill="transparent" 
                      strokeDasharray="251.2"
                      strokeDashoffset={251.2 - (251.2 * generationProgress) / 100}
                      className="transition-all duration-500 ease-out"
                    />
                  </svg>
                  <div className="absolute inset-0 flex flex-col items-center justify-center">
                    <span className="text-base font-serif font-bold text-[#E5D7B4] font-mono">{generationProgress}%</span>
                    <span className="text-[7.5px] text-[#B8AE95] font-mono uppercase tracking-wider">STEP {generationStep}/{steps}</span>
                  </div>
                </div>

                <div className="space-y-1 mb-6">
                  <h3 className="text-sm font-serif font-bold text-[#E5D7B4] tracking-wide">Recovering Image...</h3>
                  <p className="text-[9px] text-[#B8AE95] font-mono uppercase tracking-wider">Denoising localized matrix cells...</p>
                </div>

                {/* Classic low-key console output logs */}
                <div className="flex-1 bg-[#181A1D] rounded-xl border border-[#2D3136] p-3 text-left font-mono text-[8px] text-[#B8AE95] overflow-y-auto space-y-1.5 select-text custom-scrollbar">
                  {systemLogs.map((log, index) => (
                    <div key={index} className="leading-normal flex items-start gap-1">
                      <span className="text-[#B38B4D] select-none">&gt;</span>
                      <span>{log}</span>
                    </div>
                  ))}
                </div>

                {/* Cancel Button */}
                <button
                  onClick={(e) => { e.stopPropagation(); cancelTransmission(); }}
                  className="mt-4 w-full bg-[#181A1D] border border-[#2D3136] py-2 rounded-xl text-[10px] font-mono font-bold text-[#C38F2C] hover:bg-[#202428] transition-colors button-depress"
                >
                  ABORT TRANSMISSION
                </button>
              </div>
            )}

            {/* TRANSMIT BUTTON */}
            <button
              onClick={(e) => { e.stopPropagation(); handleTransmit(); }}
              disabled={isGenerating || installedModels.length === 0 || !prompt.trim()}
              className={`w-full py-2.5 rounded-lg font-serif font-bold text-xs flex items-center justify-center gap-2 tracking-widest uppercase border transition-all mt-4 button-depress ${
                installedModels.length === 0 
                  ? "bg-[#181A1D] text-[#8A6B3D]/50 border-[#2D3136] cursor-not-allowed" 
                  : !prompt.trim()
                  ? "bg-[#181A1D] text-[#8A6B3D]/70 border-[#2D3136] cursor-not-allowed"
                  : "bg-[#202428] text-[#E5D7B4] border-[#B38B4D] hover:bg-[#2D3136] hover:text-[#B38B4D] shadow-md shadow-black/30"
              }`}
            >
              <Play className="w-3.5 h-3.5 text-[#B38B4D]" /> Transmit
            </button>
          </div>
        )}

        {/* TAB 3: THE ARCHIVE (GALLERY OF RECOVERED IMAGES) */}
        {activeTab === "archive" && (
          <div className="flex-1 flex flex-col pt-1">
             <div className="flex items-start justify-between mb-3">
               <div className="text-left">
                 <span className="text-[8px] font-mono tracking-widest text-[#B38B4D] uppercase block">RECOVERED RECORDINGS</span>
                 <h1 className="text-base font-serif font-bold text-[#E5D7B4]">Archive</h1>
                 <p className="text-[10px] text-[#B8AE95] mt-0.5 leading-relaxed">Secured visual reconstructions cataloged in permanent memory</p>
               </div>
               <button
                 onClick={(e) => { e.stopPropagation(); setActiveTab("transmit"); }}
                 className="bg-[#202428] p-1.5 rounded-full text-[#B8AE95] hover:text-[#E5D7B4] border border-[#2D3136] mt-1 button-depress"
                 aria-label="Back to Transmit"
               >
                 <X className="w-3.5 h-3.5" />
               </button>
             </div>

            {generatedImages.length === 0 ? (
              <div className="flex-1 flex flex-col justify-center items-center text-center p-4">
                <div className="w-12 h-12 bg-[#181A1D] rounded-full flex items-center justify-center mb-3 border border-[#2D3136]">
                  <ArchiveIcon className="w-5 h-5 text-[#8A6B3D]" />
                </div>
                <h3 className="text-xs font-serif font-bold text-[#E5D7B4]">The Archive is Empty.</h3>
                <p className="text-[10px] text-[#B8AE95] max-w-[180px] mt-1.5 leading-relaxed font-sans">Begin your first transmission to recover visual knowledge.</p>
                <button 
                  onClick={(e) => { e.stopPropagation(); setActiveTab("transmit"); }}
                  className="mt-4 bg-[#202428] border border-[#B38B4D] text-[#E5D7B4] text-[9px] font-mono font-bold px-3 py-1.5 rounded hover:bg-[#2D3136] transition-all button-depress"
                >
                  TRANSMIT CORE
                </button>
              </div>
            ) : (
              /* Archive grid styled like antique index cards */
              <div className="space-y-3 flex-1 overflow-y-auto custom-scrollbar pr-0.5">
                {generatedImages.map((img, idx) => {
                  const recordNum = String(140 + idx).padStart(4, "0");
                  return (
                    <div 
                      key={img.id}
                      className="p-2.5 bg-[#181A1D] border border-[#2D3136] rounded-xl flex flex-col gap-2 text-left"
                    >
                      {/* Image Viewer */}
                      <div className="relative aspect-square w-full rounded-lg overflow-hidden bg-[#0F1012] border border-[#2D3136]">
                        <img 
                          src={img.imageUrl} 
                          alt={`Archive Record ${recordNum}`} 
                          className="w-full h-full object-cover filter sepia-[0.1] brightness-90 hover:brightness-100 transition-all cursor-pointer"
                          onClick={() => setSelectedImageForModal(img)}
                          referrerPolicy="no-referrer"
                        />
                      </div>

                      {/* Archived record details format */}
                      <div className="flex justify-between items-start font-mono text-[9px] text-[#B8AE95]">
                        <div className="space-y-0.5">
                          <span className="text-[#E5D7B4] font-serif font-bold text-xs block">Archive #{recordNum}</span>
                          <span className="text-[#5C7A67] bg-[#5C7A67]/10 px-1 py-0.2 rounded font-bold mr-1">Recovered</span>
                          <span>• {img.modelName || "Flux.1 Dev"}</span>
                        </div>
                        <div className="text-right">
                          <span className="block text-[#8A6B3D]">{img.timestamp}</span>
                        </div>
                      </div>

                      {/* Understated action options: View, Share, Save */}
                      <div className="grid grid-cols-3 gap-1 pt-1.5 border-t border-[#2D3136]/50">
                        <button 
                          onClick={() => setSelectedImageForModal(img)}
                          className="py-1 text-[8px] font-mono font-bold uppercase tracking-wider text-[#B8AE95] bg-[#202428]/50 border border-[#2D3136] hover:text-[#E5D7B4] rounded button-depress flex items-center justify-center gap-1"
                        >
                          View
                        </button>
                        <button 
                          onClick={() => alert(`Record #${recordNum} exported to clipboard!`)}
                          className="py-1 text-[8px] font-mono font-bold uppercase tracking-wider text-[#B8AE95] bg-[#202428]/50 border border-[#2D3136] hover:text-[#E5D7B4] rounded button-depress flex items-center justify-center gap-1"
                        >
                          Share
                        </button>
                        <button 
                          onClick={() => alert(`Record #${recordNum} committed to secure system library.`)}
                          className="py-1 text-[8px] font-mono font-bold uppercase tracking-wider text-[#B8AE95] bg-[#202428]/50 border border-[#2D3136] hover:text-[#E5D7B4] rounded button-depress flex items-center justify-center gap-1"
                        >
                          Save
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {/* TAB 4: CABINET (LOCAL STORAGE FOR DOWNLOADED MODELS) */}
        {activeTab === "cabinet" && (
          <div className="flex-1 flex flex-col pt-1">
             <div className="flex items-start justify-between mb-3">
               <div className="text-left">
                 <span className="text-[8px] font-mono tracking-widest text-[#B38B4D] uppercase block">SYSTEM FILES</span>
                 <h1 className="text-base font-serif font-bold text-[#E5D7B4]">Cabinet</h1>
                 <p className="text-[10px] text-[#B8AE95] mt-0.5 leading-relaxed">Deploy and manage local weight partitions offline</p>
               </div>
               <button
                 onClick={(e) => { e.stopPropagation(); setActiveTab("transmit"); }}
                 className="bg-[#202428] p-1.5 rounded-full text-[#B8AE95] hover:text-[#E5D7B4] border border-[#2D3136] mt-1 button-depress"
                 aria-label="Back to Transmit"
               >
                 <X className="w-3.5 h-3.5" />
               </button>
             </div>

            {installedModels.length === 0 ? (
              <div className="flex-1 flex flex-col justify-center items-center text-center p-4">
                <div className="w-12 h-12 bg-[#181A1D] rounded-full flex items-center justify-center mb-3 border border-[#2D3136]">
                  <HardDrive className="w-5 h-5 text-[#8A6B3D]" />
                </div>
                <h3 className="text-xs font-serif font-bold text-[#E5D7B4]">Cabinet Empty</h3>
                <p className="text-[10px] text-[#B8AE95] max-w-[180px] mt-1.5 leading-relaxed font-sans">No localized model weights have been locked onto internal drive sectors.</p>
                <button 
                  onClick={(e) => { e.stopPropagation(); setActiveTab("repository"); }}
                  className="mt-4 bg-[#202428] border border-[#B38B4D] text-[#E5D7B4] text-[9px] font-mono font-bold px-3 py-1.5 rounded hover:bg-[#2D3136] transition-all button-depress"
                >
                  OPEN REPOSITORY
                </button>
              </div>
            ) : (
              <div className="space-y-2.5 flex-1 overflow-y-auto custom-scrollbar">
                {installedModels.map(model => (
                  <div 
                    key={model.id}
                    className="p-3 bg-[#181A1D] border border-[#2D3136] rounded-xl flex flex-col text-left gap-1.5 hover:border-[#B38B4D]/30 transition-colors"
                  >
                    <div className="flex justify-between items-start">
                      <div className="min-w-0 flex-1">
                        <h3 className="text-xs font-serif font-bold text-[#E5D7B4] truncate">{model.name}</h3>
                        <p className="text-[9px] text-[#B8AE95] font-mono">by @{model.author}</p>
                      </div>
                      <div className="flex gap-1">
                        <button 
                          onClick={() => deleteModel(model.id)}
                          className="p-1 rounded text-[#B8AE95] hover:text-[#C38F2C] hover:bg-[#202428] transition-colors"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </div>

                    <div className="pt-2 border-t border-[#2D3136]/50 mt-1 flex justify-between items-center text-[8.5px] font-mono text-[#8A6B3D]">
                      <span>{model.fileSize}</span>
                      <span>FORMAT: {model.format}</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

      </div>

      {/* Dynamic Model Detail Drawer Modal */}
      {selectedModelForModal && (
        <div className="absolute inset-0 bg-black/80 z-50 flex items-end">
          <div className="w-full bg-[#181A1D] rounded-t-[28px] p-5 pb-8 text-left space-y-4 border-t border-[#2D3136] max-h-[85%] overflow-y-auto custom-scrollbar">
            <div className="flex justify-between items-start">
              <div className="flex gap-3">
                <div className="w-12 h-12 rounded-xl bg-[#202428] border border-[#2D3136] overflow-hidden flex-shrink-0">
                  <img 
                    src={selectedModelForModal.previewImage} 
                    alt={selectedModelForModal.name} 
                    className="w-full h-full object-cover filter sepia brightness-90"
                    referrerPolicy="no-referrer"
                  />
                </div>
                <div>
                  <h2 className="text-xs font-serif font-bold text-[#E5D7B4]">{selectedModelForModal.name}</h2>
                  <p className="text-[9px] text-[#B8AE95] font-mono">by @{selectedModelForModal.author}</p>
                  <span className="inline-block mt-1 text-[8px] uppercase tracking-widest font-mono font-bold text-[#B38B4D] bg-[#B38B4D]/10 border border-[#B38B4D]/20 px-1.5 py-0.5 rounded">
                    {selectedModelForModal.format}
                  </span>
                </div>
              </div>
              <button 
                onClick={() => setSelectedModelForModal(null)}
                className="bg-[#202428] p-1 rounded-full text-[#B8AE95] hover:text-[#E5D7B4]"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <p className="text-[10px] text-[#B8AE95] leading-relaxed font-sans">{selectedModelForModal.description}</p>

            <div className="grid grid-cols-2 gap-2 bg-[#0F1012] p-3 rounded-lg border border-[#2D3136] font-mono text-[8.5px] text-[#B8AE95]">
              <div>
                <span className="text-[#8A6B3D] block">LICENSE CODE</span>
                <span className="text-[#E5D7B4] font-semibold">{selectedModelForModal.license}</span>
              </div>
              <div>
                <span className="text-[#8A6B3D] block">CATALOG UPDATE</span>
                <span className="text-[#E5D7B4] font-semibold">{selectedModelForModal.lastUpdated}</span>
              </div>
              <div className="mt-1.5">
                <span className="text-[#8A6B3D] block">SECTOR SIZE</span>
                <span className="text-[#E5D7B4] font-semibold">{selectedModelForModal.fileSize}</span>
              </div>
              <div className="mt-1.5">
                <span className="text-[#8A6B3D] block">COPROCESSOR SPEED</span>
                <span className={`font-semibold ${selectedModelForModal.isCompatibleWithANE ? "text-[#5C7A67]" : "text-[#C38F2C]"}`}>
                  {selectedModelForModal.isCompatibleWithANE ? "Neural Engine Optimised" : "GPU fallback required"}
                </span>
              </div>
            </div>

            {/* Model tags */}
            <div className="flex flex-wrap gap-1">
              {selectedModelForModal.tags.map(t => (
                <span key={t} className="text-[8px] font-mono bg-[#202428] text-[#B8AE95] px-1.5 py-0.5 rounded border border-[#2D3136]">#{t}</span>
              ))}
            </div>

            {/* GET action button inside modal */}
            {installedModels.some(m => m.id === selectedModelForModal.id) ? (
              <div className="w-full py-2 rounded-xl bg-[#5C7A67]/10 text-[#E5D7B4] border border-[#5C7A67]/20 font-serif font-bold text-xs text-center flex items-center justify-center gap-1">
                <CheckCircle2 className="w-4 h-4 text-[#5C7A67]" /> Sourced in Cabinet
              </div>
            ) : (
              <button
                onClick={() => {
                  startDownload(selectedModelForModal);
                  setSelectedModelForModal(null);
                }}
                className="w-full py-2 rounded-xl bg-[#202428] hover:bg-[#2D3136] text-[#B38B4D] border border-[#B38B4D] font-serif font-bold text-xs tracking-wider flex items-center justify-center gap-1.5 button-depress"
              >
                <Download className="w-4 h-4" /> Download weight parameters ({selectedModelForModal.fileSize})
              </button>
            )}
          </div>
        </div>
      )}

      {/* Dynamic Image Info Inspect Modal */}
      {selectedImageForModal && (
        <div className="absolute inset-0 bg-black/80 z-50 flex items-end">
          <div className="w-full bg-[#181A1D] rounded-t-[28px] p-5 pb-8 text-left space-y-4 border-t border-[#2D3136] max-h-[85%] overflow-y-auto custom-scrollbar">
            <div className="flex justify-between items-start">
              <h2 className="text-xs font-serif font-bold text-[#E5D7B4] flex items-center gap-1.5">
                <Info className="w-4 h-4 text-[#B38B4D]" /> Archive File Metadata
              </h2>
              <button 
                onClick={() => setSelectedImageForModal(null)}
                className="bg-[#202428] p-1 rounded-full text-[#B8AE95] hover:text-[#E5D7B4]"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <img 
              src={selectedImageForModal.imageUrl} 
              alt="Inspect" 
              className="w-full rounded-xl aspect-square object-cover border border-[#2D3136] filter sepia-[0.05]"
              referrerPolicy="no-referrer"
            />

            <div className="space-y-1">
              <span className="text-[8px] font-mono text-[#8A6B3D] uppercase tracking-wider block">Visual Blueprint</span>
              <p className="text-[10px] text-[#E5D7B4] bg-[#0F1012] p-2.5 rounded-lg border border-[#2D3136] text-left select-all leading-relaxed font-sans">{selectedImageForModal.prompt}</p>
            </div>

            {selectedImageForModal.negativePrompt && (
              <div className="space-y-1">
                <span className="text-[8px] font-mono text-[#8A6B3D] uppercase tracking-wider block">Excluded Signals</span>
                <p className="text-[10px] text-[#B8AE95] bg-[#0F1012] p-2 rounded-lg border border-[#2D3136] text-left leading-relaxed font-sans">{selectedImageForModal.negativePrompt}</p>
              </div>
            )}

            <div className="grid grid-cols-2 gap-2 bg-[#0F1012] p-3 rounded-lg border border-[#2D3136] font-mono text-[8.5px] text-[#B8AE95]">
              <div>
                <span className="text-[#8A6B3D] block">MODEL COMMITTED</span>
                <span className="text-[#E5D7B4] font-semibold">{selectedImageForModal.modelName}</span>
              </div>
              <div>
                <span className="text-[#8A6B3D] block">SEED COORDINATES</span>
                <span className="text-[#B38B4D] font-semibold">{selectedImageForModal.seed}</span>
              </div>
              <div className="mt-1.5">
                <span className="text-[#8A6B3D] block">DECODING UNIT</span>
                <span className="text-[#5C7A67] font-semibold flex items-center gap-0.5">
                  <Cpu className="w-2.5 h-2.5" /> {selectedImageForModal.engine}
                </span>
              </div>
              <div className="mt-1.5">
                <span className="text-[#8A6B3D] block">RECOVERY LATENCY</span>
                <span className="text-[#E5D7B4] font-semibold">{selectedImageForModal.latencySeconds}s / {(selectedImageForModal.peakMemoryMB / 1024).toFixed(1)} GB</span>
              </div>
            </div>

            <div className="flex gap-2.5 pt-1">
              <button 
                onClick={() => {
                  alert("Archive saved safely in host system cache.");
                  setSelectedImageForModal(null);
                }}
                className="flex-1 py-2 rounded-lg bg-[#202428] hover:bg-[#2D3136] text-[#E5D7B4] font-mono font-bold text-[10px] border border-[#2D3136] button-depress"
              >
                SAVE ARTIFACT
              </button>
              <button 
                onClick={() => {
                  alert("Artifact code coordinate hash shared!");
                  setSelectedImageForModal(null);
                }}
                className="px-3.5 py-2 rounded-lg bg-[#B38B4D] hover:bg-[#8A6B3D] text-[#0F1012] font-mono font-bold text-[10px] button-depress flex items-center justify-center"
              >
                <Share2 className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* iPhone Screen Footer / Home Indicator */}
      <div className="bg-[#0F1012] pt-1 pb-4 z-40 flex flex-col justify-end border-t border-[#2D3136]/50">
        {/* iOS Styled Tab Bar */}
        <div className="grid grid-cols-4 pt-1.5 pb-1 text-[8.5px] font-mono text-[#B8AE95]">
          <button 
            onClick={() => setActiveTab("repository")}
            className={`flex flex-col items-center gap-1 py-1 ${activeTab === "repository" ? "text-[#E5D7B4] font-bold" : "hover:text-[#E5D7B4]/80 text-[#B8AE95]/60"}`}
          >
            <Search className="w-3.5 h-3.5 text-[#B38B4D]" />
            <span>Repository</span>
          </button>
          <button 
            onClick={(e) => { e.stopPropagation(); setActiveTab("transmit"); }}
            className={`flex flex-col items-center gap-1 py-1 ${activeTab === "transmit" ? "text-[#E5D7B4] font-bold" : "hover:text-[#E5D7B4]/80 text-[#B8AE95]/60"}`}
          >
            <Sparkles className="w-3.5 h-3.5 text-[#B38B4D]" />
            <span>Transmit</span>
          </button>
          <button 
            onClick={() => setActiveTab("archive")}
            className={`flex flex-col items-center gap-1 py-1 ${activeTab === "archive" ? "text-[#E5D7B4] font-bold" : "hover:text-[#E5D7B4]/80 text-[#B8AE95]/60"}`}
          >
            <ArchiveIcon className="w-3.5 h-3.5 text-[#B38B4D]" />
            <span>Archive</span>
          </button>
          <button 
            onClick={() => setActiveTab("cabinet")}
            className={`flex flex-col items-center gap-1 py-1 ${activeTab === "cabinet" ? "text-[#E5D7B4] font-bold" : "hover:text-[#E5D7B4]/80 text-[#B8AE95]/60"}`}
          >
            <Folder className="w-3.5 h-3.5 text-[#B38B4D]" />
            <span>Cabinet</span>
          </button>
        </div>

        {/* Home Indicator */}
        <div className="w-24 h-1 bg-[#2D3136] rounded-full mx-auto mt-2"></div>
      </div>

    </div>
  );
}
