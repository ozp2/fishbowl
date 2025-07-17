import Foundation
import SwiftUI

class ThemeManager: ObservableObject {
    private let llmService = LLMService()
    private let fileManager = FileManager.default
    private var thoughtsDirectory: URL
    private var themeIndexFile: URL
    
    @Published var activeThemes: [Theme] = []
    @Published var isDiscovering = false
    @Published var lastDiscoveryDate: Date?
    
    private let maxThemesTracked = 10 // Keep the most important themes
    private let minMentionsForTheme = 1 // Temporarily lowered for testing
    
    init() {
        let fileUtils = FileUtils.shared
        thoughtsDirectory = fileUtils.thoughtsDirectory
        themeIndexFile = fileUtils.fishbowlDirectory.appendingPathComponent("theme_index.json")
        
        try? fileUtils.createDirectoriesIfNeeded()
        
        activeThemes = loadThemeIndex()
    }
    
    // MARK: - Theme Discovery
    
    func discoverThemes(fromRecentDays days: Int = 7) async {
        await MainActor.run {
            isDiscovering = true
        }
        
        let recentThoughts = getRecentThoughts(days: days)
        logDebug("Found \(recentThoughts.count) recent thoughts", category: "ThemeManager")
        logDebug("Total content length: \(recentThoughts.joined(separator: "").count) characters", category: "ThemeManager")
        
        if recentThoughts.isEmpty {
            logDebug("No recent thoughts found to analyze", category: "ThemeManager")
            await MainActor.run {
                self.isDiscovering = false
            }
            return
        }
        
        let existingThemeNames = activeThemes.map { $0.name }
        logDebug("Existing themes: \(existingThemeNames)", category: "ThemeManager")
        
        do {
            logDebug("Starting theme discovery with LLM service...", category: "ThemeManager")
            let combinedContent = recentThoughts.joined(separator: "\n\n---\n\n")
            let discoveredThemes = try await llmService.discoverThemes(from: combinedContent)
            logDebug("Discovered \(discoveredThemes.count) new themes", category: "ThemeManager")
            logDebug("New themes: \(discoveredThemes.map { "\($0.name) (freq: \($0.frequency))" })", category: "ThemeManager")
            
            await MainActor.run {
                self.processDiscoveredThemes(discoveredThemes)
                self.lastDiscoveryDate = Date()
                self.isDiscovering = false
                self.saveThemeIndex()
                
                logDebug("Active themes after processing: \(self.activeThemes.map { "\($0.name) (freq: \($0.frequency))" })", category: "ThemeManager")
            }
        } catch {
            ErrorHandlingService.shared.handle(
                FishbowlError.theme(.discoveryFailed),
                context: "Discovering themes from recent thoughts"
            )
            await MainActor.run {
                self.isDiscovering = false
            }
        }
    }
    
    private func processDiscoveredThemes(_ discoveredThemes: [Theme]) {
        logDebug("Processing \(discoveredThemes.count) discovered themes", category: "ThemeManager")
        var updatedThemes = activeThemes
        
        // Process newly discovered themes
        for discoveredTheme in discoveredThemes {
            if discoveredTheme.frequency >= minMentionsForTheme {
                if let existingIndex = updatedThemes.firstIndex(where: { $0.name.lowercased() == discoveredTheme.name.lowercased() }) {
                    // Update existing theme
                    let existingTheme = updatedThemes[existingIndex]
                    let updatedTheme = Theme(
                        name: existingTheme.name,
                        summary: discoveredTheme.summary,
                        frequency: max(existingTheme.frequency, discoveredTheme.frequency),
                        evolution: updateEvolution(existingTheme.evolution, with: discoveredTheme.evolution),
                        lastMentioned: Date(),
                        keyDates: (existingTheme.keyDates + [Date()]).suffix(10)
                    )
                    updatedThemes[existingIndex] = updatedTheme
                    logDebug("Updated existing theme: \(updatedTheme.name) with frequency \(updatedTheme.frequency)", category: "ThemeManager")
                } else {
                    // Add new theme
                    updatedThemes.append(discoveredTheme)
                    logDebug("Added new theme: \(discoveredTheme.name) with frequency \(discoveredTheme.frequency)", category: "ThemeManager")
                }
            }
        }
        
        // Archive inactive themes
        let archiveThemes = updatedThemes.filter { !$0.isActive }
        if !archiveThemes.isEmpty {
            logDebug("Archiving \(archiveThemes.count) inactive themes", category: "ThemeManager")
            saveArchivedThemes(archiveThemes)
        }
        
        // Keep only active themes in the main list
        updatedThemes = updatedThemes.filter { $0.isActive }
        
        // Sort by frequency and limit to max themes
        updatedThemes.sort { $0.frequency > $1.frequency }
        activeThemes = Array(updatedThemes.prefix(maxThemesTracked))
        logDebug("Final active themes: \(activeThemes.map { "\($0.name) (\($0.frequency))" })", category: "ThemeManager")
    }
    
