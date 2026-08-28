export interface HFModel {
  id: string;
  name: string;
  author: string;
  description: string;
  downloads: number;
  likes: number;
  lastUpdated: string;
  license: string;
  fileSize: string; // e.g., "1.8 GB", "3.4 GB"
  fileSizeBytes: number;
  previewImage: string;
  tags: string[];
  format: "CoreML" | "MilProgram" | "StableDiffusion" | "Flux" | "MLX" | "GGUF";
  isCompatibleWithANE: boolean; // True if optimized for Apple Neural Engine
  isFavorite?: boolean;
}

export interface InstalledModel {
  id: string;
  name: string;
  author: string;
  fileSize: string;
  installedPath: string;
  dateInstalled: string;
  isFavorite: boolean;
  format: string;
  capabilities: string[]; // e.g. ["Text-to-Image", "Inpainting"]
  customName?: string;
}

export interface GeneratedImage {
  id: string;
  imageUrl: string;
  prompt: string;
  negativePrompt?: string;
  width: number;
  height: number;
  seed: number;
  modelId: string;
  modelName: string;
  timestamp: string;
  latencySeconds: number;
  peakMemoryMB: number;
  isFavorite: boolean;
  engine: string; // e.g., "CoreML (ANE Optimized)", "GPU Fallback"
}

export interface DownloadTask {
  modelId: string;
  modelName: string;
  progress: number; // 0 to 100
  bytesDownloaded: number;
  totalBytes: number;
  speedMBs: number;
  status: "downloading" | "paused" | "validating" | "installed" | "failed";
  error?: string;
}

export interface SystemHardwareStats {
  chipset: string; // e.g., "A18 Pro" or "M4"
  neuralEngineCores: number;
  totalMemoryGB: number;
  availableMemoryGB: number;
  activeProcessingUnit: "ANE" | "GPU" | "CPU";
  memoryFootprintMB: number;
}
