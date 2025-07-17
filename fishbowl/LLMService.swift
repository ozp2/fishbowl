import Foundation
import Network

enum LLMServiceError: Error, Equatable {
    case modelNotAvailable
    case invalidRequest
    case networkError(String)
    case responseParsingError
    case serverError(Int)
    case unknownError
    
    var localizedDescription: String {
        switch self {
        case .modelNotAvailable:
            return "AI model is not available. Please ensure Ollama is running and the model is installed."
        case .invalidRequest:
            return "Invalid request format."
        case .networkError(let errorDescription):
            return "Network error: \(errorDescription)"
        case .responseParsingError:
            return "Failed to parse AI response."
        case .serverError(let code):
            return "Server returned error \(code)"
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}

class LLMService: ObservableObject {
    // MARK: - Configuration
    
    struct ModelConfig {
        let name: String
        let temperature: Double
        let topP: Double
        let maxTokens: Int?
        let contextWindow: Int
        
        static let defaultConfig = ModelConfig(
            name: "gemma3:4b",
            temperature: 0.7,
            topP: 0.9,
            maxTokens: 2048,
            contextWindow: 8192
        )
        
        static let creativeConfig = ModelConfig(
            name: "gemma3:4b",
            temperature: 0.85,
            topP: 0.95,
            maxTokens: 2048,
            contextWindow: 8192
        )
        
        static let preciseConfig = ModelConfig(
            name: "gemma3:4b",
            temperature: 0.5,
            topP: 0.8,
            maxTokens: 2048,
            contextWindow: 8192
        )
    }
    
    private let ollamaURL: String
    private let config: ModelConfig
    private let maxRetries: Int
    private let retryDelay: TimeInterval
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.fishbowl.network.monitor")
    
    @Published private(set) var isAvailable = false
    @Published private(set) var isProcessing = false
    @Published private(set) var lastError: LLMServiceError?
    @Published private(set) var networkIsAvailable = true
    
    init(
        ollamaURL: String = "http://localhost:11434",
        config: ModelConfig = .defaultConfig,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 2.0
    ) {
        // Validate Ollama URL for security
        if let url = URL(string: ollamaURL), SecurityUtils.shared.validateURL(url) {
            self.ollamaURL = ollamaURL
        } else {
            logWarning("Invalid Ollama URL provided, using default: \(ollamaURL)", category: "LLMService")
            self.ollamaURL = "http://localhost:11434"
        }
        
        self.config = config
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        
        setupNetworkMonitoring()
        checkOllamaAvailability()
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.networkIsAvailable = path.status == .satisfied
                if self?.networkIsAvailable == true {
                    self?.checkOllamaAvailability()
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    private func checkOllamaAvailability() {
        guard let url = URL(string: "\(ollamaURL)/api/tags") else {
            updateStatus(error: .invalidRequest)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.updateStatus(error: .networkError(error.localizedDescription))
                } else if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        self?.updateStatus(error: nil)
                    } else {
                        self?.updateStatus(error: .serverError(httpResponse.statusCode))
                    }
                } else {
                    self?.updateStatus(error: .unknownError)
                }
            }
        }
        task.resume()
    }
    
    private func updateStatus(error: LLMServiceError?) {
        isAvailable = error == nil
        lastError = error
        if !isAvailable {
            isProcessing = false
        }
    }
    
    // MARK: - Request Handling
    
