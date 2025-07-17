import Foundation
import SwiftUI
import UserNotifications

class SchedulerService: ObservableObject {
    private let thoughtAnalyzer = ThoughtAnalyzer()
    private let notificationService = NotificationService()
    private var analysisTimer: Timer?
    private var dailyTimer: Timer?
    private var weeklyTimer: Timer?
    var notificationDelegate: NotificationDelegate?
    
    @Published var isRunning = false
    @Published var lastDailyAnalysis: Date?
    @Published var lastWeeklyAnalysis: Date?
    @Published var lastThemeDiscovery: Date?
    
    init() {
        setupNotificationDelegate()
        loadAnalysisHistory()
    }
    
    private func setupNotificationDelegate() {
        notificationDelegate = NotificationDelegate(scheduler: self)
        // Don't set delegate here - AppDelegate handles it
    }
    
    deinit {
        stopScheduler()
    }
    
    private func loadAnalysisHistory() {
        // Load from UserDefaults
        if let dailyDate = UserDefaults.standard.object(forKey: "lastDailyAnalysis") as? Date {
            lastDailyAnalysis = dailyDate
        }
        
        if let weeklyDate = UserDefaults.standard.object(forKey: "lastWeeklyAnalysis") as? Date {
            lastWeeklyAnalysis = weeklyDate
        }
        
        if let themeDate = UserDefaults.standard.object(forKey: "lastThemeDiscovery") as? Date {
            lastThemeDiscovery = themeDate
        }
    }
    
    private func saveAnalysisHistory() {
        if let dailyDate = lastDailyAnalysis {
            UserDefaults.standard.set(dailyDate, forKey: "lastDailyAnalysis")
        }
        
        if let weeklyDate = lastWeeklyAnalysis {
            UserDefaults.standard.set(weeklyDate, forKey: "lastWeeklyAnalysis")
        }
        
        if let themeDate = lastThemeDiscovery {
            UserDefaults.standard.set(themeDate, forKey: "lastThemeDiscovery")
        }
    }
    
    func startScheduler() {
        guard !isRunning else { return }
        
        isRunning = true
        scheduleNotifications()
        setupPeriodicChecks()
        
        // Run initial analysis if needed
        Task {
            await performInitialAnalysisIfNeeded()
        }
    }
    
    func stopScheduler() {
        isRunning = false
        analysisTimer?.invalidate()
        dailyTimer?.invalidate()
        weeklyTimer?.invalidate()
        notificationService.cancelAllNotifications()
    }
    
    private func scheduleNotifications() {
        notificationService.scheduleRecurringAnalysis()
    }
    
    private func setupPeriodicChecks() {
        // Check every hour for analysis opportunities
        analysisTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task {
                await self.performScheduledAnalysis()
            }
        }
        
        // Set up daily analysis timer (8 PM)
        setupDailyTimer()
        
