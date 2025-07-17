import Foundation

class FileUtils {
    static let shared = FileUtils()
    
    private let fileManager = FileManager.default
    private let baseDirectory: URL
    
    private init() {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        baseDirectory = documentsURL.appendingPathComponent("fishbowl")
    }
    
    // MARK: - Directory Management
    
    /// Gets the base fishbowl directory URL
    var fishbowlDirectory: URL {
        return baseDirectory
    }
    
    /// Gets the thoughts directory URL
    var thoughtsDirectory: URL {
        return baseDirectory.appendingPathComponent("thoughts")
    }
    
    /// Gets the analysis directory URL
    var analysisDirectory: URL {
        return baseDirectory.appendingPathComponent("analysis")
    }
    
    /// Creates all necessary directories if they don't exist
    func createDirectoriesIfNeeded() throws {
        let directories = [baseDirectory, thoughtsDirectory, analysisDirectory]
        
        for directory in directories {
            if !fileManager.fileExists(atPath: directory.path) {
                do {
                    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
                    logDebug("Created directory: \(directory.path)", category: "FileUtils")
                } catch {
                    ErrorHandlingService.shared.handle(
                        FishbowlError.fileSystem(.directoryCreationFailed(path: directory.path)),
                        context: "Creating directory structure"
                    )
                    throw error
                }
            }
        }
    }
    
    // MARK: - File Operations
    
    /// Safely reads a file's contents as a String
    func readFile(at url: URL) throws -> String {
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileServiceError.fileReadFailed
        }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return content
        } catch {
            ErrorHandlingService.shared.handle(
                FishbowlError.fileSystem(.fileReadFailed(path: url.path)),
                context: "Reading file"
            )
            throw FileServiceError.fileReadFailed
        }
    }
    
    /// Safely writes content to a file
    func writeFile(content: String, to url: URL, atomically: Bool = true) throws {
        do {
            try content.write(to: url, atomically: atomically, encoding: .utf8)
            logDebug("Successfully wrote file: \(url.path)", category: "FileUtils")
        } catch {
            ErrorHandlingService.shared.handle(
                FishbowlError.fileSystem(.fileWriteFailed(path: url.path)),
                context: "Writing file"
            )
            throw FileServiceError.fileWriteFailed
        }
    }
    
    /// Safely appends content to a file
    func appendToFile(content: String, at url: URL) throws {
        do {
            if fileManager.fileExists(atPath: url.path) {
                let fileHandle = try FileHandle(forWritingTo: url)
                defer { fileHandle.closeFile() }
                
                fileHandle.seekToEndOfFile()
                if let data = content.data(using: .utf8) {
                    fileHandle.write(data)
                }
            } else {
                try writeFile(content: content, to: url)
            }
        } catch {
            ErrorHandlingService.shared.handle(
                FishbowlError.fileSystem(.fileWriteFailed(path: url.path)),
                context: "Appending to file"
            )
            throw FileServiceError.fileWriteFailed
        }
    }
    
    /// Safely writes JSON data to a file
    func writeJSON<T: Codable>(_ object: T, to url: URL, prettyPrinted: Bool = false) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if prettyPrinted {
            encoder.outputFormatting = .prettyPrinted
        }
        
        do {
            let data = try encoder.encode(object)
            try data.write(to: url)
            logDebug("Successfully wrote JSON file: \(url.path)", category: "FileUtils")
        } catch {
            ErrorHandlingService.shared.handle(
                FishbowlError.fileSystem(.fileWriteFailed(path: url.path)),
                context: "Writing JSON file"
            )
            throw FileServiceError.fileWriteFailed
        }
    }
    
    /// Safely reads JSON data from a file
    func readJSON<T: Codable>(_ type: T.Type, from url: URL) throws -> T {
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileServiceError.fileReadFailed
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let object = try decoder.decode(type, from: data)
            return object
        } catch {
            ErrorHandlingService.shared.handle(
                FishbowlError.data(.corruptedJSON),
                context: "Reading JSON file: \(url.path)"
            )
            throw FileServiceError.fileReadFailed
        }
    }
    
    // MARK: - File Listing
    
    /// Lists all files in a directory with a specific extension
    func listFiles(in directory: URL, withExtension extension: String) -> [String] {
        do {
            let files = try fileManager.contentsOfDirectory(atPath: directory.path)
            return files.filter { $0.hasSuffix(".\(`extension`)") }.sorted()
        } catch {
            logError("Failed to list files in directory: \(directory.path)", category: "FileUtils")
            return []
        }
    }
    
    /// Lists all thought files (sorted by date, newest first)
    func listThoughtFiles() -> [String] {
        let files = listFiles(in: thoughtsDirectory, withExtension: "txt")
        return files.sorted().reversed()
    }
    
    // MARK: - File Paths
    
    /// Gets the URL for a thought file based on date
    func thoughtFileURL(for date: Date) -> URL {
        let fileName = DateUtils.shared.formatDateForFileName(date)
        return thoughtsDirectory.appendingPathComponent(fileName)
    }
    
    /// Gets the URL for an analysis file based on date
    func analysisFileURL(for date: Date, prefix: String = "daily_analysis") -> URL {
        let fileName = DateUtils.shared.formatDateForAnalysisFileName(date)
        return analysisDirectory.appendingPathComponent("\(prefix)_\(fileName)")
    }
    
    // MARK: - File Existence
    
    /// Checks if a file exists
    func fileExists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }
    
    /// Checks if a thought file exists for a given date
    func thoughtFileExists(for date: Date) -> Bool {
        let url = thoughtFileURL(for: date)
        return fileExists(at: url)
    }
} 