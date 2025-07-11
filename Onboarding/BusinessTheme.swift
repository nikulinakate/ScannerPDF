//
//  BusinessTheme.swift
//  InvoiceApp
//
//  Created by Nikulina Ekaterina on 30.06.2025.
//

import SwiftUI
import StoreKit

// MARK: - Enhanced Professional Theme System
struct BusinessTheme {
    
    // MARK: - Light Theme Colors
    // Primary brand colors - modern, trustworthy blues
    static let lightPrimary = Color(red: 0.067, green: 0.188, blue: 0.392)      // Rich Navy (#112F64)
    static let lightSecondary = Color(red: 0.235, green: 0.404, blue: 0.671)    // Professional Blue (#3C67AB)
    static let lightTertiary = Color(red: 0.918, green: 0.941, blue: 0.973)     // Light Blue Tint (#EAF0F8)
    
    // Accent colors for actions and highlights
    static let lightAccent = Color(red: 0.118, green: 0.565, blue: 0.906)       // Vibrant Blue (#1E90E7)
    static let lightAccentSecondary = Color(red: 0.204, green: 0.780, blue: 0.349) // Success Green (#34C759)
    
    // Background and surface colors
    static let lightBackground = Color(red: 0.988, green: 0.992, blue: 0.996)   // Cool White (#FCFDFE)
    static let lightSurface = Color.white                                        // Pure White
    static let lightSurfaceSecondary = Color(red: 0.969, green: 0.976, blue: 0.988) // Light Gray (#F7F9FC)
    
    // Text colors with better contrast
    static let lightTextPrimary = Color(red: 0.086, green: 0.106, blue: 0.133)  // Dark Charcoal (#161B22)
    static let lightTextSecondary = Color(red: 0.384, green: 0.427, blue: 0.486) // Medium Gray (#626D7C)
    static let lightTextTertiary = Color(red: 0.565, green: 0.608, blue: 0.667)  // Light Gray (#909BAA)
    
    // MARK: - Dark Theme Colors
    // Primary colors for dark mode
    static let darkPrimary = Color(red: 0.949, green: 0.957, blue: 0.973)       // Light Gray (#F2F4F8)
    static let darkSecondary = Color(red: 0.718, green: 0.757, blue: 0.816)     // Medium Gray (#B7C1D0)
    static let darkTertiary = Color(red: 0.169, green: 0.192, blue: 0.224)      // Dark Blue (#2B3139)
    
    // Accent colors for dark mode
    static let darkAccent = Color(red: 0.392, green: 0.706, blue: 1.0)          // Bright Blue (#64B4FF)
    static let darkAccentSecondary = Color(red: 0.196, green: 0.843, blue: 0.294) // Bright Green (#32D74B)
    
    // Background colors for dark mode
    static let darkBackground = Color(red: 0.043, green: 0.051, blue: 0.063)    // Very Dark (#0B0D10)
    static let darkSurface = Color(red: 0.094, green: 0.110, blue: 0.133)       // Dark Gray (#181C22)
    static let darkSurfaceSecondary = Color(red: 0.133, green: 0.153, blue: 0.180) // Medium Dark (#222730)
    
    // Text colors for dark mode
    static let darkTextPrimary = Color(red: 0.969, green: 0.976, blue: 0.988)   // Light White (#F7F9FC)
    static let darkTextSecondary = Color(red: 0.718, green: 0.757, blue: 0.816) // Medium Gray (#B7C1D0)
    static let darkTextTertiary = Color(red: 0.565, green: 0.608, blue: 0.667)  // Dim Gray (#909BAA)
    
    // MARK: - Status and Semantic Colors
    // Success states
    static let success = Color(red: 0.204, green: 0.780, blue: 0.349)           // Green (#34C759)
    static let successLight = Color(red: 0.922, green: 0.973, blue: 0.933)      // Light Green Tint (#EBF8EE)
    static let successDark = Color(red: 0.157, green: 0.600, blue: 0.267)       // Dark Green (#289943)
    
    // Warning states
    static let warning = Color(red: 1.0, green: 0.584, blue: 0.0)               // Orange (#FF9500)
    static let warningLight = Color(red: 1.0, green: 0.953, blue: 0.922)        // Light Orange Tint (#FFF3EB)
    static let warningDark = Color(red: 0.800, green: 0.467, blue: 0.0)         // Dark Orange (#CC7700)
    
    // Error states
    static let error = Color(red: 1.0, green: 0.231, blue: 0.188)               // Red (#FF3B30)
    static let errorLight = Color(red: 1.0, green: 0.941, blue: 0.941)          // Light Red Tint (#FFF0F0)
    static let errorDark = Color(red: 0.800, green: 0.185, blue: 0.150)         // Dark Red (#CC2F26)
    
