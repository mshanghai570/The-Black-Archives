//
//  MirageC.cpp
//  Thin wrapper around stable-diffusion.cpp's C++ API, exposed via the
//  C ABI declared in MirageC.h.
//
//  Memory ownership rules:
//    - `mirage_ctx` is heap-allocated; freed by `mirage_ctx_free`.
//    - `mirage_image` and its `pixels` buffer are heap-allocated; freed by
//      `mirage_free_image`.
//    - Strings inside `mirage_model_paths` / `mirage_gen_params` are borrowed
//      from the caller and must outlive the call (they're not retained).
//

#include "MirageC.h"

// stable-diffusion.cpp pulls in <stable-diffusion.h> which declares the
// `sd_ctx_t` opaque type and the `new_sd_ctx`, `txt2img`, etc. entry points.
#include "stable-diffusion.h"
#include "ggml.h"

#include <cstring>
#include <cstdlib>
#include <string>
#include <vector>
#include <mutex>
#include <utility>
#include <fstream>

// MARK: - Thread-local error buffer

namespace {

thread_local std::string g_last_error;

// Rolling buffer of the most recent native sd.cpp / ggml ERROR and WARN
// lines. `mirage_last_error()` returns these so callers see the *actual*
// reason a load or generation failed instead of the generic fallback
// string. Thread-local because `new_sd_ctx` / `generate_image` run
// synchronously on the calling thread and the log callbacks fire there.
thread_local std::vector<std::string> g_captured_lines;

void set_last_error(const char* msg) {
    g_last_error = msg ? msg : "";
}

void reset_captured_lines() {
    g_captured_lines.clear();
    g_last_error.clear();
}

void capture_line(const char* text) {
    if (!text || !*text) return;
    std::string line(text);
    while (!line.empty() && (line.back() == '\n' || line.back() == '\r')) {
        line.pop_back();
    }
    if (line.empty()) return;
    g_captured_lines.push_back(std::move(line));
    if (g_captured_lines.size() > 12) {
        g_captured_lines.erase(g_captured_lines.begin());
    }
}

// Pre-flight sanity check of a .safetensors file header, mirroring the
// (silent) header-length validation in sd-cpp's safetensors_io.cpp. A
// truncated or corrupted download fails here with a *specific* message
// instead of the generic "new_sd_ctx returned NULL".
bool check_safetensors_header(const char* path, std::string& reason) {
    std::ifstream f(path, std::ios::binary);
    if (!f) {
        reason = "cannot open file";
        return false;
    }
    f.seekg(0, std::ios::end);
    const std::streamoff file_size = f.tellg();
    if (file_size < 8) {
        reason = "file too small for a safetensors header";
        return false;
    }
    f.seekg(0, std::ios::beg);
    uint64_t header_size = 0;
    f.read(reinterpret_cast<char*>(&header_size), 8);
    // All supported platforms (Apple Silicon, x86_64) are little-endian, so
    // the raw bytes already read as the little-endian u64 safetensors uses.
    if (header_size <= 2) {
        reason = "header length (" + std::to_string(header_size) + ") implausibly small";
        return false;
    }
    if (header_size > static_cast<uint64_t>(file_size - 8)) {
        reason = "header length (" + std::to_string(header_size) +
                 ") exceeds file size (" + std::to_string(static_cast<int64_t>(file_size)) + ")";
        return false;
    }
    f.seekg(8, std::ios::beg);
    char c = 0;
    f.read(&c, 1);
    if (c != '{') {
        reason = "header does not start with '{' (got 0x" +
                 std::to_string(static_cast<unsigned char>(c)) + ")";
        return false;
    }
    return true;
}

} // namespace

// MARK: - Engine context

struct mirage_ctx {
    sd_ctx_t* sd = nullptr;
};

namespace {

// Funnel every sd.cpp / ggml log line into the iOS device console with a
// recognisable prefix. Without this, GGML's error logs (compile failures,
// shape mismatches, etc.) go to plain stderr and get lost in the noise
// from sd.cpp's progress bars on iPhone.
void mirage_sd_log_cb(enum sd_log_level_t level, const char* text, void* /*data*/) {
    if (!text) return;
    if (level == SD_LOG_ERROR || level == SD_LOG_WARN) {
        capture_line(text);
    }
    const char* tag = "info";
    switch (level) {
        case SD_LOG_ERROR: tag = "ERR "; break;
        case SD_LOG_WARN:  tag = "WARN"; break;
        case SD_LOG_INFO:  tag = "info"; break;
        case SD_LOG_DEBUG: tag = "dbg "; break;
    }
    fprintf(stderr, "[mirage sd %s] %s%s", tag, text,
            (text[0] && text[strlen(text)-1] == '\n') ? "" : "\n");
    fflush(stderr);
}

void mirage_ggml_log_cb(enum ggml_log_level level, const char* text, void* /*data*/) {
    if (!text) return;
    if (level == GGML_LOG_LEVEL_ERROR || level == GGML_LOG_LEVEL_WARN) {
        capture_line(text);
    }
    const char* tag = "info";
    switch (level) {
        case GGML_LOG_LEVEL_ERROR: tag = "ERR "; break;
        case GGML_LOG_LEVEL_WARN:  tag = "WARN"; break;
        case GGML_LOG_LEVEL_INFO:  tag = "info"; break;
        case GGML_LOG_LEVEL_DEBUG: tag = "dbg "; break;
        default: break;
    }
    fprintf(stderr, "[mirage ggml %s] %s%s", tag, text,
            (text[0] && text[strlen(text)-1] == '\n') ? "" : "\n");
    fflush(stderr);
}

bool g_log_cb_installed = false;

} // namespace