        // Set up weekly analysis timer (Sunday 7 PM)
        setupWeeklyTimer()
    }
    
    private func setupDailyTimer() {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate next 8 PM
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 20
        components.minute = 0
        components.second = 0
        
        guard let nextDaily = calendar.date(from: components) else { return }
        let adjustedDaily = nextDaily < now ? calendar.date(byAdding: .day, value: 1, to: nextDaily)! : nextDaily
        
        let timeInterval = adjustedDaily.timeIntervalSince(now)
        
        dailyTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            Task {
                await self.performDailyAnalysis()
            }
            // Reschedule for next day
            self.setupDailyTimer()
        }
    }
    
    private func setupWeeklyTimer() {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate next Sunday at 7 PM
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 1 // Sunday
        components.hour = 19
        components.minute = 0
        components.second = 0
        
        guard let nextWeekly = calendar.date(from: components) else { return }
        let adjustedWeekly = nextWeekly < now ? calendar.date(byAdding: .weekOfYear, value: 1, to: nextWeekly)! : nextWeekly
        
        let timeInterval = adjustedWeekly.timeIntervalSince(now)
        
        weeklyTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            Task {
                await self.performWeeklyAnalysis()
            }
            // Reschedule for next week
            self.setupWeeklyTimer()
        }
    }
    
    private func performInitialAnalysisIfNeeded() async {
        // Check if we need to discover themes
        if shouldDiscoverThemes() {
            await performThemeDiscovery()
        }
        
        // Check if we need to run daily analysis
        if shouldRunDailyAnalysis() {
            await performDailyAnalysis()
        }
        
        // Check if we need to run weekly analysis
        if shouldRunWeeklyAnalysis() {
            await performWeeklyAnalysis()
        }
    }
    
    private func performScheduledAnalysis() async {
        // Discover themes periodically
        if shouldDiscoverThemes() {
            await performThemeDiscovery()
        }
        
        if shouldRunDailyAnalysis() {
            await performDailyAnalysis()
        }
        
        if shouldRunWeeklyAnalysis() {
            await performWeeklyAnalysis()
        }
    }
    
    @MainActor
    private func performThemeDiscovery() async {
        logInfo("Starting theme discovery...", category: "SchedulerService")
        
        await thoughtAnalyzer.discoverThemes()
        
        // Send theme discovery notification
        let themes = thoughtAnalyzer.getActiveThemes()
        if !themes.isEmpty {
            let themeNames = themes.map { $0.name }
            notificationService.sendThemeDiscoveryNotification(themes: themeNames)
        }
        
        lastThemeDiscovery = Date()
        saveAnalysisHistory()
    }
    
    @MainActor
    private func performDailyAnalysis() async {
        logInfo("Starting daily scheduled analysis...", category: "SchedulerService")
        
        await thoughtAnalyzer.analyzeTodaysThoughts()
        
        // Only proceed with notifications if we have valid analysis results
        guard thoughtAnalyzer.dailyAnalysis != nil else {
            logInfo("Daily analysis completed but no results available", category: "SchedulerService")
            return
        }
        
        // Send intelligent suggestions notification
        let suggestions = thoughtAnalyzer.getIntelligentSuggestions()
        if !suggestions.isEmpty {
            notificationService.sendIntelligentSuggestionsNotification(suggestions: suggestions)
        }
        
        // Send contradictions notification if any
        let contradictions = thoughtAnalyzer.getContradictions()
        if !contradictions.isEmpty {
            notificationService.sendContradictionsNotification(contradictions: contradictions)
        }
        
        lastDailyAnalysis = Date()
        saveAnalysisHistory()
    }
    
    @MainActor
    private func performWeeklyAnalysis() async {
        logInfo("Starting weekly analysis...", category: "SchedulerService")
        
        await thoughtAnalyzer.analyzeWeeklyThoughts()
        
        // Only proceed with notifications if we have valid analysis results
        guard thoughtAnalyzer.weeklyAnalysis != nil else {
            logInfo("Weekly analysis completed but no results available", category: "SchedulerService")
            return
        }
        
        // Send weekly patterns notification
        let patterns = thoughtAnalyzer.getDiscoveredPatterns()
        if !patterns.isEmpty {
            notificationService.sendWeeklyPatternsNotification(patterns: patterns)
        }
        
        // Send breakthroughs notification
        let breakthroughs = thoughtAnalyzer.getBreakthroughs()
        if !breakthroughs.isEmpty {
            notificationService.sendBreakthroughsNotification(breakthroughs: breakthroughs)
        }
        
        // Send personalized actions notification
        let actions = thoughtAnalyzer.getPersonalizedActions()
        if !actions.isEmpty {
            notificationService.sendPersonalizedActionsNotification(actions: actions)
        }
        
        lastWeeklyAnalysis = Date()
        saveAnalysisHistory()
    }
    
    private func shouldDiscoverThemes() -> Bool {
        guard let lastDiscovery = lastThemeDiscovery else { return true }
        let daysSinceDiscovery = Calendar.current.dateComponents([.day], from: lastDiscovery, to: Date()).day ?? 0
        return daysSinceDiscovery >= 3 // Discover themes every 3 days
    }
    
    private func shouldRunDailyAnalysis() -> Bool {
        guard let lastDaily = lastDailyAnalysis else { return true }
        return !Calendar.current.isDate(lastDaily, inSameDayAs: Date())
    }
    
    private func shouldRunWeeklyAnalysis() -> Bool {
        guard let lastWeekly = lastWeeklyAnalysis else { return true }
        let daysSinceAnalysis = Calendar.current.dateComponents([.day], from: lastWeekly, to: Date()).day ?? 0
        return daysSinceAnalysis >= 7
    }
    
    // Manual triggers
    func triggerDailyAnalysis() {
        Task {
            await performDailyAnalysis()
        }
    }
    
    func triggerWeeklyAnalysis() {
        Task {
            await performWeeklyAnalysis()
        }
    }
    
    func triggerThemeDiscovery() {
        Task {
            await performThemeDiscovery()
        }
    }
    
    // Get current analysis status
    func getAnalysisStatus() -> (daily: Bool, weekly: Bool, themes: Bool) {
        let thoughtStatus = thoughtAnalyzer.getAnalysisStatus()
        return (
            daily: thoughtStatus.hasDaily,
            weekly: thoughtStatus.hasWeekly,
            themes: thoughtStatus.hasThemes
        )
    }
    
    // Get current insights
    func getCurrentSuggestions() -> [String] {
        return thoughtAnalyzer.getAllSuggestions()
    }
    
    func getActiveThemes() -> [Theme] {
        return thoughtAnalyzer.getActiveThemes()
    }
    

    
    func getContradictions() -> [String] {
        return thoughtAnalyzer.getContradictions()
    }
    
    func getPatterns() -> [String] {
        return thoughtAnalyzer.getDiscoveredPatterns()
    }
    
    func getBreakthroughs() -> [String] {
        return thoughtAnalyzer.getBreakthroughs()
    }
}

// Notification delegate to handle notification responses
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private unowned let scheduler: SchedulerService
    
    init(scheduler: SchedulerService) {
        self.scheduler = scheduler
        super.init()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification actions
        switch response.actionIdentifier {
        case "view_suggestions":
            logInfo("User wants to view suggestions", category: "SchedulerService")
        case "view_themes":
            logInfo("User wants to view themes", category: "SchedulerService")
        case "view_patterns":
            logInfo("User wants to view patterns", category: "SchedulerService")
        case "dismiss":
            logInfo("User dismissed notification", category: "SchedulerService")
        default:
            // Handle default tap
            if response.notification.request.identifier.contains("daily_analysis_reminder") {
                scheduler.triggerDailyAnalysis()
            } else if response.notification.request.identifier.contains("weekly_analysis_reminder") {
                scheduler.triggerWeeklyAnalysis()
            } else if response.notification.request.identifier.contains("theme_discovery_reminder") {
                scheduler.triggerThemeDiscovery()
            }
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }
} 