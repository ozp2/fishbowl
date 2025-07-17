import Foundation

enum FileServiceError: Error, Equatable {
    case directoryCreationFailed
    case fileWriteFailed
    case fileReadFailed
    case invalidData
    
    var localizedDescription: String {
        switch self {
        case .directoryCreationFailed:
            return "Failed to create journal directory"
        case .fileWriteFailed:
            return "Failed to write journal entry"
        case .fileReadFailed:
            return "Failed to read journal entries"
        case .invalidData:
            return "Invalid journal entry data"
        }
    }
}

class FileService: FileServiceProtocol {
    private let fileManager = FileManager.default
    private let baseDirectory: URL
    private let journalDirectory: URL
    private let dateFormatter: DateFormatter
    
    init() {
        // Use Documents directory as base
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        baseDirectory = documentsURL.appendingPathComponent("fishbowl")
        journalDirectory = baseDirectory.appendingPathComponent("thoughts")
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE MMM d yyyy"
        
        try? createDirectoriesIfNeeded()
    }
    
    // Test-specific initializer
    init(customBaseDirectory: URL) {
        baseDirectory = customBaseDirectory
        journalDirectory = baseDirectory.appendingPathComponent("thoughts")
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE MMM d yyyy"
        
        try? createDirectoriesIfNeeded()
    }
    
    private func createDirectoriesIfNeeded() throws {
        // Create base fishbowl directory
        if !fileManager.fileExists(atPath: baseDirectory.path) {
            do {
                try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
            } catch {
                throw FileServiceError.directoryCreationFailed
            }
        }
        
        // Create thoughts directory
        if !fileManager.fileExists(atPath: journalDirectory.path) {
            do {
                try fileManager.createDirectory(at: journalDirectory, withIntermediateDirectories: true)
            } catch {
                throw FileServiceError.directoryCreationFailed
            }
        }
    }
    
    private func migrateFromOldLocation() {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let oldDirectory = documentsURL.appendingPathComponent("MyThoughts")
        
        guard fileManager.fileExists(atPath: oldDirectory.path) else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: oldDirectory, includingPropertiesForKeys: nil)
            for file in files {
                let newLocation = journalDirectory.appendingPathComponent(file.lastPathComponent)
                if !fileManager.fileExists(atPath: newLocation.path) {
                    try fileManager.copyItem(at: file, to: newLocation)
                }
            }
            
            // After successful migration, try to remove old directory
            try fileManager.removeItem(at: oldDirectory)
        } catch {
            logError("Error during migration: \(error)", category: "FileService")
        }
    }
    
    func saveJournalEntry(_ text: String) throws {
        // Validate and sanitize input
        guard let sanitizedText = SecurityUtils.shared.validateJournalEntry(text) else {
            throw FileServiceError.invalidData
        }
        
        try createDirectoriesIfNeeded()
        
        let fileName = getJournalFileName()
        
        // Validate filename for security
        guard SecurityUtils.shared.validateFileName(fileName) != nil else {
            throw FileServiceError.fileWriteFailed
        }
        
        let fileURL = journalDirectory.appendingPathComponent(fileName)
        
        // Validate path is within allowed directory
        guard SecurityUtils.shared.validatePathWithinDirectory(fileURL, allowedDirectory: journalDirectory) else {
            throw FileServiceError.fileWriteFailed
        }
        
        let entry = formatJournalEntry(sanitizedText)
        
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
                if let data = entry.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } else {
                try entry.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            throw FileServiceError.fileWriteFailed
        }
    }
    
    func readJournalEntries() throws -> [String] {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: journalDirectory,
                                                             includingPropertiesForKeys: nil)
            return try fileURLs
                .filter { $0.pathExtension == "txt" }
                .sorted { $0.lastPathComponent > $1.lastPathComponent }
                .map { try String(contentsOf: $0, encoding: .utf8) }
        } catch {
            throw FileServiceError.fileReadFailed
        }
    }
    
    func readRecentEntries(days: Int = 7) throws -> [String] {
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: today)!
        
        return try readJournalEntries().filter { entry in
            if let entryDate = extractDate(from: entry) {
                return calendar.compare(entryDate, to: today, toGranularity: .day) != .orderedDescending &&
                       calendar.compare(entryDate, to: startDate, toGranularity: .day) != .orderedAscending
            }
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func getJournalFileName() -> String {
        let rawName = dateFormatter.string(from: Date())
        return rawName.replacingOccurrences(of: " ", with: "") + ".txt"
    }
    
    private func formatJournalEntry(_ text: String) -> String {
        return "\n\n---\n\(DateFormatter.iso8601Full.string(from: Date()))\n\(text)"
    }
    
    private func extractDate(from entry: String) -> Date? {
        let lines = entry.components(separatedBy: .newlines)
        for line in lines {
            if let date = DateFormatter.iso8601Full.date(from: line) {
                return date
            }
        }
        return nil
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
} 