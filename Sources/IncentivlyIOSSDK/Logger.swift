import Foundation

/// Logger class for IncentivlyIOSSDK
public class IncentivlyLogger {
    
    public static let shared = IncentivlyLogger()
    
    private var isEnabled: Bool = false
    private let dateFormatter: DateFormatter
    
    private init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }
    
    /// Enable or disable logging
    /// - Parameter enabled: Whether logging should be enabled
    public func setLoggingEnabled(_ enabled: Bool) {
        isEnabled = enabled
        log("Logging \(enabled ? "enabled" : "disabled")")
    }
    
    /// Check if logging is enabled
    /// - Returns: True if logging is enabled
    public func isLoggingEnabled() -> Bool {
        return isEnabled
    }
    
    /// Log a message with timestamp
    /// - Parameter message: Message to log
    public func log(_ message: String) {
        guard isEnabled else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        print("[IncentivlySDK \(timestamp)] \(message)")
    }
    
    /// Log API request details
    /// - Parameters:
    ///   - method: HTTP method
    ///   - url: Request URL
    ///   - headers: Request headers
    ///   - body: Request body
    public func logRequest(method: String, url: String, headers: [String: String]? = nil, body: Data? = nil) {
        guard isEnabled else { return }
        
        log("🌐 API REQUEST:")
        log("   Method: \(method)")
        log("   URL: \(url)")
        
        if let headers = headers {
            log("   Headers:")
            for (key, value) in headers {
                // Mask sensitive headers
                let maskedValue = key.lowercased().contains("authorization") ? "***" : value
                log("     \(key): \(maskedValue)")
            }
        }
        
        if let body = body {
            if let jsonString = String(data: body, encoding: .utf8) {
                log("   Body: \(jsonString)")
            } else {
                log("   Body: [Binary data]")
            }
        }
    }
    
    /// Log API response details
    /// - Parameters:
    ///   - statusCode: HTTP status code
    ///   - headers: Response headers
    ///   - body: Response body
    ///   - error: Error if any
    public func logResponse(statusCode: Int, headers: [String: String]? = nil, body: Data? = nil, error: Error? = nil) {
        guard isEnabled else { return }
        
        log("📡 API RESPONSE:")
        log("   Status Code: \(statusCode)")
        
        if let headers = headers {
            log("   Headers:")
            for (key, value) in headers {
                log("     \(key): \(value)")
            }
        }
        
        if let body = body {
            if let jsonString = String(data: body, encoding: .utf8) {
                log("   Body: \(jsonString)")
            } else {
                log("   Body: [Binary data]")
            }
        }
        
        if let error = error {
            log("   Error: \(error.localizedDescription)")
        }
    }
    
    /// Log error with context
    /// - Parameters:
    ///   - message: Error message
    ///   - error: Error object
    ///   - context: Additional context
    public func logError(_ message: String, error: Error? = nil, context: String? = nil) {
        guard isEnabled else { return }
        
        log("❌ ERROR: \(message)")
        if let context = context {
            log("   Context: \(context)")
        }
        if let error = error {
            log("   Error: \(error.localizedDescription)")
        }
    }
    
    /// Log success message
    /// - Parameter message: Success message
    public func logSuccess(_ message: String) {
        guard isEnabled else { return }
        log("✅ SUCCESS: \(message)")
    }
    
    /// Log info message
    /// - Parameter message: Info message
    public func logInfo(_ message: String) {
        guard isEnabled else { return }
        log("ℹ️ INFO: \(message)")
    }
} 