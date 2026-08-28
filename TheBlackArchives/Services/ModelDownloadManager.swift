import Foundation

// MARK: - Progress Model

public struct DownloadProgress: Sendable {
    public let fraction: Double
    public let receivedBytes: Int64
    public let totalBytes: Int64
    public let speedBytesPerSecond: Double
    public let averageSpeedBytesPerSecond: Double
    public let estimatedTimeRemaining: TimeInterval?
    public let activeChunkCount: Int
    public let state: DownloadState

    public init(
        fraction: Double,
        receivedBytes: Int64,
        totalBytes: Int64,
        speedBytesPerSecond: Double,
        averageSpeedBytesPerSecond: Double,
        estimatedTimeRemaining: TimeInterval?,
        activeChunkCount: Int,
        state: DownloadState
    ) {
        self.fraction = fraction
        self.receivedBytes = receivedBytes
        self.totalBytes = totalBytes
        self.speedBytesPerSecond = speedBytesPerSecond
        self.averageSpeedBytesPerSecond = averageSpeedBytesPerSecond
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.activeChunkCount = activeChunkCount
        self.state = state
    }
}

public enum DownloadState: Sendable {
    case queued
    case downloading
    case paused
    case completed
    case failed(Error)
    case cancelled
}

// MARK: - Manager

public final class ModelDownloadManager {
    public typealias ProgressCallback = @Sendable (DownloadProgress) -> Void

    private let session: URLSession
    private let concurrencyLimit: Int

    public init(
        session: URLSession = .shared,
        concurrencyLimit: Int = 6
    ) {
        self.session = session
        self.concurrencyLimit = max(1, min(concurrencyLimit, 8))
    }

    public func download(
        url: URL,
        destination: URL,
        expectedSize: Int64? = nil
    ) -> AsyncThrowingStream<DownloadProgress, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await performDownload(
                        url: url,
                        destination: destination,
                        expectedSize: expectedSize,
                        onProgress: { progress in
                            continuation.yield(progress)
                        }
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}

// MARK: - Private Implementation

private extension ModelDownloadManager {
    private struct Chunk {
        let index: Int
        let range: Range<Int64>
        let tempURL: URL
        let state: ChunkState

        var length: Int64 { Int64(range.count) }
    }

    private enum ChunkState: Equatable {
        case pending
        case partial(Int64)
        case complete
    }

    private actor ProgressAccumulator {
        private let totalSize: Int64
        private var totalReceived: Int64 = 0
        private var startTime: Date = Date()
        private var lastReportTime: Date = Date()
        private var lastReportedBytes: Int64 = 0
        private let onProgress: ProgressCallback

        init(totalSize: Int64, onProgress: @escaping ProgressCallback) {
            self.totalSize = totalSize
            self.onProgress = onProgress
        }

        func report(chunkReceived: Int64, activeChunkCount: Int) {
            totalReceived += chunkReceived
            let now = Date()

            let elapsedSinceStart = now.timeIntervalSince(startTime)
            let elapsedSinceLast = now.timeIntervalSince(lastReportTime)
            let bytesDelta = totalReceived - lastReportedBytes

            let fraction = totalSize > 0 ? Double(totalReceived) / Double(totalSize) : 0.0

            let currentSpeed: Double = {
                guard elapsedSinceLast > 0, bytesDelta > 0 else { return 0 }
                return Double(bytesDelta) / elapsedSinceLast
            }()

            let averageSpeed: Double = {
                guard elapsedSinceStart > 0, totalReceived > 0 else { return 0 }
                return Double(totalReceived) / elapsedSinceStart
            }()

            let remaining = max(totalSize - totalReceived, 0)
            let eta: TimeInterval? = {
                if currentSpeed > 0 { return Double(remaining) / currentSpeed }
                if averageSpeed > 0 { return Double(remaining) / averageSpeed }
                return nil
            }()

            let shouldReport: Bool = {
                if fraction >= 1.0 { return true }
                if elapsedSinceLast >= 0.1 { return true }
                if bytesDelta >= 1 * 1024 * 1024 { return true }
                return false
            }()

            if shouldReport {
                onProgress(DownloadProgress(
                    fraction: fraction,
                    receivedBytes: totalReceived,
                    totalBytes: totalSize,
                    speedBytesPerSecond: currentSpeed,
                    averageSpeedBytesPerSecond: averageSpeed,
                    estimatedTimeRemaining: eta,
                    activeChunkCount: activeChunkCount,
                    state: .downloading
                ))
                lastReportTime = now
                lastReportedBytes = totalReceived
            }
        }

        var averageSpeed: Double {
            let elapsed = Date().timeIntervalSince(startTime)
            guard elapsed > 0, totalReceived > 0 else { return 0 }
            return Double(totalReceived) / elapsed
        }

        func averageSpeed() async -> Double {
            await averageSpeed
        }
    }

