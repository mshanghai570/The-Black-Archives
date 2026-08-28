import Foundation
import OSLog

public enum Logger {
    private static let logger = os.Logger(subsystem: "com.theblackarchives.app", category: "CoreSystem")
    
    public static func info(_ msg: String) {
        logger.info("\(msg)")
        print("[INFO] \(msg)")
    }
    
    public static func error(_ msg: String) {
        logger.error("\(msg)")
        print("[ERROR] \(msg)")
    }
    
    public static func warning(_ msg: String) {
        logger.warning("\(msg)")
        print("[WARN] \(msg)")
    }
}
