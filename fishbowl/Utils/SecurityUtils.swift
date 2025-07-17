import Foundation

class SecurityUtils {
    static let shared = SecurityUtils()
    
    private init() {}
    
    // MARK: - Input Validation
    
    /// Validates and sanitizes journal entry text
    /// - Parameter text: The raw journal entry text
    /// - Returns: Sanitized text safe for storage and processing
    func validateJournalEntry(_ text: String) -> String? {
        // Remove null bytes and control characters (except newlines and tabs)
        let sanitized = text.replacingOccurrences(of: "\0", with: "")
            .filter { character in
                let scalar = character.unicodeScalars.first!
                return scalar.value >= 32 || scalar == "\n" || scalar == "\t"
            }
        
        // Check length limits
        guard sanitized.count <= 50000 else {
            logWarning("Journal entry too long: \(sanitized.count) characters", category: "Security")
            return nil
        }
        
        // Check for reasonable content
        let trimmed = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        
        return sanitized
    }
    
    /// Validates and sanitizes theme content
    /// - Parameter text: The raw theme text
    /// - Returns: Sanitized theme text
    func validateThemeContent(_ text: String) -> String? {
        let sanitized = text.replacingOccurrences(of: "\0", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !sanitized.isEmpty && sanitized.count <= 1000 else {
            return nil
        }
        
        return sanitized
    }
    
    // MARK: - Path Validation
    
    /// Validates file names to prevent path traversal attacks
    /// - Parameter filename: The filename to validate
    /// - Returns: Safe filename or nil if invalid
    func validateFileName(_ filename: String) -> String? {
        // Remove null bytes and control characters
        let sanitized = filename.replacingOccurrences(of: "\0", with: "")
            .filter { character in
                let scalar = character.unicodeScalars.first!
                return scalar.value >= 32 && scalar.value <= 126
            }
        
        // Check for path traversal attempts
        let pathComponents = sanitized.components(separatedBy: "/")
        for component in pathComponents {
            if component == ".." || component == "." || component.contains("\\") {
                logWarning("Path traversal attempt detected: \(filename)", category: "Security")
                return nil
            }
        }
        
        // Check for invalid characters
        let invalidChars = CharacterSet(charactersIn: "<>:\"|?*")
        if sanitized.rangeOfCharacter(from: invalidChars) != nil {
            logWarning("Invalid characters in filename: \(filename)", category: "Security")
            return nil
        }
        
        // Check length
        guard sanitized.count <= 255 && !sanitized.isEmpty else {
            return nil
        }
        
        return sanitized
    }
    
    /// Validates that a path is within the expected directory bounds
    /// - Parameters:
    ///   - path: The path to validate
    ///   - allowedDirectory: The directory that should contain the path
    /// - Returns: True if path is safe, false otherwise
    func validatePathWithinDirectory(_ path: URL, allowedDirectory: URL) -> Bool {
        let resolvedPath = path.resolvingSymlinksInPath().standardized
        let resolvedAllowed = allowedDirectory.resolvingSymlinksInPath().standardized
        
        // Check if the path is within the allowed directory
        return resolvedPath.path.hasPrefix(resolvedAllowed.path)
    }
    
    // MARK: - Content Sanitization
    
    /// Sanitizes content for LLM processing
    /// - Parameter content: Raw content to sanitize
    /// - Returns: Sanitized content safe for AI processing
    func sanitizeForLLM(_ content: String) -> String {
        // Remove null bytes and excessive whitespace
        let sanitized = content.replacingOccurrences(of: "\0", with: "")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Limit length to prevent resource exhaustion
        if sanitized.count > 10000 {
            logWarning("Content truncated for LLM processing", category: "Security")
            return String(sanitized.prefix(10000))
        }
        
        return sanitized
    }
    
    /// Sanitizes error messages to prevent information disclosure
    /// - Parameter error: The error to sanitize
    /// - Returns: Safe error message for user display
    func sanitizeErrorForUser(_ error: Error) -> String {
        let description = error.localizedDescription
        
        // Remove file paths from error messages
        let pathRegex = try! NSRegularExpression(pattern: #"/[^/\s]+(?:/[^/\s]+)*"#, options: [])
        let sanitized = pathRegex.stringByReplacingMatches(
            in: description,
            options: [],
            range: NSRange(location: 0, length: description.count),
            withTemplate: "[file path]"
        )
        
        // Remove specific system information
        return sanitized
            .replacingOccurrences(of: NSHomeDirectory(), with: "[home directory]")
            .replacingOccurrences(of: NSUserName(), with: "[user]")
    }
    
    // MARK: - Network Security
    
    /// Validates URLs for network requests
    /// - Parameter url: The URL to validate
    /// - Returns: True if URL is safe for requests
    func validateURL(_ url: URL) -> Bool {
        // Only allow localhost for Ollama
        guard let host = url.host else { return false }
        
        // Allow localhost, 127.0.0.1, and ::1
        let allowedHosts = ["localhost", "127.0.0.1", "::1"]
        guard allowedHosts.contains(host) else {
            logWarning("Blocked request to non-localhost host: \(host)", category: "Security")
            return false
        }
        
        // Check port range
        let port = url.port ?? 80
        guard port >= 1024 && port <= 65535 else {
            logWarning("Blocked request to suspicious port: \(port)", category: "Security")
            return false
        }
        
        return true
    }
    
    /// Validates HTTP response for safety
    /// - Parameter response: The HTTP response to validate
    /// - Returns: True if response is safe to process
    func validateHTTPResponse(_ response: HTTPURLResponse) -> Bool {
        // Check status code range
        guard 200...299 ~= response.statusCode else {
            return false
        }
        
        // Check content type if available
        if let contentType = response.allHeaderFields["Content-Type"] as? String {
            let allowedTypes = ["application/json", "text/plain", "text/json"]
            let isAllowed = allowedTypes.contains { contentType.hasPrefix($0) }
            if !isAllowed {
                logWarning("Unexpected content type: \(contentType)", category: "Security")
            }
        }
        
        return true
    }
} 