    // Information states
    static let info = Color(red: 0.118, green: 0.565, blue: 0.906)              // Blue (#1E90E7)
    static let infoLight = Color(red: 0.922, green: 0.953, blue: 0.988)         // Light Blue Tint (#EBF3FC)
    static let infoDark = Color(red: 0.094, green: 0.452, blue: 0.725)          // Dark Blue (#1873B9)
    
    // MARK: - Business Status Colors
    // Premium subscription
    static let premium = Color(red: 0.918, green: 0.667, blue: 0.137)           // Gold (#EAA923)
    static let premiumLight = Color(red: 0.988, green: 0.976, blue: 0.941)      // Light Gold Tint (#FCF9F0)
    static let premiumDark = Color(red: 0.734, green: 0.533, blue: 0.110)       // Dark Gold (#BB881C)
    
    // Trial period
    static let trial = Color(red: 0.463, green: 0.827, blue: 0.463)             // Fresh Green (#76D376)
    static let trialLight = Color(red: 0.953, green: 0.988, blue: 0.953)        // Light Green Tint (#F3FCF3)
    static let trialDark = Color(red: 0.370, green: 0.662, blue: 0.370)         // Dark Green (#5EA95E)
    
    // Paid status
    static let paid = Color(red: 0.204, green: 0.780, blue: 0.349)              // Success Green
    static let pending = Color(red: 1.0, green: 0.584, blue: 0.0)               // Warning Orange
    static let overdue = Color(red: 1.0, green: 0.231, blue: 0.188)             // Error Red
    
    // MARK: - Gradient Colors
    static let primaryGradient = LinearGradient(
        colors: [lightPrimary, lightSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [lightAccent, Color(red: 0.078, green: 0.451, blue: 0.725)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [success, successDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Shadow Colors
    static let shadowLight = Color.black.opacity(0.05)
    static let shadowMedium = Color.black.opacity(0.10)
    static let shadowDark = Color.black.opacity(0.20)
    
    // MARK: - Border Colors
    static let borderLight = Color(red: 0.918, green: 0.933, blue: 0.953)       // Light Border (#EAF0F3)
    static let borderMedium = Color(red: 0.839, green: 0.863, blue: 0.902)      // Medium Border (#D6DCE6)
    static let borderDark = Color(red: 0.565, green: 0.608, blue: 0.667)        // Dark Border (#909BAA)
    
    // MARK: - Chart Colors (for invoice analytics)
    static let chartColors: [Color] = [
        Color(red: 0.118, green: 0.565, blue: 0.906),  // Blue
        Color(red: 0.204, green: 0.780, blue: 0.349),  // Green
        Color(red: 1.0, green: 0.584, blue: 0.0),      // Orange
        Color(red: 0.918, green: 0.667, blue: 0.137),  // Gold
        Color(red: 0.463, green: 0.827, blue: 0.463),  // Light Green
        Color(red: 0.678, green: 0.463, blue: 0.827),  // Purple
        Color(red: 0.827, green: 0.463, blue: 0.580),  // Pink
        Color(red: 0.463, green: 0.718, blue: 0.827)   // Light Blue
    ]
}

// MARK: - Theme Environment
extension EnvironmentValues {
    var businessTheme: BusinessTheme.Type {
        get { BusinessTheme.self }
        set { }
    }
}

// MARK: - Color Scheme Adaptive Colors
extension BusinessTheme {
    static func adaptiveColor(
        light: Color,
        dark: Color
    ) -> Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                UIColor(dark) : UIColor(light)
        })
    }
    
    // Adaptive primary colors
    static let adaptivePrimary = adaptiveColor(light: lightPrimary, dark: darkPrimary)
    static let adaptiveSecondary = adaptiveColor(light: lightSecondary, dark: darkSecondary)
    static let adaptiveAccent = adaptiveColor(light: lightAccent, dark: darkAccent)
    static let adaptiveBackground = adaptiveColor(light: lightBackground, dark: darkBackground)
    static let adaptiveSurface = adaptiveColor(light: lightSurface, dark: darkSurface)
    static let adaptiveTextPrimary = adaptiveColor(light: lightTextPrimary, dark: darkTextPrimary)
    static let adaptiveTextSecondary = adaptiveColor(light: lightTextSecondary, dark: darkTextSecondary)
    static let adaptiveTextTertiary = adaptiveColor(light: lightTextTertiary, dark: darkTextTertiary)
}
