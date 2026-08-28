import Foundation

public final class DownloadManager: NSObject, URLSessionDownloadDelegate {
    public static let shared = DownloadManager()
    
    private var session: URLSession!
    public var onProgress: ((String, Double) -> Void)?
    public var onComplete: ((String, URL?, Error?) -> Void)?
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.theblackarchives.downloads")
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    public func startDownload(url: URL, modelId: String) {
        let task = session.downloadTask(with: url)
        task.taskDescription = modelId
        task.resume()
    }
    
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let modelId = downloadTask.taskDescription ?? "unknown"
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destDir = docs.appendingPathComponent("LocalModels/\(modelId)")
        try? FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
        
        let destURL = destDir.appendingPathComponent(downloadTask.originalRequest?.url?.lastPathComponent ?? "model.bin")
        do {
            try FileManager.default.moveItem(at: location, to: destURL)
            Logger.info("Download complete: \(modelId) → \(destURL.path)")
            onComplete?(modelId, destURL, nil)
        } catch {
            Logger.error("Failed to move downloaded file: \(error.localizedDescription)")
            onComplete?(modelId, nil, error)
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let modelId = downloadTask.taskDescription ?? "unknown"
        let progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0
        onProgress?(modelId, progress)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let modelId = task.taskDescription ?? "unknown"
        if let error = error {
            Logger.error("Download failed for \(modelId): \(error.localizedDescription)")
            onComplete?(modelId, nil, error)
        }
    }
}
