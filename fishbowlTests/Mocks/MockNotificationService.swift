import Foundation
import UserNotifications
@testable import fishbowl

class MockNotificationService: ObservableObject {
    @Published var notificationPermission: UNAuthorizationStatus = .notDetermined
    
    var shouldFailPermission = false
    var scheduledNotifications: [String] = []
    var permissionGranted = true
    
    func requestNotificationPermission() {
        if shouldFailPermission {
            notificationPermission = .denied
        } else {
            notificationPermission = permissionGranted ? .authorized : .denied
        }
    }
    
    func scheduleRecurringAnalysis() {
        if notificationPermission == .authorized {
            scheduledNotifications.append("recurring_analysis")
        }
    }
    
    func scheduleIntelligentSuggestion(_ suggestion: String) {
        if notificationPermission == .authorized {
            scheduledNotifications.append("suggestion: \(suggestion)")
        }
    }
    
    func schedulePersonalizedAction(_ action: String) {
        if notificationPermission == .authorized {
            scheduledNotifications.append("action: \(action)")
        }
    }
    
    func scheduleThemeReminder(_ themeName: String) {
        if notificationPermission == .authorized {
            scheduledNotifications.append("theme: \(themeName)")
        }
    }
    
    func scheduleProgressUpdate(_ progress: String) {
        if notificationPermission == .authorized {
            scheduledNotifications.append("progress: \(progress)")
        }
    }
    
    func cancelAllNotifications() {
        scheduledNotifications.removeAll()
    }
    
    // Test helpers
    func reset() {
        notificationPermission = .notDetermined
        shouldFailPermission = false
        scheduledNotifications.removeAll()
        permissionGranted = true
    }
    
    func simulatePermissionDenied() {
        shouldFailPermission = true
        permissionGranted = false
        notificationPermission = .denied
    }
    
    func simulatePermissionGranted() {
        shouldFailPermission = false
        permissionGranted = true
        notificationPermission = .authorized
    }
    
    func getScheduledNotifications() -> [String] {
        return scheduledNotifications
    }
    
    func getNotificationCount() -> Int {
        return scheduledNotifications.count
    }
    
    func hasScheduledNotification(containing text: String) -> Bool {
        return scheduledNotifications.contains { $0.contains(text) }
    }
} 