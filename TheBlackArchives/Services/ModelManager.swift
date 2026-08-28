import Foundation

public final class ModelManager {
    public static let shared = ModelManager()
    
    private let fileManager = FileManager.default
    
    public func getLocalModelURL(id: String) -> URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("LocalModels/\(id)")
    }
    
    public func checkModelExists(id: String) -> Bool {
        let url = getLocalModelURL(id: id)
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { return false }

        if isDir.boolValue {
            // Directory layout (downloads + folder imports): require at least
            // one real, non-empty weight file. A folder holding only `.part`
            // resume partials or zero-byte placeholders is NOT installed —
            // otherwise a stale partial download would be marked "installed"
            // and fed straight into the generator.
            let allowedExts = ["gguf", "safetensors", "ckpt", "bin", "mlmodelc", "mlpackage", "mlmodel"]
            guard let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
                return false
            }
            return contents.contains { fileURL in
                let ext = fileURL.pathExtension.lowercased()
                guard allowedExts.contains(ext), !fileURL.lastPathComponent.hasSuffix(".part") else { return false }
                var isFile: ObjCBool = false
                _ = fileManager.fileExists(atPath: fileURL.path, isDirectory: &isFile)
                if isFile.boolValue {
                    // CoreML model packages are directories.
                    return ext == "mlmodelc" || ext == "mlpackage"
                }
                let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                guard size > 0 else { return false }
                // A .safetensors with a corrupt header (truncated download, bad
                // chunk splice) is NOT installed — it would fail to load in the
                // engine and block a clean re-download.
                if ext == "safetensors" {
                    return Self.isValidSafetensorsHeader(at: fileURL)
                }
                return true
            }
        }

        // Single-file layout: the path itself is the weight file.
        let ext = url.pathExtension.lowercased()
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        guard ["gguf", "safetensors", "ckpt", "bin", "mlmodelc", "mlpackage", "mlmodel"].contains(ext), size > 0 else {
            return false
        }
        if ext == "safetensors" {
            return Self.isValidSafetensorsHeader(at: url)
        }
        return true
    }

    /// Cheap structural validation of a `.safetensors` file: the first 8 bytes
    /// are a little-endian header length that must be sane (<= file size - 8)
    /// and the header itself must start with '{'. Mirrors the header checks the
    /// native engine performs before it will accept a model — a corrupt file
    /// (truncated download, HTML error page written over the weights, misaligned
    /// chunk splice) fails here with a specific error instead of the generic
    /// native "model failed to load".
    static func isValidSafetensorsHeader(at url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: 8), data.count == 8 else { return false }
        let bytes = [UInt8](data)
        let headerSize = UInt64(bytes[0])
            | (UInt64(bytes[1]) << 8)
            | (UInt64(bytes[2]) << 16)
            | (UInt64(bytes[3]) << 24)
            | (UInt64(bytes[4]) << 32)
            | (UInt64(bytes[5]) << 40)
            | (UInt64(bytes[6]) << 48)
            | (UInt64(bytes[7]) << 56)
        guard headerSize > 2 else { return false }
        let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        guard Int64(headerSize) <= fileSize - 8 else { return false }
        guard let first = try? handle.read(upToCount: 1), first.first == 0x7B else { return false }
        return true
    }
}
