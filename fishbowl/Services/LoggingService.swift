import Foundation
import os.log

enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
}

class LoggingService {
    static let shared = LoggingService()
    
    private let logger = Logger(subsystem: "com.fishbowl.app", category: "main")
    private let minimumLogLevel: LogLevel
    
    private init() {
        // Set minimum log level based on build configuration
        #if DEBUG
        self.minimumLogLevel = .debug
        #else
        self.minimumLogLevel = .info
        #endif
    }
    
    func log(_ message: String, level: LogLevel = .info, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        guard shouldLog(level) else { return }
        
        let filename = URL(fileURLWithPath: file).lastPathComponent
        
        // Sanitize message for production logging
        let sanitizedMessage = sanitizeLogMessage(message)
        
        let logMessage = "[\(category)] \(filename):\(line) \(function) - \(sanitizedMessage)"
        
        logger.log(level: level.osLogType, "\(logMessage)")
    }
    
    private func sanitizeLogMessage(_ message: String) -> String {
        #if DEBUG
        // In debug mode, log more detailed information
        return message
        #else
        // In production, sanitize sensitive information
        return SecurityUtils.shared.sanitizeErrorForUser(NSError(domain: "LogMessage", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
        #endif
    }
    
    func debug(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    private func shouldLog(_ level: LogLevel) -> Bool {
        return LogLevel.allCases.firstIndex(of: level)! >= LogLevel.allCases.firstIndex(of: minimumLogLevel)!
    }
}

// Convenience global functions
func logDebug(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    LoggingService.shared.debug(message, category: category, file: file, function: function, line: line)
}

func logInfo(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    LoggingService.shared.info(message, category: category, file: file, function: function, line: line)
}

func logWarning(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    LoggingService.shared.warning(message, category: category, file: file, function: function, line: line)
}

func logError(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    LoggingService.shared.error(message, category: category, file: file, function: function, line: line)
} 