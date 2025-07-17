import Foundation
import SwiftUI
import Combine

class ThoughtAnalyzer: ObservableObject {
    private let llmService = LLMService()
    private let themeManager = ThemeManager()
    private let fileManager = FileManager.default
    private var thoughtsDirectory: URL
    private var analysisDirectory: URL
    private var cancellables = Set<AnyCancellable>()
    
    @Published var dailyAnalysis: DailyAnalysisResult?
    @Published var weeklyAnalysis: WeeklyAnalyticsResult?
    @Published var isAnalyzing = false
    @Published var lastAnalysisDate: Date?
    @Published var activeThemes: [Theme] = []
    @Published var selectedTheme: Theme?
    @Published var deepThemeAnalysis: DeepThemeAnalysis?
    
    init() {
        let fileUtils = FileUtils.shared
        thoughtsDirectory = fileUtils.thoughtsDirectory
        analysisDirectory = fileUtils.analysisDirectory
        
        try? fileUtils.createDirectoriesIfNeeded()
        
        setupThemeManagerObservation()
        loadSavedAnalysis()
    }
    
    // Analysis Status
    func shouldAnalyzeToday() -> Bool {
        guard let lastAnalysis = lastAnalysisDate else { return true }
        return !Calendar.current.isDate(lastAnalysis, inSameDayAs: Date())
    }
    
    func shouldAnalyzeWeekly() -> Bool {
        // Check if we have enough content for analysis
        let recentContent = readAccumulatedThoughts()
        let minimumEntriesForWeekly = 5  // Require at least 5 entries
        let minimumWordsForWeekly = 1000  // Require at least 1000 words total
        
        let entries = recentContent.filter { !$0.isEmpty }
        let totalWords = entries.joined(separator: " ").split(separator: " ").count
        
        // If we have enough content, check if it's been at least 3 days since last analysis
        if entries.count >= minimumEntriesForWeekly && totalWords >= minimumWordsForWeekly {
            guard let lastAnalysis = lastAnalysisDate else { return true }
            let daysSinceAnalysis = Calendar.current.dateComponents([.day], from: lastAnalysis, to: Date()).day ?? 0
            return daysSinceAnalysis >= 3  // Reduced from 7 to 3 days minimum between analyses
        }
        
        return false
    }
    
    func getAnalysisStatus() -> (hasDaily: Bool, hasWeekly: Bool, hasThemes: Bool) {
        return (
            hasDaily: dailyAnalysis != nil,
            hasWeekly: weeklyAnalysis != nil,
            hasThemes: !activeThemes.isEmpty
        )
    }
    
    // Utility Methods
    
    func getRecentThoughtFiles() -> [String] {
        return FileUtils.shared.listThoughtFiles()
    }
    
    func readThoughtsFromFile(_ fileName: String) -> String {
        let fileURL = thoughtsDirectory.appendingPathComponent(fileName)
        
        do {
            return try FileUtils.shared.readFile(at: fileURL)
        } catch {
            logError("Error reading thoughts from \(fileName): \(error)", category: "ThoughtAnalyzer")
            return ""
        }
    }
    
    func analyzeSpecificThoughts(_ content: String) async -> DailyAnalysisResult? {
        let historicalContext = themeManager.getHistoricalContext(for: content)
        do {
            return try await llmService.analyzeDailyThoughts(content, withHistoricalContext: historicalContext)
        } catch {
            logError("Error analyzing specific thoughts: \(error)", category: "ThoughtAnalyzer")
            return nil
        }
    }
    
