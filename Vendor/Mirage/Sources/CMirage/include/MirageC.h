//
//  MirageC.h
//  Public C ABI for the Kiln-Image / Mirage native engine.
//
//  This is the vendored app-integration header for the prebuilt
//  `sdcpp.xcframework` (sd.cpp + ggml + Metal + MirageC.cpp). Swift imports
//  this module (`import CMirage`) through `module.modulemap`.
//
//  Memory ownership rules (mirrors MirageC.cpp):
//    - `mirage_ctx` is heap-allocated; freed by `mirage_ctx_free`.
//    - `mirage_image` and its `pixels` buffer are heap-allocated; freed by
//      `mirage_free_image`.
//    - Strings inside `mirage_model_paths` / `mirage_gen_params` are borrowed
//      from the caller and must outlive the call.
//

#ifndef MIRAGEC_H
#define MIRAGEC_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// MARK: - Types

/// Opaque engine context, owning a loaded `sd_ctx`.
typedef struct mirage_ctx mirage_ctx;

/// File-system locations for the model files the engine loads. Every field is
/// borrowed from the caller and must outlive the `mirage_ctx_create` call.
///
/// `diffusion_model_path` is the diffusion-transformer checkpoint
/// (`diffusion.gguf` / `z-image-turbo-*.gguf` for Z-Image, etc.).
/// `model_path` is an optional full single-file checkpoint (A1111-style
/// `.safetensors`/`.ckpt`) that bundles UNet + CLIP + VAE; when set it takes
/// precedence over `diffusion_model_path`. `vae_path` and `llm_path` are the
/// optional VAE and text-encoder weights.
typedef struct mirage_model_paths {
    const char* diffusion_model_path;
    const char* model_path;
    const char* vae_path;
    const char* llm_path;
} mirage_model_paths;

/// Inputs to one image-generation call. All strings are borrowed from the
/// caller and must outlive the `mirage_generate` call.
typedef struct mirage_gen_params {
    const char* prompt;
    const char* negative_prompt;
    int32_t width;
    int32_t height;
    int32_t steps;
    float cfg_scale;
    int64_t seed;
    int32_t batch_size;
} mirage_gen_params;

/// A generated RGBA/RGB image. `pixels` holds `width * height * channels`
/// bytes and is freed by `mirage_free_image`.
typedef struct mirage_image {
    int32_t width;
    int32_t height;
    int32_t channels;
    uint8_t* pixels;
} mirage_image;

/// Progress callback invoked once per denoising step. `step` is 1-indexed,
/// `steps` is the configured total, `time_s` is seconds since the previous
/// step. `user_data` is the opaque pointer passed to
/// `mirage_set_progress_callback`.
typedef void (*mirage_progress_cb)(int step, int steps, float time_s, void* user_data);

// MARK: - Engine lifetime

/// Create an engine context and load the model weights. Returns NULL (and sets
/// a retrievable error via `mirage_last_error`) if the weights fail to load.
mirage_ctx* mirage_ctx_create(const mirage_model_paths* paths);

/// Free an engine context and its loaded weights. Safe to pass NULL.
void mirage_ctx_free(mirage_ctx* ctx);

// MARK: - Generation

/// Generate one image synchronously. Returns NULL on failure; check
/// `mirage_last_error` for the reason. The returned image must be released
/// with `mirage_free_image`.
mirage_image* mirage_generate(mirage_ctx* ctx, const mirage_gen_params* params);

/// Free an image produced by `mirage_generate`. Safe to pass NULL.
void mirage_free_image(mirage_image* img);

// MARK: - Diagnostics

/// Thread-local, human-readable message describing the last failed load or
/// generation (including captured sd.cpp / ggml error lines). Pointer is only
/// valid until the next Mirage call on the same thread.
const char* mirage_last_error(void);

/// Version string of the embedded native library, e.g. "0.2.0".
const char* mirage_version(void);

// MARK: - Progress

/// Install (or clear, with NULL) the global progress callback fired once per
/// denoising step on the engine's sampling thread.
void mirage_set_progress_callback(mirage_progress_cb cb, void* user_data);

#ifdef __cplusplus
}
#endif

#endif /* MIRAGEC_H */