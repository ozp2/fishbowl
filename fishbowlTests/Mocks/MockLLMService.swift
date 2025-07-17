import Foundation
@testable import fishbowl

class MockLLMService: ObservableObject {
    @Published var isAvailable = true
    @Published var isProcessing = false
    @Published var lastError: LLMServiceError?
    @Published var networkIsAvailable = true
    
    var shouldFail = false
    var processingDelay: TimeInterval = 0.0
    var mockError: LLMServiceError?
    
    // Mock responses
    var mockDailyAnalysis = DailyAnalysisResult(
        themesToday: ["productivity", "learning"],
        overarchingAreas: ["Work", "Personal Growth"],
        keyInsights: ["You're focusing on skill development", "Work-life balance is important"],
        focusAreas: ["Time management", "Goal setting"]
    )
    
    var mockWeeklyAnalysis = WeeklyAnalyticsResult(
        themeEvolution: ["Productivity focus has strengthened", "Learning goals have become clearer"],
        patternsDiscovered: ["Morning productivity peaks", "Afternoon energy dips"],
        breakthroughs: ["New project approach", "Better communication"],
        obstacles: ["Time constraints", "Distractions"],
        productivityInsights: ["Focus blocks work well", "Meetings interrupt flow"],
        emotionalPatterns: ["Morning optimism", "Afternoon stress"],
        personalizedActions: ["Schedule deep work in mornings", "Limit afternoon meetings"]
    )
    
    var mockThemes = [
        Theme(name: "productivity", summary: "Focus on getting things done", frequency: 5, evolution: "Growing stronger", lastMentioned: Date(), keyDates: [Date()]),
        Theme(name: "learning", summary: "Continuous skill development", frequency: 3, evolution: "Becoming more focused", lastMentioned: Date(), keyDates: [Date()])
    ]
    
    func generateDailyAnalysis(thoughts: [String]) async throws -> DailyAnalysisResult {
        if shouldFail {
            throw mockError ?? LLMServiceError.networkError("Mock network error")
        }
        
        if processingDelay > 0 {
            await MainActor.run { isProcessing = true }
            try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
            await MainActor.run { isProcessing = false }
        }
        
        return mockDailyAnalysis
    }
    
    func generateWeeklyAnalytics(themes: [Theme], weeklyThoughts: [String]) async throws -> WeeklyAnalyticsResult {
        if shouldFail {
            throw mockError ?? LLMServiceError.networkError("Mock network error")
        }
        
        if processingDelay > 0 {
            await MainActor.run { isProcessing = true }
            try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
            await MainActor.run { isProcessing = false }
        }
        
        return mockWeeklyAnalysis
    }
    
    func discoverThemes(from thoughts: String) async throws -> [Theme] {
        if shouldFail {
            throw mockError ?? LLMServiceError.networkError("Mock network error")
        }
        
        if processingDelay > 0 {
            await MainActor.run { isProcessing = true }
            try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
            await MainActor.run { isProcessing = false }
        }
        
        return mockThemes
    }
    
    func analyzeThemeInDepth(_ theme: Theme, relevantEntries: [String]) async throws -> DeepThemeAnalysis {
        if shouldFail {
            throw mockError ?? LLMServiceError.networkError("Mock network error")
        }
        
        if processingDelay > 0 {
            await MainActor.run { isProcessing = true }
            try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
            await MainActor.run { isProcessing = false }
        }
        
        return DeepThemeAnalysis(
            evolutionAnalysis: "This theme has evolved significantly",
            triggers: ["Morning routine", "Work meetings"],
            patterns: ["Mentioned weekly", "Linked to goals"],
            discoveredSolutions: ["Time blocking", "Priority setting"],
            stuckPoints: ["Procrastination", "Overwhelm"],
            specificSuggestions: ["Set daily reminders", "Track progress weekly"]
        )
    }
    
    func checkAvailability() async -> Bool {
        return isAvailable
    }
    
    func analyzeDailyThoughts(_ todaysThoughts: String, withHistoricalContext context: HistoricalContext) async throws -> DailyAnalysisResult {
        if shouldFail {
            throw mockError ?? LLMServiceError.networkError("Mock network error")
        }
        
        if processingDelay > 0 {
            await MainActor.run { isProcessing = true }
            try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
            await MainActor.run { isProcessing = false }
        }
        
        return mockDailyAnalysis
    }
    
    // Test helpers
    func reset() {
        shouldFail = false
        processingDelay = 0.0
        mockError = nil
        isAvailable = true
        isProcessing = false
        lastError = nil
        networkIsAvailable = true
    }
    
    func simulateNetworkError() {
        shouldFail = true
        mockError = LLMServiceError.networkError("Simulated network error")
        networkIsAvailable = false
    }
    
    func simulateProcessingDelay(_ delay: TimeInterval) {
        processingDelay = delay
    }
} 