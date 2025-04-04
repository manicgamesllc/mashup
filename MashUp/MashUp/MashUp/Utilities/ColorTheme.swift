import SwiftUI

struct ColorTheme {
    // Remove the Environment property wrapper
    // And add methods that take colorScheme as parameter
    
    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.05, green: 0.1, blue: 0.25) : .white
    }
    
    static func primary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : Color(red: 0.0, green: 0.12, blue: 0.35)
    }
    
    static func secondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.0, green: 0.12, blue: 0.35) : .white
    }
    
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.1, green: 0.15, blue: 0.3) : Color(.secondarySystemBackground)
    }
    
    static func textColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : Color(red: 0.0, green: 0.12, blue: 0.35)
    }
    
    // Keep original properties for backward compatibility
    static let primary = Color(red: 0.0, green: 0.12, blue: 0.35) // Dark Navy Blue
    static let secondary = Color.white
    static let cardBackground = Color(.secondarySystemBackground)
    static let accent = Color(red: 0.1, green: 0.2, blue: 0.45) // Slightly lighter blue
}
