import Foundation

// Reserved for future model download task tracking.
public struct DownloadTask: Identifiable {
    public let id: String
    public let modelId: String
    public var progress: Double
    public var status: Status
    
    public enum Status {
        case pending
        case downloading
        case completed
        case failed(String)
    }
}
