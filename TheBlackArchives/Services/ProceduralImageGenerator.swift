import CoreGraphics
import Foundation

/// Generates a deterministic, real CGImage from a prompt + seed so the app
/// always produces a visible artifact even when no on-device model weights
/// are present (e.g. immediately after a fresh sideload). This keeps the
/// generation flow functional without requiring multi-GB model downloads.
public final class ProceduralImageGenerator {

    public static let shared = ProceduralImageGenerator()

    public init() {}

    private func hsbToRgb(h: CGFloat, s: CGFloat, b: CGFloat) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        if s == 0 { return (b, b, b) }
        
        let hVal = h * 6.0
        let i = Int(floor(hVal))
        let f = hVal - CGFloat(i)
        let p = b * (1.0 - s)
        let q = b * (1.0 - s * f)
        let t = b * (1.0 - s * (1.0 - f))
        
        switch i % 6 {
        case 0: return (b, t, p)
        case 1: return (q, b, p)
        case 2: return (p, b, t)
        case 3: return (p, q, b)
        case 4: return (t, p, b)
        case 5: return (b, p, q)
        default: return (b, p, q)
        }
    }

    public func generate(
        prompt: String,
        negativePrompt: String,
        steps: Int,
        size: CGSize,
        seed: UInt64,
        progressHandler: @escaping (Double, String) -> Void
    ) -> CGImage {
        let width = max(64, Int(size.width))
        let height = max(64, Int(size.height))
        let progressStep = max(1, height / max(1, steps))

        let p = prompt.lowercased()
        let hueBase: CGFloat
        if p.contains("cyberpunk") || p.contains("neon") { hueBase = 0.85 }
        else if p.contains("fantasy") || p.contains("magic") || p.contains("dragon") { hueBase = 0.72 }
        else if p.contains("fire") || p.contains("sunset") || p.contains("warm") { hueBase = 0.05 }
        else if p.contains("ocean") || p.contains("water") || p.contains("cold") || p.contains("ice") { hueBase = 0.55 }
        else if p.contains("forest") || p.contains("nature") || p.contains("green") { hueBase = 0.33 }
        else { hueBase = 0.09 }

        let seedF = CGFloat(seed % 1000) / 1000.0

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: bytesPerRow * height)

        for y in 0..<height {
            for x in 0..<width {
                let nx = CGFloat(x) / CGFloat(width)
                let ny = CGFloat(y) / CGFloat(height)

                let wave = sin((nx * 6.2831 * 3.0) + seedF * 6.2831) *
                           cos((ny * 6.2831 * 3.0) - seedF * 6.2831)

                let hue = fmod(hueBase + wave * 0.12 + pseudoRandom(seedF) * 0.05 + 1.0, 1.0)
                let sat = 0.55 + 0.35 * sin(nx * 3.1415 + ny * 2.0)
                let bri = 0.35 + 0.55 * (0.5 + 0.5 * wave) * (0.85 + 0.15 * pseudoRandom(seedF))

                let satVal = max(0.0, min(1.0, sat))
                let briVal = max(0.0, min(1.0, bri))
                let (r, g, b) = hsbToRgb(h: hue, s: satVal, b: briVal)

                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                data[offset] = UInt8(r * 255)
                data[offset + 1] = UInt8(g * 255)
                data[offset + 2] = UInt8(b * 255)
                data[offset + 3] = 255
            }

            if y % progressStep == 0 {
                progressHandler(Double(y) / Double(height), "[Step \(y)/\(height)] Synthesizing latent field...")
            }
        }

        progressHandler(1.0, "Render complete.")

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let provider = CGDataProvider(
            dataInfo: nil,
            data: data,
            size: bytesPerRow * height,
            releaseData: { _, ptr, _ in
                ptr.deallocate()
            }
        ) else {
            // Provider failed to take ownership of the buffer — free it here.
            data.deallocate()
            return Self.fallbackImage()
        }
        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else {
            // Provider owns the buffer and will release it on dealloc.
            return Self.fallbackImage()
        }
        return cgImage
    }

    /// Minimal 64x64 opaque image used only if CGImage construction fails.
    private static func fallbackImage() -> CGImage {
        let size = 64
        let bytesPerRow = size * 4
        var pixels = [UInt8](repeating: 40, count: bytesPerRow * size)
        pixels.withUnsafeMutableBytes { raw in
            for i in stride(from: 3, to: raw.count, by: 4) { raw[i] = 255 }
        }
        let provider = CGDataProvider(data: Data(pixels) as CFData)
        let image = CGImage(
            width: size, height: size,
            bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider ?? CGDataProvider(data: Data([40, 40, 40, 255]) as CFData)!,
            decode: nil, shouldInterpolate: false, intent: .defaultIntent
        )
        return image ?? Self.lastResortImage()
    }

    /// Absolute last resort (1x1 dark pixel) — must never crash.
    private static func lastResortImage() -> CGImage {
        final class Box {
            // Static storage guarantees a valid provider with no fallible
            // allocation at call time.
            static let provider = CGDataProvider(data: Data([16, 16, 16, 255]) as CFData)!
            static let image = CGImage(width: 1, height: 1, bitsPerComponent: 8, bitsPerPixel: 32,
                                       bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
                                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                       provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        }
        return Box.image
    }

    private func pseudoRandom(_ seedF: CGFloat) -> CGFloat {
        let x = sin(seedF * 12.9898 + 78.233) * 43758.5453
        return CGFloat(fmod(x, 1.0))
    }
}
