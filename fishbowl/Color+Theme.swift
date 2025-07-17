import SwiftUI
import AppKit

extension Color {
    // Background colors that adapt to light/dark mode
    static let surface = Color(
        light: Color(red: 0xF8/255, green: 0xFA/255, blue: 0xF8/255),
        dark: Color(red: 0x1C/255, green: 0x1C/255, blue: 0x1E/255)
    )
    
    static let surfaceContainer = Color(
        light: Color(red: 0xEF/255, green: 0xF1/255, blue: 0xEF/255),
        dark: Color(red: 0x2C/255, green: 0x2C/255, blue: 0x2E/255)
    )
    
    // Text colors that adapt to light/dark mode
    static let mainText = Color(
        light: Color(red: 0x29/255, green: 0x1d/255, blue: 0x15/255),
        dark: Color(red: 0xF2/255, green: 0xF2/255, blue: 0xF7/255)
    )
    
    // Accent color
    static let accent = Color(
        light: Color(red: 60/255, green: 72/255, blue: 172/255),
        dark: Color(red: 114/255, green: 135/255, blue: 253/255)
    )
    
    // Status colors
    static let lightRed = Color(
        light: Color(red: 0xcc/255, green: 0x3f/255, blue: 0x0c/255),
        dark: Color(red: 0xFF/255, green: 0x69/255, blue: 0x58/255)
    )
    
    static let errorRed = Color(
        light: Color(red: 0xcc/255, green: 0x3f/255, blue: 0x0c/255),
        dark: Color(red: 0xFF/255, green: 0x69/255, blue: 0x58/255)
    )
    
    static let success = Color(
        light: Color(red: 0x55/255, green: 0x8B/255, blue: 0x6E/255),
        dark: Color(red: 0x30/255, green: 0xD1/255, blue: 0x58/255)
    )
    
    static let successLight = Color(
        light: Color(red: 0xD6/255, green: 0xEA/255, blue: 0xDF/255),
        dark: Color(red: 0x1A/255, green: 0x3A/255, blue: 0x2E/255)
    )
}

extension Color {
    init(light: Color, dark: Color) {
        self.init(NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(dark)
            } else {
                return NSColor(light)
            }
        })
    }
} 