    func performDownload(
        url: URL,
        destination: URL,
        expectedSize: Int64?,
        onProgress: @escaping ProgressCallback
    ) async throws {
        if let expectedSize = expectedSize,
           try checkIfAlreadyDownloaded(destination: destination, expectedSize: expectedSize) {
            onProgress(DownloadProgress(
                fraction: 1.0,
                receivedBytes: expectedSize,
                totalBytes: expectedSize,
                speedBytesPerSecond: 0,
                averageSpeedBytesPerSecond: 0,
                estimatedTimeRemaining: 0,
                activeChunkCount: 0,
                state: .completed
            ))
            return
        }

        if let expectedSize = expectedSize {
            let hasSpace = try checkDiskSpace(url: destination.deletingLastPathComponent(), expectedSize: expectedSize)
            guard hasSpace else {
                throw NSError(
                    domain: "ModelDownloadManager",
                    code: -7,
                    userInfo: [NSLocalizedDescriptionKey: "Not enough storage space for this model."]
                )
            }
        }

        let supportsRange: Bool
        do {
            supportsRange = try await detectRangeSupport(url: url)
        } catch {
            supportsRange = false
        }

        if supportsRange {
            try await downloadWithParallelChunks(
                url: url,
                destination: destination,
                expectedSize: expectedSize,
                onProgress: onProgress
            )
        } else {
            try await downloadWithSingleStream(
                url: url,
                destination: destination,
                expectedSize: expectedSize,
                onProgress: onProgress
            )
        }
    }

    func downloadWithParallelChunks(
        url: URL,
        destination: URL,
        expectedSize: Int64?,
        onProgress: @escaping ProgressCallback
    ) async throws {
        let fileSize: Int64
        if let expectedSize = expectedSize, expectedSize > 0 {
            fileSize = expectedSize
        } else {
            fileSize = try await getFileSize(url: url)
        }

        guard fileSize > 0 else {
            throw NSError(
                domain: "ModelDownloadManager",
                code: -8,
                userInfo: [NSLocalizedDescriptionKey: "Remote file size is 0 or unknown."]
            )
        }

        let tempDir = destination.appendingPathExtension("part")
        ensureValidTempDirectory(tempDir: tempDir, url: url, fileSize: fileSize, concurrency: concurrencyLimit)

        let chunkSpecs = calculateChunks(fileSize: fileSize, concurrency: concurrencyLimit)
        let chunks = loadExistingChunks(chunks: chunkSpecs, tempDir: tempDir)

        let accumulator = ProgressAccumulator(totalSize: fileSize, onProgress: onProgress)

        let incomplete = chunks.filter { $0.state != .complete }
        guard !incomplete.isEmpty else {
            try mergeChunks(chunks: chunks, to: destination)
            cleanupTempDirectory(tempDir: tempDir)
            onProgress(DownloadProgress(
                fraction: 1.0,
                receivedBytes: fileSize,
                totalBytes: fileSize,
                speedBytesPerSecond: 0,
                averageSpeedBytesPerSecond: 0,
                estimatedTimeRemaining: 0,
                activeChunkCount: 0,
                state: .completed
            ))
            return
        }

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for chunk in incomplete {
                    group.addTask {
                        try await self.downloadChunkWithRetry(
                            chunk: chunk,
                            url: url,
                            tempDir: tempDir,
                            accumulator: accumulator,
                            activeChunkCount: incomplete.count
                        )
                    }
                }

                do {
                    while try await group.next() != nil {}
                } catch {
                    group.cancelAll()
                    while try await group.next() != nil {}
                    throw error
                }
            }
        } catch {
            cleanupTempDirectory(tempDir: tempDir, keepPartial: true)
            throw error
        }

