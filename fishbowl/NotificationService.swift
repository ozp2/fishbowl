import Foundation
import UserNotifications
import SwiftUI

class NotificationService: ObservableObject {
    @Published var notificationPermission: UNAuthorizationStatus = .notDetermined
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init() {
        requestNotificationPermission()
    }
    
    private func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.notificationPermission = .authorized
                } else {
                    self.notificationPermission = .denied
                }
            }
        }
        
        // Check current permission status
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermission = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Intelligent Suggestions
    
    func sendIntelligentSuggestionsNotification(suggestions: [String]) {
        guard notificationPermission == .authorized && !suggestions.isEmpty else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "💡 Intelligent Suggestions"
        content.sound = .default
        
        if suggestions.count == 1 {
            content.body = suggestions.first ?? ""
        } else {
            content.body = "You have \(suggestions.count) personalized suggestions based on your patterns"
            content.subtitle = suggestions.prefix(2).joined(separator: " • ")
        }
        
        // Add action buttons
        let viewAction = UNNotificationAction(
            identifier: "view_suggestions",
            title: "View All",
            options: []
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "dismiss",
            title: "Dismiss",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "suggestions_category",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([category])
        content.categoryIdentifier = "suggestions_category"
        
        scheduleNotification(content: content, identifier: "suggestions_\(Date().timeIntervalSince1970)")
    }
    

    
    // MARK: - Contradictions
    
    func sendContradictionsNotification(contradictions: [String]) {
        guard notificationPermission == .authorized && !contradictions.isEmpty else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Thought Contradictions"
        content.sound = .default
        
        if contradictions.count == 1 {
            content.body = contradictions.first ?? ""
        } else {
            content.body = "Found \(contradictions.count) contradictions in your thinking"
            content.subtitle = contradictions.prefix(2).joined(separator: " • ")
        }
        
        scheduleNotification(content: content, identifier: "contradictions_\(Date().timeIntervalSince1970)")
    }
    
    // MARK: - Weekly Patterns
    
    func sendWeeklyPatternsNotification(patterns: [String]) {
        guard notificationPermission == .authorized && !patterns.isEmpty else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🔄 Weekly Patterns"
        content.sound = .default
        
        if patterns.count == 1 {
            content.body = patterns.first ?? ""
        } else {
            content.body = "Discovered \(patterns.count) patterns in your weekly thoughts"
            content.subtitle = patterns.prefix(2).joined(separator: " • ")
        }
        
        // Add action buttons
        let viewAction = UNNotificationAction(
            identifier: "view_patterns",
            title: "View Patterns",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "patterns_category",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([category])
        content.categoryIdentifier = "patterns_category"
        
        scheduleNotification(content: content, identifier: "patterns_\(Date().timeIntervalSince1970)")
    }
    
    // MARK: - Breakthroughs
    
    func sendBreakthroughsNotification(breakthroughs: [String]) {
        guard notificationPermission == .authorized && !breakthroughs.isEmpty else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🎯 Breakthroughs!"
        content.sound = .default
        
        if breakthroughs.count == 1 {
            content.body = breakthroughs.first ?? ""
        } else {
            content.body = "You had \(breakthroughs.count) breakthrough moments this week"
            content.subtitle = breakthroughs.prefix(2).joined(separator: " • ")
        }
        
        scheduleNotification(content: content, identifier: "breakthroughs_\(Date().timeIntervalSince1970)")
    }
    
    // MARK: - Personalized Actions
    
    func sendPersonalizedActionsNotification(actions: [String]) {
        guard notificationPermission == .authorized && !actions.isEmpty else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📝 Personalized Action Items"
        content.sound = .default
        
        if actions.count == 1 {
            content.body = actions.first ?? ""
        } else {
            content.body = "You have \(actions.count) personalized action items"
            content.subtitle = actions.prefix(2).joined(separator: " • ")
        }
        
        scheduleNotification(content: content, identifier: "actions_\(Date().timeIntervalSince1970)")
    }
    
    // MARK: - Theme Discovery
    
    func sendThemeDiscoveryNotification(themes: [String]) {
        guard notificationPermission == .authorized && !themes.isEmpty else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🏷️ New Themes Discovered"
        content.sound = .default
        
        if themes.count == 1 {
            content.body = "New recurring theme: \(themes.first ?? "")"
        } else {
            content.body = "Found \(themes.count) new recurring themes in your thoughts"
            content.subtitle = themes.prefix(3).joined(separator: " • ")
        }
        
        // Add action buttons
        let viewAction = UNNotificationAction(
            identifier: "view_themes",
            title: "View Themes",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "themes_category",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([category])
        content.categoryIdentifier = "themes_category"
        
        scheduleNotification(content: content, identifier: "themes_\(Date().timeIntervalSince1970)")
    }
    
    // MARK: - Legacy Support (for backward compatibility)
    
    func sendDailySummaryNotification(analysis: DailyAnalysisResult) {
        guard notificationPermission == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📊 Daily Analysis Complete"
        content.sound = .default
        
        if !analysis.themesToday.isEmpty {
            content.body = "Today's themes: \(analysis.themesToday.joined(separator: ", "))"
        } else {
            content.body = "Your daily thought analysis is ready"
        }
        
        scheduleNotification(content: content, identifier: "daily_summary_\(Date().timeIntervalSince1970)")
    }
    
    func sendWeeklySummaryNotification(analysis: WeeklyAnalyticsResult) {
        guard notificationPermission == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📈 Weekly Analysis Complete"
        content.sound = .default
        
        if !analysis.patternsDiscovered.isEmpty {
            content.body = "Discovered patterns: \(analysis.patternsDiscovered.count)"
        } else {
            content.body = "Your weekly thought analysis is ready"
        }
        
        scheduleNotification(content: content, identifier: "weekly_summary_\(Date().timeIntervalSince1970)")
    }
    
    // MARK: - Recurring Reminders
    
    func scheduleRecurringAnalysis() {
        scheduleDaily()
        scheduleWeekly()
        scheduleThemeDiscovery()
    }
    
    private func scheduleDaily() {
        let content = UNMutableNotificationContent()
        content.title = "🧠 Daily Thought Analysis"
        content.body = "Time to analyze today's thoughts for insights and patterns"
        content.sound = .default
        
        // Schedule for 8 PM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 20 // 8 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_analysis_reminder",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                logError("Error scheduling daily analysis reminder: \(error)", category: "NotificationService")
            }
        }
    }
    
    private func scheduleWeekly() {
        let content = UNMutableNotificationContent()
        content.title = "📊 Weekly Thought Analysis"
        content.body = "Time for your weekly pattern analysis and insights"
        content.sound = .default
        
        // Schedule for Sunday at 7 PM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 19 // 7 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly_analysis_reminder",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                logError("Error scheduling weekly analysis reminder: \(error)", category: "NotificationService")
            }
        }
    }
    
    private func scheduleThemeDiscovery() {
        // Don't schedule recurring reminders - theme discovery happens automatically every 3 days
        // when there's enough content. The scheduler handles the timing logic.
        logInfo("Theme discovery scheduling: Let SchedulerService handle theme discovery timing", category: "NotificationService")
    }
    
    // MARK: - Test Notification
    
    func sendTestNotification() {
        guard notificationPermission == .authorized else {
            logWarning("Notification permission not granted: \(notificationPermission)", category: "NotificationService")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🧪 Test Notification"
        content.body = "Notifications are working! Permission: \(notificationPermission)"
        content.sound = .default
        
        scheduleNotification(content: content, identifier: "test_notification_\(Date().timeIntervalSince1970)")
        logInfo("Test notification scheduled", category: "NotificationService")
    }
    
    // MARK: - Utility Methods
    
    private func scheduleNotification(content: UNMutableNotificationContent, identifier: String) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                logError("Error scheduling notification: \(error)", category: "NotificationService")
            }
        }
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    // Handle notification responses
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        switch response.actionIdentifier {
        case "view_suggestions":
            logInfo("User wants to view suggestions", category: "NotificationService")
        case "view_themes":
            logInfo("User wants to view themes", category: "NotificationService")
        case "view_patterns":
            logInfo("User wants to view patterns", category: "NotificationService")
        case "dismiss":
            logInfo("User dismissed notification", category: "NotificationService")
        default:
            break
        }
    }
} 