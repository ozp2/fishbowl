import Foundation

enum FishbowlError: Error, Equatable {
    case fileSystem(FileSystemError)
    case llm(LLMError)
    case notification(NotificationError)
    case theme(ThemeError)
    case analysis(AnalysisError)
    case data(DataError)
    case network(NetworkError)
    case unknown(String)
    
    var localizedDescription: String {
        let rawMessage = switch self {
        case .fileSystem(let error):
            error.userFriendlyMessage
        case .llm(let error):
            error.userFriendlyMessage
        case .notification(let error):
            error.userFriendlyMessage
        case .theme(let error):
            error.userFriendlyMessage
        case .analysis(let error):
            error.userFriendlyMessage
        case .data(let error):
            error.userFriendlyMessage
        case .network(let error):
            error.userFriendlyMessage
        case .unknown(let message):
            "An unexpected error occurred: \(message)"
        }
        
        // Sanitize error message for security
        return SecurityUtils.shared.sanitizeErrorForUser(FishbowlError.unknown(rawMessage))
    }
    
    var technicalDescription: String {
        switch self {
        case .fileSystem(let error):
            return error.technicalDescription
        case .llm(let error):
            return error.technicalDescription
        case .notification(let error):
            return error.technicalDescription
        case .theme(let error):
            return error.technicalDescription
        case .analysis(let error):
            return error.technicalDescription
        case .data(let error):
            return error.technicalDescription
        case .network(let error):
            return error.technicalDescription
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var category: String {
        switch self {
        case .fileSystem:
            return "FileSystem"
        case .llm:
            return "LLM"
        case .notification:
            return "Notification"
        case .theme:
            return "Theme"
        case .analysis:
            return "Analysis"
        case .data:
            return "Data"
        case .network:
            return "Network"
        case .unknown:
            return "Unknown"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .fileSystem(let error):
            return error.severity
        case .llm(let error):
            return error.severity
        case .notification(let error):
            return error.severity
        case .theme(let error):
            return error.severity
        case .analysis(let error):
            return error.severity
        case .data(let error):
            return error.severity
        case .network(let error):
            return error.severity
        case .unknown:
            return .high
        }
    }
}

enum ErrorSeverity: Equatable {
    case low      // Minor issues that don't affect core functionality
    case medium   // Issues that affect some functionality but have workarounds
    case high     // Critical issues that affect core functionality
    case critical // System-breaking issues
}

// MARK: - Specific Error Types

enum FileSystemError: Error, Equatable {
    case directoryCreationFailed(path: String)
    case fileNotFound(path: String)
    case fileWriteFailed(path: String)
    case fileReadFailed(path: String)
    case permissionDenied(path: String)
    case diskFull
    case corruptedFile(path: String)
    
    var userFriendlyMessage: String {
        switch self {
        case .directoryCreationFailed:
            return "Unable to create necessary folders. Please check your disk space and permissions."
        case .fileNotFound:
            return "The requested file could not be found. It may have been moved or deleted."
        case .fileWriteFailed:
            return "Unable to save your thoughts. Please check your available disk space."
        case .fileReadFailed:
            return "Unable to read your previous thoughts. The file may be corrupted."
        case .permissionDenied:
            return "Permission denied. Please check your file system permissions."
        case .diskFull:
            return "Your disk is full. Please free up some space and try again."
        case .corruptedFile:
            return "The file appears to be corrupted. Your other thoughts are safe."
        }
    }
    
    var technicalDescription: String {
        switch self {
        case .directoryCreationFailed(let path):
            return "Failed to create directory at path: \(path)"
        case .fileNotFound(let path):
            return "File not found at path: \(path)"
        case .fileWriteFailed(let path):
            return "Failed to write file at path: \(path)"
        case .fileReadFailed(let path):
            return "Failed to read file at path: \(path)"
        case .permissionDenied(let path):
            return "Permission denied for path: \(path)"
        case .diskFull:
            return "Disk full error"
        case .corruptedFile(let path):
            return "Corrupted file at path: \(path)"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .directoryCreationFailed:
            return .high
        case .fileNotFound:
            return .medium
        case .fileWriteFailed:
            return .high
        case .fileReadFailed:
            return .medium
        case .permissionDenied:
            return .high
        case .diskFull:
            return .critical
        case .corruptedFile:
            return .medium
        }
    }
}

enum LLMError: Error, Equatable {
    case serviceUnavailable
    case modelNotFound
    case requestTimeout
    case responseParsingFailed
    case invalidPrompt
    case rateLimitExceeded
    case networkError
    
    var userFriendlyMessage: String {
        switch self {
        case .serviceUnavailable:
            return "The AI service is currently unavailable. Please make sure Ollama is running."
        case .modelNotFound:
            return "The AI model is not available. Please install the required model using Ollama."
        case .requestTimeout:
            return "The AI request timed out. Please try again with a shorter text."
        case .responseParsingFailed:
            return "Unable to understand the AI response. Please try again."
        case .invalidPrompt:
            return "The request format is invalid. Please try again."
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment and try again."
        case .networkError:
            return "Network error. Please check your connection and try again."
        }
    }
    
    var technicalDescription: String {
        switch self {
        case .serviceUnavailable:
            return "LLM service is not available"
        case .modelNotFound:
            return "Required model not found"
        case .requestTimeout:
            return "Request timeout"
        case .responseParsingFailed:
            return "Failed to parse LLM response"
        case .invalidPrompt:
            return "Invalid prompt format"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .networkError:
            return "Network error"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .serviceUnavailable:
            return .high
        case .modelNotFound:
            return .high
        case .requestTimeout:
            return .medium
        case .responseParsingFailed:
            return .medium
        case .invalidPrompt:
            return .low
        case .rateLimitExceeded:
            return .medium
        case .networkError:
            return .medium
        }
    }
}

enum NotificationError: Error, Equatable {
    case permissionDenied
    case schedulingFailed
    case deliveryFailed
    
    var userFriendlyMessage: String {
        switch self {
        case .permissionDenied:
            return "Notification permission denied. Please enable notifications in System Preferences."
        case .schedulingFailed:
            return "Unable to schedule notifications. Please try again."
        case .deliveryFailed:
            return "Failed to deliver notification."
        }
    }
    
    var technicalDescription: String {
        switch self {
        case .permissionDenied:
            return "Notification permission denied"
        case .schedulingFailed:
            return "Failed to schedule notification"
        case .deliveryFailed:
            return "Failed to deliver notification"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .permissionDenied:
            return .medium
        case .schedulingFailed:
            return .low
        case .deliveryFailed:
            return .low
        }
    }
}

enum ThemeError: Error, Equatable {
    case discoveryFailed
    case saveFailed
    case loadFailed
    case processingFailed
    
    var userFriendlyMessage: String {
        switch self {
        case .discoveryFailed:
            return "Unable to discover themes from your thoughts. Please try again later."
        case .saveFailed:
            return "Unable to save theme information. Your thoughts are safe."
        case .loadFailed:
            return "Unable to load your themes. They may be recovered on next restart."
        case .processingFailed:
            return "Unable to process themes. Please try again."
        }
    }
    
    var technicalDescription: String {
        switch self {
        case .discoveryFailed:
            return "Theme discovery failed"
        case .saveFailed:
            return "Theme save failed"
        case .loadFailed:
            return "Theme load failed"
        case .processingFailed:
            return "Theme processing failed"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .discoveryFailed:
            return .medium
        case .saveFailed:
            return .medium
        case .loadFailed:
            return .medium
        case .processingFailed:
            return .medium
        }
    }
}

enum AnalysisError: Error, Equatable {
    case dailyAnalysisFailed
    case weeklyAnalysisFailed
    case insufficientData
    case corruptedData
    
    var userFriendlyMessage: String {
        switch self {
        case .dailyAnalysisFailed:
            return "Unable to analyze today's thoughts. Please try again later."
        case .weeklyAnalysisFailed:
            return "Unable to analyze weekly patterns. Please try again later."
        case .insufficientData:
            return "Not enough data for analysis. Please add more thoughts."
        case .corruptedData:
            return "Some data appears corrupted. Analysis may be incomplete."
        }
    }
    
    var technicalDescription: String {
        switch self {
        case .dailyAnalysisFailed:
            return "Daily analysis failed"
        case .weeklyAnalysisFailed:
            return "Weekly analysis failed"
        case .insufficientData:
            return "Insufficient data for analysis"
        case .corruptedData:
            return "Data corruption detected"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .dailyAnalysisFailed:
            return .medium
        case .weeklyAnalysisFailed:
            return .medium
        case .insufficientData:
            return .low
        case .corruptedData:
            return .medium
        }
    }
}

enum DataError: Error, Equatable {
    case corruptedJSON
    case incompatibleVersion
    case migrationFailed
    case validationFailed
    
    var userFriendlyMessage: String {
        switch self {
        case .corruptedJSON:
            return "Some data is corrupted. Your other thoughts are safe."
        case .incompatibleVersion:
            return "Data format needs to be updated. This will happen automatically."
        case .migrationFailed:
            return "Unable to update data format. Please contact support."
        case .validationFailed:
            return "Data validation failed. Some features may not work correctly."
        }
    }
    
    var technicalDescription: String {
        switch self {
        case .corruptedJSON:
            return "JSON data corruption detected"
        case .incompatibleVersion:
            return "Data version incompatibility"
        case .migrationFailed:
            return "Data migration failed"
        case .validationFailed:
            return "Data validation failed"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .corruptedJSON:
            return .medium
        case .incompatibleVersion:
            return .medium
        case .migrationFailed:
            return .high
        case .validationFailed:
            return .medium
        }
    }
}

enum NetworkError: Error, Equatable {
    case noConnection
    case timeout
    case serverError(Int)
    case invalidResponse
    
    var userFriendlyMessage: String {
        switch self {
        case .noConnection:
            return "No network connection. Please check your internet connection."
        case .timeout:
            return "Request timed out. Please try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .invalidResponse:
            return "Invalid response from server. Please try again."
        }
    }
    
    var technicalDescription: String {
        switch self {
        case .noConnection:
            return "No network connection"
        case .timeout:
            return "Network timeout"
        case .serverError(let code):
            return "Server error: \(code)"
        case .invalidResponse:
            return "Invalid server response"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .noConnection:
            return .medium
        case .timeout:
            return .low
        case .serverError:
            return .medium
        case .invalidResponse:
            return .medium
        }
    }
}

// MARK: - Error Handling Service

class ErrorHandlingService {
    static let shared = ErrorHandlingService()
    
    private init() {}
    
    func handle(_ error: FishbowlError, context: String = "") {
        let contextMessage = context.isEmpty ? "" : " (Context: \(context))"
        logError("\(error.technicalDescription)\(contextMessage)", category: error.category)
    }
    
    func handle(_ error: Error, context: String = "") {
        let fishbowlError = mapToFishbowlError(error)
        handle(fishbowlError, context: context)
    }
    
    private func mapToFishbowlError(_ error: Error) -> FishbowlError {
        switch error {
        case let serviceError as FileServiceError:
            return .fileSystem(mapFileServiceError(serviceError))
        case let llmError as LLMServiceError:
            return .llm(mapLLMServiceError(llmError))
        default:
            return .unknown(error.localizedDescription)
        }
    }
    
    private func mapFileServiceError(_ error: FileServiceError) -> FileSystemError {
        switch error {
        case .directoryCreationFailed:
            return .directoryCreationFailed(path: "")
        case .fileWriteFailed:
            return .fileWriteFailed(path: "")
        case .fileReadFailed:
            return .fileReadFailed(path: "")
        case .invalidData:
            return .corruptedFile(path: "")
        }
    }
    
    private func mapLLMServiceError(_ error: LLMServiceError) -> LLMError {
        switch error {
        case .modelNotAvailable:
            return .modelNotFound
        case .invalidRequest:
            return .invalidPrompt
        case .networkError:
            return .networkError
        case .responseParsingError:
            return .responseParsingFailed
        case .serverError:
            return .serviceUnavailable
        case .unknownError:
            return .serviceUnavailable
        }
    }
}

 