import Testing
import Foundation
@testable import fishbowl

struct FileServiceTests {
    
    // Helper to create isolated test directory
    private func createTestDirectory() throws -> URL {
        let testDirectoryName = "fishbowl_test_\(UUID().uuidString)"
        let testDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(testDirectoryName)
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        return testDirectory
    }
    
    // Helper to clean up test directory
    private func cleanupTestDirectory(_ directory: URL) {
        try? FileManager.default.removeItem(at: directory)
    }
    
    @Test("FileService saves journal entry successfully")
    func testSaveJournalEntry() async throws {
        let testDirectory = try createTestDirectory()
        defer { cleanupTestDirectory(testDirectory) }
        
        let fileService = FileService(customBaseDirectory: testDirectory)
        let testEntry = "Test journal entry \(UUID().uuidString)"
        
        try fileService.saveJournalEntry(testEntry)
        
        let entries = try fileService.readJournalEntries()
        let found = entries.contains { $0.contains(testEntry) }
        #expect(found, "Test entry should be found in saved entries")
    }
    
    @Test("FileService saves multiple entries correctly")
    func testSaveMultipleEntries() async throws {
        let testDirectory = try createTestDirectory()
        defer { cleanupTestDirectory(testDirectory) }
        
        let fileService = FileService(customBaseDirectory: testDirectory)
        let entries = [
            "First test entry \(UUID().uuidString)",
            "Second test entry \(UUID().uuidString)",
            "Third test entry \(UUID().uuidString)"
        ]
        
        for entry in entries {
            try fileService.saveJournalEntry(entry)
        }
        
        let savedEntries = try fileService.readJournalEntries()
        for entry in entries {
            let found = savedEntries.contains { $0.contains(entry) }
            #expect(found, "Entry '\(entry)' should be found in saved entries")
        }
    }
    
    @Test("FileService reads journal entries successfully")
    func testReadJournalEntries() async throws {
        let testDirectory = try createTestDirectory()
        defer { cleanupTestDirectory(testDirectory) }
        
        let fileService = FileService(customBaseDirectory: testDirectory)
        let uniqueEntry = "Unique test entry \(UUID().uuidString)"
        try fileService.saveJournalEntry(uniqueEntry)
        
        let entries = try fileService.readJournalEntries()
        
        #expect(entries.count > 0, "Should have at least one entry")
        let found = entries.contains { $0.contains(uniqueEntry) }
        #expect(found, "Should find the unique entry we just saved")
    }
    
    @Test("FileService handles empty journal gracefully")
    func testReadEmptyJournal() async throws {
        let testDirectory = try createTestDirectory()
        defer { cleanupTestDirectory(testDirectory) }
        
        let fileService = FileService(customBaseDirectory: testDirectory)
        
        #expect(throws: Never.self) {
            let entries = try fileService.readJournalEntries()
            #expect(entries.isEmpty, "Empty journal should return empty array")
        }
    }
    
    @Test("FileService reads recent entries within date range")
    func testReadRecentEntries() async throws {
        let testDirectory = try createTestDirectory()
        defer { cleanupTestDirectory(testDirectory) }
        
        let fileService = FileService(customBaseDirectory: testDirectory)
        let recentEntry = "Recent entry \(UUID().uuidString)"
        try fileService.saveJournalEntry(recentEntry)
        
        let recentEntries = try fileService.readRecentEntries(days: 7)
        
        let found = recentEntries.contains { $0.contains(recentEntry) }
        #expect(found, "Recent entry should be found in recent entries")
    }
    
    @Test("FileService preserves entry content exactly")
    func testPreservesEntryContent() async throws {
        let testDirectory = try createTestDirectory()
        defer { cleanupTestDirectory(testDirectory) }
        
        let fileService = FileService(customBaseDirectory: testDirectory)
        let uniqueId = UUID().uuidString
        let complexEntry = """
        Complex entry \(uniqueId) with:
        - Multiple lines
        - Special characters: !@#$%^&*()
        - Unicode: 🎯📝✅
        """
        
        try fileService.saveJournalEntry(complexEntry)
        let entries = try fileService.readJournalEntries()
        
        let found = entries.contains { entry in
            entry.contains(uniqueId) &&
            entry.contains("Multiple lines") &&
            entry.contains("🎯📝✅")
        }
        #expect(found, "Complex entry content should be preserved exactly")
    }
    
    @Test("FileService handles large entries")
    func testLargeEntry() async throws {
        let testDirectory = try createTestDirectory()
        defer { cleanupTestDirectory(testDirectory) }
        
        let fileService = FileService(customBaseDirectory: testDirectory)
        let uniqueId = UUID().uuidString
        let largeEntry = "Large entry \(uniqueId): " + String(repeating: "Content. ", count: 500)
        
        try fileService.saveJournalEntry(largeEntry)
        let entries = try fileService.readJournalEntries()
        
        let found = entries.contains { $0.contains(uniqueId) }
        #expect(found, "Large entry should be saved and retrieved correctly")
    }
    
    @Test("FileService entries contain proper timestamps")
    func testEntriesContainTimestamps() async throws {
        let testDirectory = try createTestDirectory()
        defer { cleanupTestDirectory(testDirectory) }
        
        let fileService = FileService(customBaseDirectory: testDirectory)
        let testEntry = "Entry with timestamp \(UUID().uuidString)"
        
        try fileService.saveJournalEntry(testEntry)
        let entries = try fileService.readJournalEntries()
        
        let found = entries.contains { entry in
            entry.contains(testEntry) && 
            entry.contains("---") && // FileService adds "---" separator
            entry.contains("202") // Should contain year (2024, 2025, etc.)
        }
        #expect(found, "Entry should contain timestamp and separator")
    }
} 