    private func updateEvolution(_ currentEvolution: String, with newDescription: String) -> String {
        if currentEvolution.isEmpty {
            return newDescription
        }
        return "\(currentEvolution) → \(newDescription)"
    }
    
    // MARK: - Theme Analysis
    
    func analyzeThemeInDepth(_ theme: Theme) async -> DeepThemeAnalysis? {
        let relevantEntries = getRelevantEntriesForTheme(theme)
        do {
            return try await llmService.analyzeThemeInDepth(theme, relevantEntries: relevantEntries)
        } catch {
            ErrorHandlingService.shared.handle(
                FishbowlError.theme(.processingFailed),
                context: "Analyzing theme in depth: \(theme.name)"
            )
            return nil
        }
    }
    
    private func getRelevantEntriesForTheme(_ theme: Theme) -> [String] {
        var relevantEntries: [String] = []
        
        // Get entries from key dates
        for date in theme.keyDates.suffix(5) { // Last 5 mentions
            let fileName = formatDateForFileName(date)
            if let content = readThoughtsFromFile(fileName) {
                relevantEntries.append(content)
            }
        }
        
        // Also search for theme mentions in recent files
        let recentFiles = getRecentThoughtFiles().prefix(14) // Last 2 weeks
        for fileName in recentFiles {
            if let content = readThoughtsFromFile(fileName) {
                if content.lowercased().contains(theme.name.lowercased()) {
                    relevantEntries.append(content)
                }
            }
        }
        
        return relevantEntries
    }
    
    // MARK: - Historical Context
    
    func getHistoricalContext(for todaysThoughts: String) -> HistoricalContext {
        let relevantThemes = findRelevantThemes(in: todaysThoughts)
        
        return HistoricalContext(
            activeThemes: relevantThemes
        )
    }
    
    private func findRelevantThemes(in thoughts: String) -> [Theme] {
        let lowercasedThoughts = thoughts.lowercased()
        return activeThemes.filter { theme in
            let keywords = theme.name.lowercased().components(separatedBy: " ")
            return keywords.contains { lowercasedThoughts.contains($0) }
        }
    }
    

    
    // MARK: - Theme Updates
    
    func updateThemeAfterAnalysis(_ themeName: String, with newInsights: String) {
        if let index = activeThemes.firstIndex(where: { $0.name == themeName }) {
            let theme = activeThemes[index]
            activeThemes[index] = Theme(
                name: theme.name,
                summary: theme.summary,
                frequency: theme.frequency + 1,
                evolution: updateEvolution(theme.evolution, with: newInsights),
                lastMentioned: Date(),
                keyDates: theme.keyDates + [Date()]
            )
            saveThemeIndex()
        }
    }
    
    // MARK: - File Operations
    
    private func getRecentThoughts(days: Int) -> [String] {
        let dateUtils = DateUtils.shared
        let today = Date()
        var thoughts: [String] = []
        
        for i in 0..<days {
            let date = dateUtils.dateBySubtractingDays(i, from: today)
            let fileName = dateUtils.formatDateForFileName(date)
            if let content = readThoughtsFromFile(fileName) {
                thoughts.append(content)
            }
        }
        
        return thoughts
    }
    
    private func readThoughtsFromFile(_ fileName: String) -> String? {
        let fileURL = thoughtsDirectory.appendingPathComponent(fileName)
        
        do {
            let content = try FileUtils.shared.readFile(at: fileURL)
            // Split by entry separator and process each entry
            let entries = content.components(separatedBy: "\n\n---\n")
                .map { entry -> String in
                    // Remove timestamp line if present
                    let lines = entry.components(separatedBy: .newlines)
                    if lines.count > 1 && DateUtils.shared.parseISO8601Date(lines[0]) != nil {
                        return lines.dropFirst().joined(separator: "\n")
                    }
                    return entry
                }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n\n")
            
            return entries
        } catch {
            logError("Error reading thoughts from \(fileName): \(error)", category: "ThemeManager")
            return nil
        }
    }
    
