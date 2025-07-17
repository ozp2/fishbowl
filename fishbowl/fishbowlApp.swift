//
//  fishbowlApp.swift
//  fishbowl
//
//  Created by Olivia on 7/11/25.
//

import SwiftUI
import AppKit
import UserNotifications

@main
struct fishbowlApp: App {
    // Create the popover and status item
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        // No main window group
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var scheduler: SchedulerService!
    var notificationService: NotificationService!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize the notification service
        notificationService = NotificationService()
        UNUserNotificationCenter.current().delegate = self
        
        // Initialize the scheduler service
        scheduler = SchedulerService()
        
        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 375)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())

        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            // Use custom icon from asset catalog
            if let image = NSImage(named: "thoughts") {
                // Configure the image for menu bar display
                image.size = NSSize(width: 18, height: 18)
                image.isTemplate = true // This makes it adapt to light/dark menu bar
                button.image = image
            } else {
                // Fallback to system symbol if custom image not found
                button.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "Fishbowl")
            }
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        
        // Start the scheduler service
        scheduler.startScheduler()
        
        // Schedule recurring notifications
        notificationService.scheduleRecurringAnalysis()
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Stop the scheduler service
        scheduler.stopScheduler()
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .sound, .badge]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // Handle notification response - forward to both services
        notificationService.handleNotificationResponse(response)
        
        // Also handle scheduler-specific responses
        if let delegate = scheduler.notificationDelegate {
            delegate.userNotificationCenter(center, didReceive: response) {}
        }
    }
}