    private func setupThemeManagerObservation() {
        logDebug("Setting up theme manager observation", category: "ThoughtAnalyzer")
        themeManager.$activeThemes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] themes in
                logDebug("Received \(themes.count) themes from ThemeManager", category: "ThoughtAnalyzer")
                self?.activeThemes = themes
            }
            .store(in: &cancellables)
    }
    
    private func loadSavedAnalysis() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Load daily analysis (get most recent from array)
        let todayFile = FileUtils.shared.analysisFileURL(for: Date(), prefix: "daily_analysis")
        do {
            let data = try Data(contentsOf: todayFile)
            let analyses = try decoder.decode([DailyAnalysisResult].self, from: data)
            dailyAnalysis = analyses.last // Get most recent analysis
            logInfo("Loaded daily analysis from \(todayFile.lastPathComponent) (total: \(analyses.count) analyses)", category: "ThoughtAnalyzer")
        } catch {
            logError("Failed to load daily analysis: \(error)", category: "ThoughtAnalyzer")
        }
        
        // Load last analysis date
        let dateFile = analysisDirectory.appendingPathComponent("last_analysis_date.json")
        do {
            let data = try Data(contentsOf: dateFile)
            lastAnalysisDate = try decoder.decode(Date.self, from: data)
            logInfo("Loaded last analysis date: \(lastAnalysisDate?.description ?? "nil")", category: "ThoughtAnalyzer")
        } catch {
            logError("Failed to load last analysis date: \(error)", category: "ThoughtAnalyzer")
        }
        
        // Load weekly analysis
        let weeklyFile = analysisDirectory.appendingPathComponent("weekly_analysis.json")
        do {
            let data = try Data(contentsOf: weeklyFile)
            weeklyAnalysis = try decoder.decode(WeeklyAnalyticsResult.self, from: data)
            logInfo("Loaded weekly analysis from \(weeklyFile.lastPathComponent)", category: "ThoughtAnalyzer")
        } catch {
            logError("Failed to load weekly analysis: \(error)", category: "ThoughtAnalyzer")
        }
    }
    
    private func saveAnalysis() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        // Save daily analysis (append to array)
        if let analysis = dailyAnalysis {
            let todayFile = FileUtils.shared.analysisFileURL(for: Date(), prefix: "daily_analysis")
            
            // Load existing analyses or create new array
            var existingAnalyses: [DailyAnalysisResult] = []
            if FileUtils.shared.fileExists(at: todayFile) {
                do {
                    existingAnalyses = try FileUtils.shared.readJSON([DailyAnalysisResult].self, from: todayFile)
                } catch {
                    logWarning("Could not load existing analyses, starting fresh: \(error)", category: "ThoughtAnalyzer")
                }
            }
            
            // Add new analysis to array
            existingAnalyses.append(analysis)
            
            // Save updated array
            do {
                try FileUtils.shared.writeJSON(existingAnalyses, to: todayFile, prettyPrinted: true)
                logInfo("Saved daily analysis to \(todayFile.lastPathComponent) (total: \(existingAnalyses.count) analyses)", category: "ThoughtAnalyzer")
            } catch {
                logError("Failed to save daily analysis: \(error)", category: "ThoughtAnalyzer")
            }
        }
        
        // Save last analysis date
        if let date = lastAnalysisDate {
            let dateFile = analysisDirectory.appendingPathComponent("last_analysis_date.json")
            do {
                try FileUtils.shared.writeJSON(date, to: dateFile, prettyPrinted: true)
                logInfo("Saved last analysis date", category: "ThoughtAnalyzer")
            } catch {
                logError("Failed to save analysis date: \(error)", category: "ThoughtAnalyzer")
            }
        }
        
        // Save weekly analysis
        if let analysis = weeklyAnalysis {
            let weeklyFile = analysisDirectory.appendingPathComponent("weekly_analysis.json")
            do {
                try FileUtils.shared.writeJSON(analysis, to: weeklyFile, prettyPrinted: true)
                logInfo("Saved weekly analysis", category: "ThoughtAnalyzer")
            } catch {
                logError("Failed to save weekly analysis: \(error)", category: "ThoughtAnalyzer")
            }
        }
    }
    
    func discoverThemes(fromRecentDays days: Int = 7) async {
        logDebug("Starting theme discovery process", category: "ThoughtAnalyzer")
        await themeManager.discoverThemes(fromRecentDays: days)
        logDebug("Theme discovery process completed", category: "ThoughtAnalyzer")
    }
    
    func shouldDiscoverThemes() -> Bool {
        logDebug("Checking if we should discover themes", category: "ThoughtAnalyzer")
        let shouldDiscover = themeManager.shouldDiscoverThemes()
        logDebug("Should discover themes: \(shouldDiscover)", category: "ThoughtAnalyzer")
        return shouldDiscover
    }
    
    func analyzeTodaysThoughts() async {
        await MainActor.run { isAnalyzing = true }
        
        let todaysContent = readTodaysThoughts()
        
        if !todaysContent.isEmpty {
            let historicalContext = themeManager.getHistoricalContext(for: todaysContent)
            do {
                let analysis = try await llmService.analyzeDailyThoughts(todaysContent, withHistoricalContext: historicalContext)
                
                await MainActor.run {
                    self.dailyAnalysis = analysis
                    self.lastAnalysisDate = Date()
                    self.isAnalyzing = false
                    
                    for theme in analysis.themesToday {
                        themeManager.updateThemeAfterAnalysis(theme, with: "Mentioned in today's thoughts")
                    }
                    
                    self.saveAnalysis()
                }
            } catch {
                ErrorHandlingService.shared.handle(
                    FishbowlError.analysis(.dailyAnalysisFailed),
                    context: "Analyzing today's thoughts"
                )
                await MainActor.run { 
                    self.isAnalyzing = false 
                }
            }
        } else {
            await MainActor.run { isAnalyzing = false }
        }
    }
    
    func analyzeWeeklyThoughts() async {
        await MainActor.run { isAnalyzing = true }
        
        let accumulatedContent = readAccumulatedThoughts()
        let activeThemes = themeManager.getTopThemes(5)
        
        if !accumulatedContent.isEmpty {
            do {
                let analysis = try await llmService.generateWeeklyAnalytics(themes: activeThemes, weeklyThoughts: accumulatedContent)
                
                await MainActor.run {
                    self.weeklyAnalysis = analysis
                    self.lastAnalysisDate = Date()
                    self.isAnalyzing = false
                    self.saveAnalysis()
                }
            } catch {
                ErrorHandlingService.shared.handle(
                    FishbowlError.analysis(.weeklyAnalysisFailed),
                    context: "Analyzing weekly thoughts"
                )
                await MainActor.run { 
                    self.isAnalyzing = false 
                }
            }
        } else {
            await MainActor.run { isAnalyzing = false }
        }
    }
    
    func analyzeThemeInDepth(_ theme: Theme) async {
        await MainActor.run {
            isAnalyzing = true
            selectedTheme = theme
        }
        
        let analysis = await themeManager.analyzeThemeInDepth(theme)
        
        await MainActor.run {
            self.deepThemeAnalysis = analysis
            self.isAnalyzing = false
        }
    }
    
    // Analysis Results
    
    func getDailyAnalyses(for date: Date = Date()) -> [DailyAnalysisResult] {
        let file = FileUtils.shared.analysisFileURL(for: date, prefix: "daily_analysis")
        
        do {
            return try FileUtils.shared.readJSON([DailyAnalysisResult].self, from: file)
        } catch {
            return []
        }
    }
    
    func getIntelligentSuggestions() -> [String] {
        return dailyAnalysis?.keyInsights ?? []
    }
    
    func getPersonalizedActions() -> [String] {
        return weeklyAnalysis?.personalizedActions ?? []
    }
    
    func getThemeSpecificSuggestions() -> [String] {
        return deepThemeAnalysis?.specificSuggestions ?? []
    }
    
    func getAllSuggestions() -> [String] {
        let daily = getIntelligentSuggestions()
        let weekly = getPersonalizedActions()
        let themeSpecific = getThemeSpecificSuggestions()
        return Array(Set(daily + weekly + themeSpecific))
    }
    

    
    func getContradictions() -> [String] {
        return []
    }
    
    func getProgressIndicators() -> [String] {
        return dailyAnalysis?.focusAreas ?? []
    }
    
    func getDiscoveredPatterns() -> [String] {
        return weeklyAnalysis?.patternsDiscovered ?? []
    }
    
    func getBreakthroughs() -> [String] {
        return weeklyAnalysis?.breakthroughs ?? []
    }
    
    func getObstacles() -> [String] {
        return weeklyAnalysis?.obstacles ?? []
    }
    
    func getProductivityInsights() -> [String] {
        return weeklyAnalysis?.productivityInsights ?? []
    }
    
    // Theme Management
    
    func getActiveThemes() -> [Theme] {
        return themeManager.activeThemes
    }
    
    func getTopThemes(_ count: Int = 5) -> [Theme] {
        return themeManager.getTopThemes(count)
    }
    
    func getThemeByName(_ name: String) -> Theme? {
        return themeManager.getThemeByName(name)
    }
    
    func addManualTheme(_ name: String, description: String) {
        themeManager.addManualTheme(name, description: description)
    }
    
    func removeTheme(_ themeName: String) {
        themeManager.removeTheme(themeName)
    }
    
    // File Operations
    
    private func readTodaysThoughts() -> String {
        let now = Date()
        let dateUtils = DateUtils.shared
        let fileUtils = FileUtils.shared
        
        // Get thoughts from the last 24 hours
        let twentyFourHoursAgo = Calendar.current.date(byAdding: .hour, value: -24, to: now) ?? now
        
        var recentThoughts: [String] = []
        
        // Check the last 3 days worth of files to ensure we don't miss anything
        // (in case entries span across midnight)
        for i in 0..<3 {
            let date = dateUtils.dateBySubtractingDays(i, from: now)
            let fileURL = fileUtils.thoughtFileURL(for: date)
            
            if fileUtils.fileExists(at: fileURL) {
                do {
                    let content = try fileUtils.readFile(at: fileURL)
                    if !content.isEmpty {
                        // Parse individual entries from the file content
                        let entries = parseEntriesFromContent(content)
                        
                        // Filter entries by their timestamps
                        for entry in entries {
                            if let entryDate = entry.timestamp, 
                               entryDate >= twentyFourHoursAgo && entryDate <= now {
                                recentThoughts.append(entry.content)
                            }
                        }
                    }
                } catch {
                    logError("Error reading thoughts from \(fileURL.path): \(error)", category: "ThoughtAnalyzer")
                }
            }
        }
        
        return recentThoughts.joined(separator: "\n\n")
    }
    
    // Helper struct to represent a parsed entry
    private struct ParsedEntry {
        let content: String
        let timestamp: Date?
    }
    
    // Helper method to parse entries from file content
    private func parseEntriesFromContent(_ content: String) -> [ParsedEntry] {
        var entries: [ParsedEntry] = []
        let dateUtils = DateUtils.shared
        
        // Split content by entry separator
        let rawEntries = content.components(separatedBy: "\n\n---\n")
        
        for rawEntry in rawEntries {
            let lines = rawEntry.components(separatedBy: .newlines)
            let trimmedEntry = rawEntry.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedEntry.isEmpty {
                continue
            }
            
            // Try to extract timestamp from the first line
            var timestamp: Date?
            var contentLines = lines
            
            if let firstLine = lines.first {
                // Try to parse as ISO 8601 date
                timestamp = dateUtils.parseISO8601Date(firstLine)
                if timestamp != nil {
                    // Remove timestamp line from content
                    contentLines = Array(lines.dropFirst())
                }
            }
            
            let entryContent = contentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !entryContent.isEmpty {
                entries.append(ParsedEntry(content: entryContent, timestamp: timestamp))
            }
        }
        
        return entries
    }
    
    private func readAccumulatedThoughts() -> [String] {
        let dateUtils = DateUtils.shared
        let fileUtils = FileUtils.shared
        let today = Date()
        var accumulatedThoughts: [String] = []
        var totalWords = 0
        let maxDays = 14  // Look back up to 14 days maximum
        
        for i in 0..<maxDays {
            let date = dateUtils.dateBySubtractingDays(i, from: today)
            let fileURL = fileUtils.thoughtFileURL(for: date)
            
            if fileUtils.fileExists(at: fileURL) {
                do {
                    let content = try fileUtils.readFile(at: fileURL)
                    if !content.isEmpty {
                        // Parse individual entries from the file content
                        let entries = parseEntriesFromContent(content)
                        
                        // Add entries to accumulated thoughts
                        for entry in entries {
                            accumulatedThoughts.append(entry.content)
                            totalWords += entry.content.split(separator: " ").count
                            
                            // If we have enough content, we can stop looking back further
                            if accumulatedThoughts.count >= 5 && totalWords >= 1000 {
                                return accumulatedThoughts
                            }
                        }
                    }
                } catch {
                    let fileName = dateUtils.formatDateForFileName(date)
                    logError("Error reading thoughts for \(fileName): \(error)", category: "ThoughtAnalyzer")
                }
            }
        }
        
        return accumulatedThoughts
    }
} 