extern "C" mirage_ctx* mirage_ctx_create(const mirage_model_paths* paths) {
    if (!paths || (!paths->diffusion_model_path && !paths->model_path)) {
        set_last_error("mirage_ctx_create: diffusion_model_path or model_path is required");
        return nullptr;
    }

    reset_captured_lines();

    if (!g_log_cb_installed) {
        sd_set_log_callback(mirage_sd_log_cb, nullptr);
        ggml_log_set(mirage_ggml_log_cb, nullptr);
        g_log_cb_installed = true;
    }

    // Build a default sd_ctx_params and override only what we expose.
    sd_ctx_params_t p;
    sd_ctx_params_init(&p);
    // Full single-file checkpoints (A1111 .safetensors/.ckpt) must go through
    // `model_path`: sd.cpp loads those with NO name prefix, so the embedded
    // CLIP (cond_stage_model.*) and VAE (first_stage_model.*) tensors keep
    // their names. Routing them through `diffusion_model_path` would prepend
    // `model.diffusion_model.` and the load fails (architecture detection or
    // missing CLIP/VAE tensors). UNet-only weights still use
    // `diffusion_model_path` below.
    if (paths->model_path) {
        p.model_path = paths->model_path;
    } else {
        p.diffusion_model_path = paths->diffusion_model_path;
    }
    if (paths->vae_path) { p.vae_path = paths->vae_path; }
    if (paths->llm_path) { p.llm_path = paths->llm_path; }

    // Memory + speed tuning. Read the inline notes — each flag is the result
    // of a real iOS-only failure mode (jetsam, missing kernels, dangling
    // freed params on second generation, etc.).
    //
    // `enable_mmap = true`: cuts peak load memory from ~2× weights (read +
    // upload) to ~1× (lazily paged-in working set). Required on iPhone or
    // jetsam kills the app during weight load.
    //
    // `offload_params_to_cpu = false`: keeps diffusion params resident in
    // Metal buffers for the lifetime of the engine. With mmap on, the path
    // goes through `buffer_from_host_ptr` (zero-copy on Apple Silicon's
    // unified memory) so no extra footprint vs offload=true, but per-op
    // sampling avoids the CPU↔GPU copy and runs 3-5× faster.
    //
    // `keep_vae_on_cpu = false`: lets the VAE decode run on the GPU. CPU
    // decode is 30-60s per image at 768², GPU is a few seconds.
    //
    // `keep_clip_on_cpu = true`: the text encoder (Qwen3-4B for Z-Image,
    // T5-XXL for SD3/Flux) is ~2 GB on GPU; keeping it on CPU saves that
    // budget for the diffusion model. Text encoding runs once at the start
    // of each generation so the CPU-side latency is hidden by the much
    // longer sampling phase.
    //
    // `free_params_immediately = false`: sd.cpp's default is `true`, which
    // releases the diffusion-model param tensors at the end of every
    // `generate_image` call. The next generation against the same engine
    // dereferences the now-freed pointers and crashes. We hold them for
    // the lifetime of the `sd_ctx`; the engine actor caches per-modelId
    // and HaploAI explicitly unloads on memory pressure, so we control
    // lifetime up the stack.
    //
    // `diffusion_flash_attn = true` + `diffusion_conv_direct = true`:
    // reduces attention + conv working memory.
    // Stability over speed on iPhone. The two flips below were tried and
    // crashed at ~78% (late-sample / VAE-decode handoff) — almost certainly
    // jetsam: with offload_params_to_cpu=false the full ~4 GB diffusion
    // weight set lives on the GPU heap simultaneously with the activations
    // and (if keep_vae_on_cpu=false) the VAE, and the peak exceeds the
    // increased-memory-limit cap. Returning to the proven-stable config.
    //   p.offload_params_to_cpu = false;   // ← faster but crashes
    //   p.keep_vae_on_cpu       = false;   // ← faster decode but adds GPU pressure
    p.enable_mmap             = true;
    p.offload_params_to_cpu   = true;
    p.keep_clip_on_cpu        = true;
    p.keep_control_net_on_cpu = true;
    p.keep_vae_on_cpu         = true;
    p.diffusion_flash_attn    = true;
    p.diffusion_conv_direct   = true;
    // Keep params alive across multiple `generate_image` calls. Without this,
    // sd.cpp's default frees them at the end of each generation and the next
    // call dereferences freed GPU buffers → second-image crash.
    p.free_params_immediately = false;

    // Log the resolved params before handing them to sd.cpp so we can verify
    // from the device console which knobs actually took effect.
    if (char* dump = sd_ctx_params_to_str(&p)) {
        fprintf(stderr, "[mirage] sd_ctx_params resolved:\n%s\n", dump);
        free(dump);
    }

    // Pre-flight check the primary model file before handing it to sd.cpp.
    // The vendored safetensors parser rejects a truncated/corrupt header
    // *silently* and surfaces only as "new_sd_ctx returned NULL"; checking
    // here turns that into a specific, actionable message.
    const char* primary = paths->model_path ? paths->model_path : paths->diffusion_model_path;
    if (primary && primary[0]) {
        const size_t len = strlen(primary);
        const bool is_safetensors = len >= 12 && strcmp(primary + (len - 12), ".safetensors") == 0;
        if (is_safetensors) {
            std::string reason;
            if (!check_safetensors_header(primary, reason)) {
                set_last_error(("model file failed safetensors header check: " +
                                std::string(primary) + " — " + reason).c_str());
                return nullptr;
            }
        }
    }

    sd_ctx_t* sd = new_sd_ctx(&p);
    if (!sd) {
        set_last_error("new_sd_ctx returned NULL — model failed to load (check paths + quantization compatibility)");
        return nullptr;
    }

    auto* ctx = new mirage_ctx();
    ctx->sd = sd;
    return ctx;
}