    private func makeRequest(_ prompt: String, timeout: TimeInterval = 30, useExponentialBackoff: Bool = false) async throws -> String {
        guard isAvailable && networkIsAvailable else {
            throw lastError ?? .modelNotAvailable
        }
        
        let requestBody: [String: Any] = [
            "model": config.name,
            "prompt": prompt,
            "stream": false,
            "options": [
                "temperature": config.temperature,
                "top_p": config.topP
            ]
        ]
        
        guard let url = URL(string: "\(ollamaURL)/api/generate"),
              let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw LLMServiceError.invalidRequest
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = timeout
        
        var currentDelay = retryDelay
        for attempt in 1...maxRetries {
            do {
                if timeout > 30 {
                    logDebug("Long request attempt \(attempt) of \(maxRetries)", category: "LLMService")
                }
                
                await MainActor.run { 
                    isProcessing = true
                    lastError = nil
                }
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw LLMServiceError.unknownError
                }
                
                guard httpResponse.statusCode == 200 else {
                    if timeout > 30 {
                        logError("Server returned status code: \(httpResponse.statusCode)", category: "LLMService")
                        if let errorData = String(data: data, encoding: .utf8) {
                            logError("Server response: \(errorData)", category: "LLMService")
                        }
                    }
                    throw LLMServiceError.serverError(httpResponse.statusCode)
                }
                
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let responseText = json["response"] as? String else {
                    if timeout > 30 {
                        logError("Failed to parse response", category: "LLMService")
                        if let responseStr = String(data: data, encoding: .utf8) {
                            logError("Raw response: \(responseStr)", category: "LLMService")
                        }
                    }
                    throw LLMServiceError.responseParsingError
                }
                
                if timeout > 30 {
                    logDebug("Long request completed successfully", category: "LLMService")
                }
                
                await MainActor.run { 
                    isProcessing = false
                    lastError = nil
                }
                
                return responseText
            } catch {
                if timeout > 30 {
                    logError("Request failed: \(error.localizedDescription)", category: "LLMService")
                }
                
                if attempt == maxRetries {
                    await MainActor.run {
                        isProcessing = false
                        lastError = error as? LLMServiceError ?? .networkError(error.localizedDescription)
                    }
                    throw error
                }
                
                // Use exponential backoff with jitter for long requests
                let delay = useExponentialBackoff ? currentDelay + Double.random(in: 0...0.5) : retryDelay
                if timeout > 30 {
                    logDebug("Retrying in \(delay) seconds...", category: "LLMService")
                }
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                if useExponentialBackoff {
                    currentDelay *= 2
                }
            }
        }
        
