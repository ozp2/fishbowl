import Foundation

protocol FileServiceProtocol {
    /// Saves a journal entry to the file system
    /// - Parameter text: The text content of the journal entry
    /// - Throws: FileServiceError if the save operation fails
    func saveJournalEntry(_ text: String) throws
    
    /// Reads all journal entries from the file system
    /// - Returns: An array of journal entry strings
    /// - Throws: FileServiceError if the read operation fails
    func readJournalEntries() throws -> [String]
    
    /// Reads recent journal entries from the specified number of days
    /// - Parameter days: Number of days to look back (default: 7)
    /// - Returns: An array of recent journal entry strings
    /// - Throws: FileServiceError if the read operation fails
    func readRecentEntries(days: Int) throws -> [String]
} 