        let finalChunks = loadExistingChunks(chunks: chunkSpecs, tempDir: tempDir)
        guard finalChunks.allSatisfy({ $0.state == .complete }) else {
            cleanupTempDirectory(tempDir: tempDir, keepPartial: true)
            throw NSError(
                domain: "ModelDownloadManager",
                code: -9,
                userInfo: [NSLocalizedDescriptionKey: "Some download chunks did not complete."]
            )
        }

        try mergeChunks(chunks: finalChunks, to: destination)
        let mergedSize = (try? destination.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        guard mergedSize == fileSize else {
            cleanupTempDirectory(tempDir: tempDir)
            try? FileManager.default.removeItem(at: destination)
            throw NSError(
                domain: "ModelDownloadManager",
                code: -13,
                userInfo: [NSLocalizedDescriptionKey: "Merged file size mismatch (\(mergedSize) of \(fileSize) bytes)."]
            )
        }
        cleanupTempDirectory(tempDir: tempDir, keepPartial: false)

        let averageSpeed = await accumulator.averageSpeed()
        onProgress(DownloadProgress(
            fraction: 1.0,
            receivedBytes: fileSize,
            totalBytes: fileSize,
            speedBytesPerSecond: 0,
            averageSpeedBytesPerSecond: averageSpeed,
            estimatedTimeRemaining: 0,
            activeChunkCount: 0,
            state: .completed
        ))
    }

    func downloadWithSingleStream(
        url: URL,
        destination: URL,
        expectedSize: Int64?,
        onProgress: @escaping ProgressCallback
    ) async throws {
        let partialURL = destination.appendingPathExtension("part")
        var resumeOffset: Int64
        if let attrs = try? FileManager.default.attributesOfItem(atPath: partialURL.path),
           let size = attrs[.size] as? Int64,
           size > 0 {
            resumeOffset = size
        } else {
            resumeOffset = 0
        }

        var request = URLRequest(url: url)
        if resumeOffset > 0 {
            request.setValue("bytes=\(resumeOffset)-", forHTTPHeaderField: "Range")
        }

        var (bytes, response) = try await session.bytes(for: request)
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 416 || (httpResponse.statusCode == 200 && resumeOffset > 0) {
            // 416: the byte we asked for is past the end of the remote file
            // (it changed since the size probe). 200 while resuming: the
            // server ignored the Range header and sent the whole body, which
            // appended at the wrong offset would corrupt the partial. Either
            // way, discard and restart from byte 0.
            try? FileManager.default.removeItem(at: partialURL)
            resumeOffset = 0
            (bytes, response) = try await session.bytes(for: URLRequest(url: url))
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(
                domain: "ModelDownloadManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Download failed with HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)."]
            )
        }

        guard let stream = OutputStream(url: partialURL, append: resumeOffset > 0) else {
            throw NSError(
                domain: "ModelDownloadManager",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Cannot open destination file for writing."]
            )
        }
        stream.open()
        defer { stream.close() }

        let remaining = httpResponse.expectedContentLength
        let totalSize: Int64 = {
            if remaining > 0 { return resumeOffset + remaining }
            if let expected = expectedSize, expected > 0 { return expected }
            return 0
        }()

        let accumulator = ProgressAccumulator(totalSize: totalSize, onProgress: onProgress)
        var received = resumeOffset
        var buffer = Data()
        let chunkSize = 64 * 1024

        for try await byte in bytes {
            buffer.append(byte)
            if buffer.count >= chunkSize {
                try writeBuffer(buffer, to: stream)
                received += Int64(buffer.count)
                await accumulator.report(chunkReceived: Int64(buffer.count), activeChunkCount: 1)
                buffer.removeAll(keepingCapacity: true)
            }
            if Task.isCancelled { throw CancellationError() }
        }

        if !buffer.isEmpty {
            try writeBuffer(buffer, to: stream)
            received += Int64(buffer.count)
            await accumulator.report(chunkReceived: Int64(buffer.count), activeChunkCount: 1)
        }

        stream.close()

