import React from "react";
import { Cpu, ShieldAlert, Cpu as CoreMlicon, Layers, HardDrive, Info, CheckCircle, Zap, Activity, ChevronRight } from "lucide-react";

export default function TechSpecs() {
  return (
    <div className="bg-archive-card border border-archive-border rounded-xl p-6 text-left space-y-6 paper-grain">
      
      {/* Header section with vintage text hierarchy */}
      <div className="flex items-center gap-3 pb-4 border-b border-archive-border">
        <Cpu className="w-5 h-5 text-archive-bronze" />
        <div>
          <span className="text-[8px] font-mono tracking-widest text-[#B38B4D] uppercase block">SOC LOGISTICS</span>
          <h2 className="text-sm font-serif font-bold text-archive-text">ANE Co-Processor & Unified RAM Budgets</h2>
          <p className="text-[10px] text-archive-text-muted">Directives for optimizing on-device hardware constraints</p>
        </div>
      </div>

      {/* Memory Budgets Bento Grid */}
      <div className="space-y-3">
        <h3 className="text-[10px] font-mono font-bold text-archive-text uppercase tracking-widest flex items-center gap-1.5">
          <Activity className="w-3.5 h-3.5 text-archive-bronze" /> PHYSICAL HARDWARE THRESHOLDS
        </h3>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3.5">
          <div className="p-3.5 bg-[#0F1012] rounded-lg border border-archive-border space-y-1.5">
            <div className="flex justify-between items-center text-[9px] font-mono font-bold text-archive-text">
              <span>6 GB RAM</span>
              <span className="text-archive-amber">Jetsam Limit: 3.3 GB</span>
            </div>
            <p className="text-[9.5px] text-archive-text-muted leading-relaxed font-sans">
              iPhone 13 Pro, 14, 15. Requires aggressive <strong>INT4 quantization</strong> of weights. Cannot load uncompressed pipelines safely.
            </p>
            <span className="inline-block text-[8px] font-mono font-bold bg-[#202428] text-archive-text-muted border border-archive-border px-1.5 py-0.5 rounded">
              MobileDiffusion V2
            </span>
          </div>

          <div className="p-3.5 bg-[#0F1012] rounded-lg border border-archive-border space-y-1.5">
            <div className="flex justify-between items-center text-[9px] font-mono font-bold text-archive-text">
              <span>8 GB RAM</span>
              <span className="text-archive-bronze">Jetsam Limit: 4.4 GB</span>
            </div>
            <p className="text-[9.5px] text-archive-text-muted leading-relaxed font-sans">
              iPhone 15 Pro, 16, 16 Plus. Supports <strong>INT8 Quantized Flux.1-schnell</strong> or <strong>FP16 SDXL Turbo</strong>.
            </p>
            <span className="inline-block text-[8px] font-mono font-bold bg-archive-bronze/10 text-archive-bronze border border-archive-bronze/30 px-1.5 py-0.5 rounded">
              Ideal Target Allocation
            </span>
          </div>

          <div className="p-3.5 bg-[#0F1012] rounded-lg border border-archive-border space-y-1.5">
            <div className="flex justify-between items-center text-[9px] font-mono font-bold text-archive-text">
              <span>12 GB+ iPad/Mac</span>
              <span className="text-archive-green">Jetsam Limit: 6.6+ GB</span>
            </div>
            <p className="text-[9.5px] text-archive-text-muted leading-relaxed font-sans">
              iPads/Macs with M1-M4. Supports uncompressed FP16 SDXL models and custom multi-LoRA pipelines.
            </p>
            <span className="inline-block text-[8px] font-mono font-bold bg-archive-green/10 text-archive-green border border-archive-green/30 px-1.5 py-0.5 rounded">
              Unrestricted Pipelines
            </span>
          </div>
        </div>
      </div>

      {/* Computational Framework Comparisons */}
      <div className="space-y-3 pt-1">
        <h3 className="text-[10px] font-mono font-bold text-archive-text uppercase tracking-widest flex items-center gap-1.5">
          <Layers className="w-3.5 h-3.5 text-archive-bronze" /> COMPUTE FRAMEWORKS & FORMAT CORES
        </h3>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3.5">
          <div className="p-3 bg-[#0F1012] rounded-lg border border-archive-border space-y-1.5">
            <div className="flex justify-between items-center text-[9px] font-mono font-bold text-archive-text">
              <span className="text-archive-bronze">Apple CoreML</span>
              <span className="text-archive-green">ANE-Native</span>
            </div>
            <p className="text-[9.5px] text-archive-text-muted leading-relaxed font-sans">
              Compiles static neural graphs mapping directly to the custom Matrix Multiplier units in the Neural Engine. <strong>Outstanding power efficiency</strong> but requires lengthy compilation steps.
            </p>
            <span className="inline-block text-[8px] font-mono font-bold bg-[#202428] text-archive-text-muted border border-archive-border px-1.5 py-0.5 rounded">
              .mlmodelc File Units
            </span>
          </div>

          <div className="p-3 bg-[#0F1012] rounded-lg border border-archive-border space-y-1.5">
            <div className="flex justify-between items-center text-[9px] font-mono font-bold text-archive-text">
              <span className="text-archive-bronze">Apple MLX</span>
              <span className="text-archive-green">Metal GPU-Native</span>
            </div>
            <p className="text-[9.5px] text-archive-text-muted leading-relaxed font-sans">
              Apple Research's array framework. Computes weights natively on Apple Silicon GPUs. <strong>Zero compilation overhead</strong>, direct Metal Shaders bindings, and beautiful float16/int8 memory layouts.
            </p>
            <span className="inline-block text-[8px] font-mono font-bold bg-archive-bronze/10 text-archive-bronze border border-archive-bronze/30 px-1.5 py-0.5 rounded">
              .safetensors / MLX Arrays
            </span>
          </div>

          <div className="p-3 bg-[#0F1012] rounded-lg border border-archive-border space-y-1.5">
            <div className="flex justify-between items-center text-[9px] font-mono font-bold text-archive-text">
              <span className="text-archive-bronze">GGUF (llama.cpp)</span>
              <span className="text-archive-green">Quantized CPU/GPU</span>
            </div>
            <p className="text-[9.5px] text-archive-text-muted leading-relaxed font-sans">
              Universal binary weight layout. Spans layer-by-layer offloading between host CPU registers and Metal GPU buffers. <strong>Ultimate compression and low footprint</strong> for huge 12B+ parameter models.
            </p>
            <span className="inline-block text-[8px] font-mono font-bold bg-archive-green/10 text-archive-green border border-archive-green/30 px-1.5 py-0.5 rounded">
              .gguf Unified Weights
            </span>
          </div>
        </div>
      </div>

      {/* Optimization Rules */}
      <div className="space-y-4 pt-2">
        <h3 className="text-[10px] font-mono font-bold text-archive-text uppercase tracking-widest flex items-center gap-1.5">
          <ShieldAlert className="w-3.5 h-3.5 text-archive-amber" /> SEVERE JETSAM HAZARDS & MITIGATIONS
        </h3>

        <div className="space-y-4">
          <div className="flex gap-3 items-start">
            <div className="bg-[#2D3136]/50 text-archive-bronze p-1.5 rounded border border-archive-border mt-0.5">
              <Zap className="w-4 h-4 text-archive-bronze" />
            </div>
            <div className="space-y-0.5">
              <h4 className="text-xs font-serif font-bold text-archive-text">Preventing Jetsam (OOM) Crashes</h4>
              <p className="text-[10px] text-archive-text-muted leading-relaxed font-sans">
                iOS terminates host threads exceeding 55% memory. To prevent this during denoising, load the CLIP Text Encoder and VAE Decoder lazily. Release CLIP buffers entirely from Unified RAM immediately before allocating uncompressed UNet weights.
              </p>
            </div>
          </div>

          <div className="flex gap-3 items-start">
            <div className="bg-[#2D3136]/50 text-archive-bronze p-1.5 rounded border border-archive-border mt-0.5">
              <Layers className="w-4 h-4 text-archive-bronze" />
            </div>
            <div className="space-y-0.5">
              <h4 className="text-xs font-serif font-bold text-archive-text">Ahead-of-Time (AOT) Compilation</h4>
              <p className="text-[10px] text-archive-text-muted leading-relaxed font-sans">
                Compiling raw <code className="font-mono text-archive-bronze bg-[#0F1012] px-1 rounded text-[9.5px]">.mlmodel</code> graphs on-device can exceed 5 minutes and cause significant thermal throttling. Sourced models are pre-compiled to <code className="font-mono text-archive-bronze bg-[#0F1012] px-1 rounded text-[9.5px]">.mlmodelc</code> formats using macOS coremltools, zipped and served from repositories.
              </p>
            </div>
          </div>

          <div className="flex gap-3 items-start">
            <div className="bg-[#2D3136]/50 text-archive-bronze p-1.5 rounded border border-archive-border mt-0.5">
              <CheckCircle className="w-4 h-4 text-archive-bronze" />
            </div>
            <div className="space-y-0.5">
              <h4 className="text-xs font-serif font-bold text-archive-text">URLSession Background Downloading</h4>
              <p className="text-[10px] text-archive-text-muted leading-relaxed font-sans">
                Model sizes are multi-gigabyte files. If a user backgrounds the app, iOS suspends standard threads instantly. Utilizing <code className="font-mono text-archive-bronze bg-[#0F1012] px-1 rounded text-[9.5px]">URLSessionConfiguration.background(withIdentifier:)</code> ensures the download pipeline continues in an isolated daemon system.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* CoreML Pipeline Flow */}
      <div className="p-4 bg-[#0F1012] rounded-lg border border-archive-border space-y-2.5">
        <h4 className="text-xs font-serif font-bold text-archive-text flex items-center gap-1.5">
          <CoreMlicon className="w-3.5 h-3.5 text-archive-bronze" /> Model Execution Pipeline Flow
        </h4>
        <div className="flex items-center justify-between text-[9px] text-archive-text-muted text-center font-mono py-1">
          <div className="px-2.5 py-1.5 bg-archive-card rounded border border-archive-border">
            CLIP encoder
            <span className="block text-[8px] text-archive-bronze-muted uppercase font-bold tracking-wider mt-0.5">semantic text</span>
          </div>
          <ChevronRight className="w-3.5 h-3.5 text-archive-bronze-muted" />
          <div className="px-2.5 py-1.5 bg-archive-card rounded border border-archive-border">
            UNet / DiT Graph
            <span className="block text-[8px] text-archive-bronze-muted uppercase font-bold tracking-wider mt-0.5">denoise loop</span>
          </div>
          <ChevronRight className="w-3.5 h-3.5 text-archive-bronze-muted" />
          <div className="px-2.5 py-1.5 bg-archive-card rounded border border-archive-border">
            VAE Decoder
            <span className="block text-[8px] text-archive-bronze-muted uppercase font-bold tracking-wider mt-0.5">latent output</span>
          </div>
        </div>
        <p className="text-[9.5px] text-archive-text-muted leading-relaxed block font-sans">
          *Engine Note: Unified RAM allows Apple GPU cores and the Neural Engine (ANE) to share latent tensor memory directly, eliminating physical copy cycles.*
        </p>
      </div>
    </div>
  );
}