extern "C" void mirage_ctx_free(mirage_ctx* ctx) {
    if (!ctx) return;
    if (ctx->sd) free_sd_ctx(ctx->sd);
    delete ctx;
}

// MARK: - Generation

extern "C" mirage_image* mirage_generate(mirage_ctx* ctx, const mirage_gen_params* params) {
    if (!ctx || !ctx->sd) {
        set_last_error("mirage_generate: invalid context");
        return nullptr;
    }
    if (!params || !params->prompt) {
        set_last_error("mirage_generate: prompt is required");
        return nullptr;
    }

    reset_captured_lines();

    sd_img_gen_params_t g;
    sd_img_gen_params_init(&g);
    g.prompt = params->prompt;
    g.negative_prompt = params->negative_prompt ? params->negative_prompt : "";
    g.width = params->width  > 0 ? params->width  : 1024;
    g.height = params->height > 0 ? params->height : 1024;
    g.sample_params.sample_steps = params->steps > 0 ? params->steps : 9;
    g.sample_params.guidance.txt_cfg = params->cfg_scale > 0 ? params->cfg_scale : 1.0f;
    g.sample_params.sample_method = EULER_SAMPLE_METHOD;
    g.seed = params->seed;
    g.batch_count = params->batch_size > 0 ? params->batch_size : 1;

    sd_image_t* result = generate_image(ctx->sd, &g);
    if (!result) {
        set_last_error("generate_image returned NULL");
        return nullptr;
    }

    auto* img = static_cast<mirage_image*>(std::malloc(sizeof(mirage_image)));
    if (!img) {
        set_last_error("mirage_generate: out of memory allocating image struct");
        for (int i = 0; i < g.batch_count; ++i) {
            if (result[i].data) std::free(result[i].data);
        }
        std::free(result);
        return nullptr;
    }

    img->width = result[0].width;
    img->height = result[0].height;
    img->channels = result[0].channel;
    const size_t bytes = static_cast<size_t>(img->width) *
                         static_cast<size_t>(img->height) *
                         static_cast<size_t>(img->channels);
    img->pixels = static_cast<uint8_t*>(std::malloc(bytes));
    if (!img->pixels) {
        set_last_error("mirage_generate: out of memory allocating pixel buffer");
        for (int i = 0; i < g.batch_count; ++i) {
            if (result[i].data) std::free(result[i].data);
        }
        std::free(result);
        std::free(img);
        return nullptr;
    }
    std::memcpy(img->pixels, result[0].data, bytes);

    for (int i = 0; i < g.batch_count; ++i) {
        if (result[i].data) std::free(result[i].data);
    }
    std::free(result);

    return img;
}

extern "C" void mirage_free_image(mirage_image* img) {
    if (!img) return;
    if (img->pixels) std::free(img->pixels);
    std::free(img);
}

// MARK: - Diagnostics

extern "C" const char* mirage_last_error(void) {
    if (!g_captured_lines.empty()) {
        std::string joined;
        for (const auto& line : g_captured_lines) {
            joined += line;
            joined += "\n";
        }
        g_last_error = std::move(joined);
    }
    return g_last_error.c_str();
}

extern "C" const char* mirage_version(void) {
    return "0.2.0";
}

// MARK: - Progress callback

namespace {

mirage_progress_cb g_progress_cb = nullptr;
void*              g_progress_user_data = nullptr;

void mirage_sd_progress_trampoline(int step, int steps, float time_s, void* /*data*/) {
    if (g_progress_cb) {
        g_progress_cb(step, steps, time_s, g_progress_user_data);
    }
}

} // namespace

extern "C" void mirage_set_progress_callback(mirage_progress_cb cb, void* user_data) {
    g_progress_cb = cb;
    g_progress_user_data = user_data;
    // sd.cpp accepts NULL to clear too.
    sd_set_progress_callback(cb ? mirage_sd_progress_trampoline : nullptr, nullptr);
}