        throw LLMServiceError.unknownError
    }

    // MARK: - Public Interface
    
    func discoverThemes(from content: String) async throws -> [Theme] {
        logDebug("Starting theme discovery with content length: \(content.count)", category: "LLMService")
        
        let prompt = generateThemeDiscoveryPrompt(content)
        let response = try await makeRequest(prompt, timeout: 120, useExponentialBackoff: true)
        
        do {
            let themes = try parseThemeDiscoveryResponse(response)
            logDebug("Successfully discovered \(themes.count) themes", category: "LLMService")
            return themes
        } catch {
            logError("LLM Service error during theme discovery: \(error.localizedDescription)", category: "LLMService")
            logError("Full error details: \(error)", category: "LLMService")
            throw error
        }
    }
    
    func analyzeDailyThoughts(_ todaysThoughts: String, withHistoricalContext context: HistoricalContext) async throws -> DailyAnalysisResult {
        let prompt = generateDailyAnalysisPrompt(thoughts: todaysThoughts, context: context)
        let response = try await makeRequest(prompt)
        return try parseDailyAnalysisResponse(response)
    }
    
    func generateWeeklyAnalytics(themes: [Theme], weeklyThoughts: [String]) async throws -> WeeklyAnalyticsResult {
        let prompt = generateWeeklyAnalyticsPrompt(themes: themes, thoughts: weeklyThoughts)
        let response = try await makeRequest(prompt)
        return try parseWeeklyAnalyticsResponse(response)
    }
    
    func analyzeThemeInDepth(_ theme: Theme, relevantEntries: [String]) async throws -> DeepThemeAnalysis {
        let prompt = generateThemeAnalysisPrompt(theme: theme, entries: relevantEntries)
        let response = try await makeRequest(prompt)
        return try parseDeepThemeAnalysisResponse(response)
    }
    
    // MARK: - Prompt Generation
    
    private func generateThemeDiscoveryPrompt(_ content: String) -> String {
        return """
        You are a thoughtful analysis assistant. Your task is to identify recurring themes in this journal entry.

        Instructions:
        1. Analyze the thoughts and identify 3-5 most significant recurring themes
        2. For each theme provide:
           - Name: 2-3 words maximum
           - Summary: Write a 1-2 sentence personal summary using "you" instead of "the narrator". For example: "You're experiencing intense pressure about the upcoming interview" instead of "The narrator experiences pressure"
           - Frequency: Number of meaningful mentions
           - Examples: 1-2 key quotes
           - Evolution: Brief note on how this theme has developed, using personal language

        Format as JSON:
        {
          "themes": [
            {
              "name": "Career Transition",
              "summary": "You're focused on preparing for your upcoming interview while managing the pressure of needing to secure a job soon",
              "frequency": 3,
              "examples": ["quote 1"],
              "evolution": "Your concerns have shifted from general job search to specific interview preparation"
            }
          ]
        }

        Keep responses personal and empathetic, using "you" and "your" instead of third-person language.
        """
    }
    
    private func generateDailyAnalysisPrompt(thoughts: String, context: HistoricalContext) -> String {
        // Sanitize input for security
        let todaysThoughts = SecurityUtils.shared.sanitizeForLLM(thoughts)
        let contextSummary = context.activeThemes.map { "\($0.name): \($0.summary)" }.joined(separator: "\n")
        
        return """
        Analyze your thoughts from the past 24 hours and identify meaningful patterns and themes. Do not suggest therapy or counseling.

        YOUR THOUGHTS FROM THE PAST 24 HOURS:
        \(todaysThoughts)

        YOUR CURRENT ACTIVE THEMES:
        \(contextSummary)

        Provide a complete analysis with the following sections:
        1. Key themes in your recent thoughts
        2. Overarching areas of your life (Personal Growth, Relationships, Work, Creative Projects)
        3. Important patterns or recurring ideas in your thinking
        4. Areas of your life that might need attention or support
        5. Notable progress or insights you've gained

        Important: Never suggest therapy, counseling, or professional mental health services.

        IMPORTANT: Your response must be valid JSON wrapped in triple backticks like this:
        ```json
        {
            "themes_today": ["Theme 1", "Theme 2"],
            "overarching_areas": ["Area 1", "Area 2"],
            "key_insights": ["Insight 1", "Insight 2"],
            "focus_areas": ["Focus Area 1", "Focus Area 2"]
        }
        ```

        Write complete sentences and avoid using ellipses or truncation. Do not include any text outside the JSON block. Each item should be a full, meaningful statement that directly addresses you and your experiences.
        """
    }
    
    private func generateWeeklyAnalyticsPrompt(themes: [Theme], thoughts: [String]) -> String {
        let themesSummary = themes.map { "\($0.name): \($0.summary)\nHow often it comes up: \($0.frequency) times\nHow it's evolved: \($0.evolution)" }.joined(separator: "\n\n")
        let thoughtsSummary = thoughts.enumerated().map { "Entry \($0.offset + 1): \($0.element)" }.joined(separator: "\n\n")
        
        return """
        Let's look at how your thoughts and ideas have developed recently.

        YOUR ACTIVE THEMES:
        \(themesSummary)

        YOUR RECENT THOUGHTS:
        \(thoughtsSummary)

        I'll help you understand:
        1. How your perspective on each theme has grown
        2. Any patterns or cycles you might want to know about
        3. Your 'aha!' moments and realizations
        4. Challenges you're working through
        5. When and how you do your best thinking
        6. How your energy and mood flow throughout your entries
        7. Ideas for what might help you move forward

        I'll keep things practical and focused on what matters to you.

        Format your response as a JSON object with these exact fields:
        {
            "theme_evolution": ["Evolution 1", "Evolution 2"],
            "patterns_discovered": ["Pattern 1", "Pattern 2"],
            "breakthroughs": ["Breakthrough 1", "Breakthrough 2"],
            "obstacles": ["Obstacle 1", "Obstacle 2"],
            "productivity_insights": ["Insight 1", "Insight 2"],
            "emotional_patterns": ["Pattern 1", "Pattern 2"],
            "personalized_actions": ["Action 1", "Action 2"]
        }

        Keep responses natural and personal, like we're having a conversation about your experiences.
        """
    }
    
    private func generateThemeAnalysisPrompt(theme: Theme, entries: [String]) -> String {
        let themeSummary = theme.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let relevantEntriesSummary = entries.joined(separator: "\n\n")
        
        return """
        Let's dive deeper into this theme that keeps showing up in your thoughts.

        THEME: \(theme.name)
        WHAT IT'S ABOUT: \(themeSummary)
        HOW OFTEN IT COMES UP: \(theme.frequency) times
        HOW IT'S CHANGED: \(theme.evolution)

        RELATED THOUGHTS FROM YOUR PAST:
        \(relevantEntriesSummary)

        I'll help you explore:
        1. How your thinking on this has evolved
        2. What tends to bring this topic to mind
        3. How you typically approach this
        4. What's worked well for you
        5. What makes this a recurring theme
        6. Ideas that might be helpful going forward

        Let's keep this conversational and focused on what's meaningful to you.

        Format your response as a JSON object with these exact fields:
        {
            "evolution_analysis": "How your perspective has grown over time",
            "triggers": ["What brings this up 1", "What brings this up 2"],
            "patterns": ["How you approach it 1", "How you approach it 2"],
            "discovered_solutions": ["What's worked 1", "What's worked 2"],
            "stuck_points": ["Challenge 1", "Challenge 2"],
            "specific_suggestions": ["Idea 1", "Idea 2"]
        }

        Keep responses natural and direct, like we're having a thoughtful conversation about your experiences.
        """
    }
    
    // MARK: - Response Parsing
    
    private func parseThemeDiscoveryResponse(_ response: String) throws -> [Theme] {
        logDebug("Raw LLM response: \(response)", category: "LLMService")
        
        // First try to extract JSON from markdown code blocks if present
        let jsonString: String
        if response.contains("```json") {
            let components = response.components(separatedBy: "```json")
            if components.count > 1 {
                let jsonBlock = components[1].components(separatedBy: "```")[0]
                jsonString = jsonBlock.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                jsonString = response
            }
        } else {
            jsonString = response
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            logError("Could not convert response to data", category: "LLMService")
            throw LLMServiceError.responseParsingError
        }
        
        do {
            // Parse the outer JSON structure
            let outerJSON = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            logDebug("Parsed outer JSON: \(String(describing: outerJSON))", category: "LLMService")
            
            guard let themesArray = outerJSON?["themes"] as? [[String: Any]] else {
                logError("Could not find themes array in JSON", category: "LLMService")
                throw LLMServiceError.responseParsingError
            }
            
            // Convert each theme dictionary to Theme object
            return try themesArray.map { themeDict in
                guard let name = themeDict["name"] as? String,
                      let summary = themeDict["summary"] as? String,
                      let frequency = themeDict["frequency"] as? Int,
                      let _ = themeDict["examples"] as? [String],
                      let evolution = themeDict["evolution"] as? String else {
                    logError("Missing required fields in theme: \(themeDict)", category: "LLMService")
                    throw LLMServiceError.responseParsingError
                }
                
                return Theme(
                    name: name,
                    summary: summary,
                    frequency: frequency,
                    evolution: evolution,
                    lastMentioned: Date(),
                    keyDates: [Date()]
                )
            }
        } catch {
            logError("JSON parsing error: \(error)", category: "LLMService")
            throw LLMServiceError.responseParsingError
        }
    }
    
    private func parseDailyAnalysisResponse(_ response: String) throws -> DailyAnalysisResult {
        guard let jsonData = extractJSON(from: response),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw LLMServiceError.responseParsingError
        }
        
        let themes = cleanupTextArray(json["themes_today"])
        let areas = cleanupTextArray(json["overarching_areas"])
        let insights = cleanupTextArray(json["key_insights"])
        let focus = cleanupTextArray(json["focus_areas"])
        
        return DailyAnalysisResult(
            themesToday: themes,
            overarchingAreas: areas,
            keyInsights: insights,
            focusAreas: focus
        )
    }
    
    private func parseWeeklyAnalyticsResponse(_ response: String) throws -> WeeklyAnalyticsResult {
        guard let jsonData = extractJSON(from: response),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw LLMServiceError.responseParsingError
        }
        
        return WeeklyAnalyticsResult(
            themeEvolution: cleanupTextArray(json["theme_evolution"]),
            patternsDiscovered: cleanupTextArray(json["patterns_discovered"]),
            breakthroughs: cleanupTextArray(json["breakthroughs"]),
            obstacles: cleanupTextArray(json["obstacles"]),
            productivityInsights: cleanupTextArray(json["productivity_insights"]),
            emotionalPatterns: cleanupTextArray(json["emotional_patterns"]),
            personalizedActions: cleanupTextArray(json["personalized_actions"])
        )
    }
    
    private func parseDeepThemeAnalysisResponse(_ response: String) throws -> DeepThemeAnalysis {
        guard let jsonData = extractJSON(from: response),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw LLMServiceError.responseParsingError
        }
        
        return DeepThemeAnalysis(
            evolutionAnalysis: (json["evolution_analysis"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            triggers: cleanupTextArray(json["triggers"]),
            patterns: cleanupTextArray(json["patterns"]),
            discoveredSolutions: cleanupTextArray(json["discovered_solutions"]),
            stuckPoints: cleanupTextArray(json["stuck_points"]),
            specificSuggestions: cleanupTextArray(json["specific_suggestions"])
        )
    }
    
    // MARK: - Helper Functions
    
    private func cleanupTextArray(_ value: Any?) -> [String] {
        guard let array = value as? [String] else { return [] }
        return array.map { text in
            text.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\\\"", with: "\"")
        }
    }
    
    private func extractJSON(from text: String) -> Data? {
        // First try to find JSON between triple backticks
        if let codeBlockRange = text.range(of: "```json\\n.*\\n```", options: .regularExpression) {
            let jsonText = text[codeBlockRange]
                .replacingOccurrences(of: "```json\n", with: "")
                .replacingOccurrences(of: "\n```", with: "")
            return jsonText.data(using: .utf8)
        }
        
        // Then try to find any JSON object
        if let jsonRange = text.range(of: "\\{[^\\{\\}]*\\}", options: .regularExpression) {
            let jsonText = String(text[jsonRange])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return jsonText.data(using: .utf8)
        }
        
        return nil
    }
}

