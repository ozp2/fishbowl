import Foundation
@testable import fishbowl

class MockFileService: FileServiceProtocol {
    private var entries: [String] = []
    private var entriesByDate: [Date: [String]] = [:]
    
    var shouldFail = false
    var mockError: FileServiceError?
    
    // Test data
    var mockEntries = [
        "Today I learned about SwiftUI testing",
        "Working on a new project with clean architecture",
        "Feeling productive and focused on goals"
    ]
    
    func saveJournalEntry(_ text: String) throws {
        if shouldFail {
            throw mockError ?? FileServiceError.fileWriteFailed
        }
        
        entries.append(text)
        let today = Date()
        entriesByDate[today, default: []].append(text)
    }
    
    func readJournalEntries() throws -> [String] {
        if shouldFail {
            throw mockError ?? FileServiceError.fileReadFailed
        }
        
        return entries.isEmpty ? mockEntries : entries
    }
    
    func readRecentEntries(days: Int = 7) throws -> [String] {
        if shouldFail {
            throw mockError ?? FileServiceError.fileReadFailed
        }
        
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        var recentEntries: [String] = []
        for (date, dateEntries) in entriesByDate {
            if date >= startDate {
                recentEntries.append(contentsOf: dateEntries)
            }
        }
        
        return recentEntries.isEmpty ? mockEntries : recentEntries
    }
    
    // Test helpers
    func reset() {
        entries.removeAll()
        entriesByDate.removeAll()
        shouldFail = false
        mockError = nil
    }
    
    func simulateError(_ error: FileServiceError) {
        shouldFail = true
        mockError = error
    }
    
    func addMockEntry(_ text: String, date: Date = Date()) {
        entries.append(text)
        entriesByDate[date, default: []].append(text)
    }
    
    func getStoredEntries() -> [String] {
        return entries
    }
    
    func getEntriesCount() -> Int {
        return entries.count
    }
} 