    private func getRecentThoughtFiles() -> [String] {
        return FileUtils.shared.listThoughtFiles()
    }
    
    private func formatDateForFileName(_ date: Date) -> String {
        return DateUtils.shared.formatDateForFileName(date)
    }
    
    // MARK: - Persistence
    
    private func saveThemeIndex() {
        do {
            try FileUtils.shared.writeJSON(activeThemes, to: themeIndexFile)
        } catch {
            ErrorHandlingService.shared.handle(
                FishbowlError.theme(.saveFailed),
                context: "Saving theme index"
            )
        }
    }
    
    func saveThemes(_ themes: [Theme]) {
        logDebug("Saving \(themes.count) themes", category: "ThemeManager")
        var currentThemes = loadThemeIndex()
        currentThemes.append(contentsOf: themes)
        
        do {
            try FileUtils.shared.writeJSON(currentThemes, to: themeIndexFile, prettyPrinted: true)
            logDebug("Successfully saved themes to \(themeIndexFile.path)", category: "ThemeManager")
        } catch {
            logError("Failed to save themes: \(error)", category: "ThemeManager")
        }
    }
    
    private func loadThemeIndex() -> [Theme] {
        do {
            guard FileUtils.shared.fileExists(at: themeIndexFile) else {
                logDebug("Theme index file does not exist yet", category: "ThemeManager")
                return []
            }
            
            let themes = try FileUtils.shared.readJSON([Theme].self, from: themeIndexFile)
            logDebug("Loaded \(themes.count) themes from index", category: "ThemeManager")
            
            let activeThemes = themes.filter { $0.isActive }
            logDebug("Found \(activeThemes.count) active themes", category: "ThemeManager")
            activeThemes.forEach { theme in
                logDebug("Active theme: \(theme.name) (freq: \(theme.frequency), last: \(theme.lastMentioned))", category: "ThemeManager")
            }
            
            return activeThemes
        } catch {
            ErrorHandlingService.shared.handle(
                FishbowlError.theme(.loadFailed),
                context: "Loading theme index"
            )
            return []
        }
    }
    
    private func saveArchivedThemes(_ themes: [Theme]) {
        let archiveURL = themeIndexFile.deletingLastPathComponent().appendingPathComponent("archived_themes.json")
        
        do {
            var archivedThemes: [Theme] = []
            if FileUtils.shared.fileExists(at: archiveURL) {
                archivedThemes = try FileUtils.shared.readJSON([Theme].self, from: archiveURL)
            }
            
            // Add new themes to archive
            archivedThemes.append(contentsOf: themes)
            
            // Save updated archive
            try FileUtils.shared.writeJSON(archivedThemes, to: archiveURL, prettyPrinted: true)
            logDebug("Successfully archived themes", category: "ThemeManager")
        } catch {
            logError("Failed to save archived themes: \(error)", category: "ThemeManager")
        }
    }
    
    // MARK: - Utility Methods
    
    func shouldDiscoverThemes() -> Bool {
        guard let lastDiscovery = lastDiscoveryDate else { return true }
        let daysSinceDiscovery = Calendar.current.dateComponents([.day], from: lastDiscovery, to: Date()).day ?? 0
        return daysSinceDiscovery >= 3 // Discover themes every 3 days
    }
    
    func getThemeByName(_ name: String) -> Theme? {
        return activeThemes.first { $0.name.lowercased() == name.lowercased() }
    }
    
    func getTopThemes(_ count: Int = 5) -> [Theme] {
        return Array(activeThemes.prefix(count))
    }
    
    func getThemeFrequency(_ themeName: String) -> Int {
        return activeThemes.first { $0.name == themeName }?.frequency ?? 0
    }
    
    func getThemeEvolution(_ themeName: String) -> String {
        return activeThemes.first { $0.name == themeName }?.evolution ?? ""
    }
    
    // MARK: - Manual Theme Management
    
    func addManualTheme(_ name: String, description: String) {
        let newTheme = Theme(
            name: name,
            summary: description,
            frequency: 1,
            evolution: description,
            lastMentioned: Date(),
            keyDates: [Date()]
        )
        activeThemes.append(newTheme)
        saveThemeIndex()
    }
    
    func removeTheme(_ themeName: String) {
        activeThemes.removeAll { $0.name == themeName }
        saveThemeIndex()
    }
    
    func resetThemes() {
        activeThemes = []
        saveThemeIndex()
    }
} 