        if let expected = expectedSize, expected > 0, received != expected {
            throw NSError(
                domain: "ModelDownloadManager",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Download incomplete (\(received) of \(expected) bytes)."] 
            )
        }

        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: partialURL, to: destination)

        let averageSpeed = await accumulator.averageSpeed()
        onProgress(DownloadProgress(
            fraction: 1.0,
            receivedBytes: received,
            totalBytes: totalSize,
            speedBytesPerSecond: 0,
            averageSpeedBytesPerSecond: averageSpeed,
            estimatedTimeRemaining: 0,
            activeChunkCount: 0,
            state: .completed
        ))
    }

    private func downloadChunkWithRetry(
        chunk: Chunk,
        url: URL,
        tempDir: URL,
        accumulator: ProgressAccumulator,
        activeChunkCount: Int
    ) async throws {
        let tempURL = tempDir.appendingPathComponent("chunk.\(chunk.index)")
        let maxAttempts = 3
        var lastError: Error?

        for attempt in 0..<maxAttempts {
            do {
                // The chunk snapshot is immutable, so its `state` reflects the
                // disk at the time the task was created — NOT what a failed
                // attempt just wrote. Deriving the resume offset from the real
                // file on disk at the start of each attempt keeps retries
                // byte-aligned; using the stale snapshot would append the next
                // range at the wrong offset and permanently corrupt the chunk.
                let resumeOffset = resumeOffsetForChunk(range: chunk.range, tempURL: tempURL)
                let received = try await downloadChunk(
                    url: url,
                    range: chunk.range,
                    to: tempURL,
                    resumeOffset: resumeOffset
                )
                let delta = received - resumeOffset
                if delta > 0 {
                    await accumulator.report(chunkReceived: delta, activeChunkCount: activeChunkCount)
                }
                return
            } catch {
                lastError = error
                if attempt < maxAttempts - 1 {
                    let delay = pow(2.0, Double(attempt))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? NSError(
            domain: "ModelDownloadManager",
            code: -10,
            userInfo: [NSLocalizedDescriptionKey: "Chunk \(chunk.index) failed after retries."]
        )
    }

    /// Byte offset a chunk should resume from, read from disk on demand.
    /// Returns 0 when the chunk file is missing, and resets corrupted
    /// (oversized) chunk files back to a clean state so they re-download
    /// from scratch instead of being spliced together wrongly.
    private func resumeOffsetForChunk(range: Range<Int64>, tempURL: URL) -> Int64 {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: tempURL.path),
              let size = attrs[.size] as? Int64,
              size > 0 else {
            return 0
        }
        guard size < range.count else {
            try? FileManager.default.removeItem(at: tempURL)
            return 0
        }
        return size
    }

    /// Parses a `Content-Range` header of the form `bytes <start>-<end>/<total>`.
    private static func parseContentRange(_ header: String) -> (start: Int64, end: Int64, total: Int64)? {
        let parts = header.split(separator: "/")
        guard parts.count == 2 else { return nil }
        let rangePart = parts[0].split(separator: " ")
        guard rangePart.count == 2, rangePart[0] == "bytes" else { return nil }
        let bounds = rangePart[1].split(separator: "-")
        guard bounds.count == 2,
              let start = Int64(bounds[0]),
              let end = Int64(bounds[1]) else { return nil }
        let total = Int64(parts[1]) ?? -1
        return (start, end, total)
    }

    private func downloadChunk(
        url: URL,
        range: Range<Int64>,
        to tempURL: URL,
        resumeOffset: Int64
    ) async throws -> Int64 {
        let targetStart = range.lowerBound + resumeOffset
        guard targetStart < range.upperBound else {
            return Int64(range.count)
        }

        var request = URLRequest(url: url)
        request.setValue("bytes=\(targetStart)-\(range.upperBound - 1)", forHTTPHeaderField: "Range")

        let (bytes, response) = try await session.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "ModelDownloadManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Chunk download returned no HTTP response."]
            )
        }

        if httpResponse.statusCode == 416 {
            // The byte we asked for is past the end of the remote file (the
            // file changed since the size probe). Discard the partial and
            // restart the chunk from its beginning.
            try? FileManager.default.removeItem(at: tempURL)
            return try await downloadChunk(url: url, range: range, to: tempURL, resumeOffset: 0)
        }

        // A ranged request must be answered with 206. A 200 means the server
        // ignored the Range header and sent the whole file; writing that at
        // the resume offset would silently corrupt the chunk.
        guard httpResponse.statusCode == 206 else {
            throw NSError(
                domain: "ModelDownloadManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Chunk download failed: expected HTTP 206 Partial Content, got \(httpResponse.statusCode)."]
            )
        }

        // The server must answer with a Content-Range whose start byte is
        // exactly what we asked for. If a CDN ignored the requested start and
        // returned bytes from a different offset, appending them here would
        // silently corrupt the chunk — surface it so the retry resets.
        if let contentRange = httpResponse.value(forHTTPHeaderField: "Content-Range") {
            guard let parsed = Self.parseContentRange(contentRange),
                  parsed.start == targetStart else {
                try? FileManager.default.removeItem(at: tempURL)
                throw NSError(
                    domain: "ModelDownloadManager",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Chunk download returned Content-Range '\(contentRange)' but requested start byte \(targetStart). Restarting the chunk."]
                )
            }
        }

        guard let stream = OutputStream(url: tempURL, append: resumeOffset > 0) else {
            throw NSError(
                domain: "ModelDownloadManager",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Cannot open chunk temp file for writing."]
            )
        }
        stream.open()
        defer { stream.close() }

        let expectedThisAttempt = range.upperBound - targetStart
        var received = resumeOffset
        var buffer = Data()
        let chunkSize = 64 * 1024

        for try await byte in bytes {
            buffer.append(byte)
            if buffer.count >= chunkSize {
                try writeBuffer(buffer, to: stream)
                received += Int64(buffer.count)
                buffer.removeAll(keepingCapacity: true)
            }
            if Task.isCancelled { throw CancellationError() }
        }

        if !buffer.isEmpty {
            try writeBuffer(buffer, to: stream)
            received += Int64(buffer.count)
        }

        // A clean stream end that delivered fewer bytes than the requested
        // sub-range means the body was truncated mid-chunk. Surface it so the
        // retry resumes from the true on-disk position.
        let writtenThisAttempt = received - resumeOffset
        guard writtenThisAttempt == expectedThisAttempt else {
            throw NSError(
                domain: "ModelDownloadManager",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Chunk download incomplete (\(writtenThisAttempt) of \(expectedThisAttempt) bytes)."]
            )
        }

        return received
    }

    private func mergeChunks(chunks: [Chunk], to destination: URL) throws {
        let outputStream = OutputStream(url: destination, append: false)!
        outputStream.open()
        defer { outputStream.close() }

        let bufferSize = 1 * 1024 * 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        let sorted = chunks.sorted(by: { $0.range.lowerBound < $1.range.lowerBound })
        for chunk in sorted {
            guard let inputStream = InputStream(url: chunk.tempURL) else {
                throw NSError(
                    domain: "ModelDownloadManager",
                    code: -5,
                    userInfo: [NSLocalizedDescriptionKey: "Cannot open chunk file for reading."]
                )
            }
            inputStream.open()
            defer { inputStream.close() }

            while inputStream.hasBytesAvailable {
                let read = inputStream.read(buffer, maxLength: bufferSize)
                if read <= 0 { break }

                var offset = 0
                while offset < read {
                    let written = outputStream.write(buffer.advanced(by: offset), maxLength: read - offset)
                    if written <= 0 {
                        throw NSError(
                            domain: "ModelDownloadManager",
                            code: -6,
                            userInfo: [NSLocalizedDescriptionKey: "Write failed while merging chunks."]
                        )
                    }
                    offset += written
                }
            }
        }
    }

    func detectRangeSupport(url: URL) async throws -> Bool {
        var request = URLRequest(url: url)
        request.setValue("bytes=0-0", forHTTPHeaderField: "Range")
        request.httpMethod = "HEAD"
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        return httpResponse.statusCode == 206
    }

    func getFileSize(url: URL) async throws -> Int64 {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(
                domain: "ModelDownloadManager",
                code: -11,
                userInfo: [NSLocalizedDescriptionKey: "Cannot determine remote file size."]
            )
        }
        let length = httpResponse.expectedContentLength
        guard length >= 0 else {
            throw NSError(
                domain: "ModelDownloadManager",
                code: -12,
                userInfo: [NSLocalizedDescriptionKey: "Remote file size is unknown."]
            )
        }
        return Int64(length)
    }

    func checkDiskSpace(url: URL, expectedSize: Int64) throws -> Bool {
        let resourceValues = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        let available = resourceValues.volumeAvailableCapacityForImportantUsage ?? 0
        let safetyMargin = max(100 * 1024 * 1024, expectedSize / 10)
        return available >= expectedSize + safetyMargin
    }

    func checkIfAlreadyDownloaded(destination: URL, expectedSize: Int64) throws -> Bool {
        guard FileManager.default.fileExists(atPath: destination.path) else { return false }
        let actualSize = (try? destination.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        return actualSize == expectedSize
    }

    private func calculateChunks(fileSize: Int64, concurrency: Int) -> [Chunk] {
        guard fileSize > 0 else { return [] }

        let minChunkSize: Int64 = 16 * 1024 * 1024
        let maxChunkSize: Int64 = 256 * 1024 * 1024

        let ideal = fileSize / max(Int64(concurrency), 1)
        let chunkSize = min(maxChunkSize, max(minChunkSize, ideal))
        let count = Int((fileSize + chunkSize - 1) / chunkSize)
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)

        var chunks: [Chunk] = []
        var offset: Int64 = 0
        for index in 0..<count {
            let size = min(chunkSize, fileSize - offset)
            let tempURL = tempDir.appendingPathComponent("chunk.\(index)")
            chunks.append(Chunk(index: index, range: offset..<(offset + size), tempURL: tempURL, state: .pending))
            offset += size
        }
        return chunks
    }

    /// Validates the resume directory before reusing partial chunks.
    ///
    /// Partial chunks are only safe to resume when they were produced by the
    /// same download (same URL, file size and chunk layout). Anything else — a
    /// stale `.part` dir from an earlier failure, a remote file that changed,
    /// or a different concurrency setting — is wiped so resume can never
    /// splice bytes from two different downloads into one corrupt file.
    private func ensureValidTempDirectory(tempDir: URL, url: URL, fileSize: Int64, concurrency: Int) {
        let markerURL = tempDir.appendingPathComponent(".download-meta.json")
        if FileManager.default.fileExists(atPath: tempDir.path) {
            var isValid = false
            if FileManager.default.fileExists(atPath: markerURL.path),
               let data = try? Data(contentsOf: markerURL),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let storedURL = json["url"] as? String,
               let storedSize = (json["fileSize"] as? NSNumber)?.int64Value,
               let storedConcurrency = (json["concurrency"] as? NSNumber)?.intValue,
               storedURL == url.absoluteString,
               storedSize == fileSize,
               storedConcurrency == concurrency {
                isValid = true
            }
            if !isValid {
                try? FileManager.default.removeItem(at: tempDir)
            }
        }

        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let meta: [String: Any] = [
            "url": url.absoluteString,
            "fileSize": NSNumber(value: fileSize),
            "concurrency": NSNumber(value: concurrency)
        ]
        if let data = try? JSONSerialization.data(withJSONObject: meta) {
            try? data.write(to: markerURL)
        }
    }

    private func loadExistingChunks(chunks: [Chunk], tempDir: URL) -> [Chunk] {
        chunks.map { chunk in
            let tempURL = tempDir.appendingPathComponent("chunk.\(chunk.index)")
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: tempURL.path),
                  let size = attrs[.size] as? Int64 else {
                return Chunk(index: chunk.index, range: chunk.range, tempURL: tempURL, state: .pending)
            }

            if size == chunk.length {
                return Chunk(index: chunk.index, range: chunk.range, tempURL: tempURL, state: .complete)
            } else if size > 0 && size < chunk.length {
                return Chunk(index: chunk.index, range: chunk.range, tempURL: tempURL, state: .partial(size))
            } else {
                try? FileManager.default.removeItem(at: tempURL)
                return Chunk(index: chunk.index, range: chunk.range, tempURL: tempURL, state: .pending)
            }
        }
    }

    private func cleanupTempDirectory(tempDir: URL, keepPartial: Bool = false) {
        guard !keepPartial else { return }
        try? FileManager.default.removeItem(at: tempDir)
    }
}

// MARK: - Helpers

private func writeBuffer(_ buffer: Data, to stream: OutputStream) throws {
    guard !buffer.isEmpty else { return }
    var cursor = 0
    while cursor < buffer.count {
        let bytesToWrite = buffer.count - cursor
        let written = buffer.withUnsafeBytes { ptr -> Int in
            stream.write(ptr.bindMemory(to: UInt8.self).baseAddress!.advanced(by: cursor), maxLength: bytesToWrite)
        }
        if written < 0 {
            throw NSError(
                domain: "ModelDownloadManager",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Write failed while downloading."]
            )
        }
        if written == 0 {
            throw NSError(
                domain: "ModelDownloadManager",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: "Write stalled while downloading."]
            )
        }
        cursor += written
    }
}