// MARK: - Data Structures

struct ThemeDiscoveryResult {
    let discoveredThemes: [DiscoveredTheme]
}

struct DiscoveredTheme {
    let name: String
    let description: String
    let frequency: Int
    let examples: [String]
    let evolution: String
}

struct DailyAnalysisResult: Codable {
    let themesToday: [String]
    let overarchingAreas: [String]
    let keyInsights: [String]
    let focusAreas: [String]
}

struct WeeklyAnalyticsResult: Codable {
    let themeEvolution: [String]
    let patternsDiscovered: [String]
    let breakthroughs: [String]
    let obstacles: [String]
    let productivityInsights: [String]
    let emotionalPatterns: [String]
    let personalizedActions: [String]
}

struct DeepThemeAnalysis: Codable {
    let evolutionAnalysis: String
    let triggers: [String]
    let patterns: [String]
    let discoveredSolutions: [String]
    let stuckPoints: [String]
    let specificSuggestions: [String]
}

struct HistoricalContext {
    let activeThemes: [Theme]
}

struct Theme: Codable, Identifiable {
    let name: String
    let summary: String
    let frequency: Int
    let evolution: String
    let lastMentioned: Date
    let keyDates: [Date]
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name, summary, frequency, evolution, lastMentioned, keyDates
    }
    
    var isActive: Bool {
        let now = Date()
        // If lastMentioned is in the future, consider it active
        if lastMentioned > now {
            return true
        }
        let daysSinceLastMention = Calendar.current.dateComponents([.day], from: lastMentioned, to: now).day ?? 0
        return daysSinceLastMention <= 14 // Theme is active if mentioned in last 2 weeks
    }
    
    var activityLevel: String {
        if frequency >= 10 {
            return "Very Active"
        } else if frequency >= 5 {
            return "Active"
        } else {
            return "Emerging"
        }
    }
    
    var lastMentionDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: lastMentioned, relativeTo: Date())
    }
} 