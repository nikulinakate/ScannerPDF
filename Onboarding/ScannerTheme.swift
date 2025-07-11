//
//  ScannerTheme.swift
//  Scanner PDF
//
//  Created by user on 11.07.2025.
//


//
//  ScannerTheme.swift
//  ScannerPro
//
//  Modern PDF Scanner App Theme System
//

import SwiftUI
import UIKit

// MARK: - Scanner App Theme System
struct ScannerTheme {
    
    // MARK: - Light Theme Colors
    // Primary scanner colors - modern, tech-forward
    static let lightPrimary = Color(red: 0.043, green: 0.522, blue: 0.898)      // Scan Blue (#0B85E5)
    static let lightSecondary = Color(red: 0.102, green: 0.737, blue: 0.612)    // Success Green (#1ABC9C)
    static let lightTertiary = Color(red: 0.945, green: 0.969, blue: 0.992)     // Light Scanner Tint (#F1F7FD)
    
    // Accent colors for scanning actions
    static let lightAccent = Color(red: 0.255, green: 0.412, blue: 0.882)       // Deep Scanner Blue (#4169E1)
    static let lightAccentSecondary = Color(red: 0.945, green: 0.518, blue: 0.094) // Scanner Orange (#F18418)
    
    // Background and surface colors
    static let lightBackground = Color(red: 0.992, green: 0.996, blue: 1.0)     // Pure Scan White (#FDFDFF)
    static let lightSurface = Color.white                                        // Clean White
    static let lightSurfaceSecondary = Color(red: 0.976, green: 0.988, blue: 0.996) // Light Document Gray (#F9FCFE)
    
    // Text colors optimized for scanning interface
    static let lightTextPrimary = Color(red: 0.067, green: 0.094, blue: 0.141)  // Scanner Dark (#111823)
    static let lightTextSecondary = Color(red: 0.341, green: 0.396, blue: 0.471) // Document Gray (#577078)
    static let lightTextTertiary = Color(red: 0.522, green: 0.576, blue: 0.647)  // Light Document Gray (#85939F)
    
    // MARK: - Dark Theme Colors
    // Dark mode optimized for scanning
    static let darkPrimary = Color(red: 0.365, green: 0.678, blue: 0.945)       // Bright Scanner Blue (#5DAD7F)
    static let darkSecondary = Color(red: 0.145, green: 0.824, blue: 0.694)     // Bright Green (#25D2B1)
    static let darkTertiary = Color(red: 0.141, green: 0.169, blue: 0.208)      // Dark Scanner (#243545)
    
    // Dark accent colors
    static let darkAccent = Color(red: 0.475, green: 0.733, blue: 0.984)        // Light Scanner Blue (#79BBFB)
    static let darkAccentSecondary = Color(red: 0.976, green: 0.631, blue: 0.239) // Bright Orange (#F9A13D)
    
    // Dark backgrounds
    static let darkBackground = Color(red: 0.051, green: 0.063, blue: 0.078)    // Scanner Dark (#0D1014)
    static let darkSurface = Color(red: 0.102, green: 0.125, blue: 0.153)       // Document Dark (#1A2027)
    static let darkSurfaceSecondary = Color(red: 0.141, green: 0.169, blue: 0.208) // Medium Dark (#243545)
    
    // Dark text colors
    static let darkTextPrimary = Color(red: 0.976, green: 0.984, blue: 0.992)   // Light Scanner Text (#F9FBFD)
    static let darkTextSecondary = Color(red: 0.698, green: 0.745, blue: 0.804) // Medium Scanner Gray (#B2BECD)
    static let darkTextTertiary = Color(red: 0.522, green: 0.576, blue: 0.647)  // Dim Scanner Gray (#85939F)
    
    // MARK: - Scanning Status Colors
    // Scan quality indicators
    static let scanExcellent = Color(red: 0.102, green: 0.737, blue: 0.612)     // Perfect Green (#1ABC9C)
    static let scanGood = Color(red: 0.180, green: 0.800, blue: 0.443)          // Good Green (#2ECC71)
    static let scanFair = Color(red: 0.945, green: 0.769, blue: 0.059)          // Warning Yellow (#F1C40F)
    static let scanPoor = Color(red: 0.906, green: 0.298, blue: 0.235)          // Poor Red (#E74C3C)
    
    // Scanner mode colors
    static let docScan = Color(red: 0.043, green: 0.522, blue: 0.898)           // Document Blue
    static let textScan = Color(red: 0.102, green: 0.737, blue: 0.612)          // Text Green
    static let photoScan = Color(red: 0.945, green: 0.518, blue: 0.094)         // Photo Orange
    static let qrScan = Color(red: 0.608, green: 0.349, blue: 0.714)            // QR Purple (#9B59B6)
    
    // Processing states
    static let processing = Color(red: 0.155, green: 0.678, blue: 0.937)        // Processing Blue (#27AEF0)
    static let completed = Color(red: 0.102, green: 0.737, blue: 0.612)         // Success Green
    static let failed = Color(red: 0.906, green: 0.298, blue: 0.235)            // Error Red
    
    // MARK: - Feature Status Colors
    // OCR and AI features
    static let ocrActive = Color(red: 0.478, green: 0.333, blue: 0.902)         // OCR Purple (#7A55E6)
    static let aiEnhance = Color(red: 0.173, green: 0.243, blue: 0.314)         // AI Dark Blue (#2C3E50)
    static let cloudSync = Color(red: 0.204, green: 0.596, blue: 0.859)         // Cloud Blue (#3498DB)
    
    // Premium features
    static let premium = Color(red: 0.902, green: 0.678, blue: 0.149)           // Premium Gold (#E6AD26)
    static let premiumLight = Color(red: 0.988, green: 0.976, blue: 0.941)      // Light Gold Tint
    static let premiumDark = Color(red: 0.722, green: 0.542, blue: 0.119)       // Dark Gold
    
    // MARK: - Gradient Collections
    static let scanningGradient = LinearGradient(
        colors: [lightPrimary, lightSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let processingGradient = LinearGradient(
        colors: [processing, lightPrimary],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let successGradient = LinearGradient(
        colors: [scanExcellent, scanGood],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let premiumGradient = LinearGradient(
        colors: [premium, premiumDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Scanner UI Specific Colors
    static let viewfinderFrame = Color(red: 0.043, green: 0.522, blue: 0.898)   // Scanner Frame Blue
    static let viewfinderCorner = Color.white                                    // Corner Markers
    static let flashlight = Color(red: 1.0, green: 0.973, blue: 0.863)          // Flash Yellow (#FFF8DC)
    
    // Document edge detection
    static let edgeDetected = Color(red: 0.102, green: 0.737, blue: 0.612)      // Good Edge Green
    static let edgeWeak = Color(red: 0.945, green: 0.769, blue: 0.059)          // Weak Edge Yellow
    static let edgeNone = Color(red: 0.906, green: 0.298, blue: 0.235)          // No Edge Red
    
    // MARK: - Shadow Variations
    static let shadowLight = Color.black.opacity(0.04)
    static let shadowMedium = Color.black.opacity(0.08)
    static let shadowHeavy = Color.black.opacity(0.16)
    static let shadowScanner = lightPrimary.opacity(0.15)
    
    // MARK: - Border Collections
    static let borderUltraLight = Color(red: 0.945, green: 0.957, blue: 0.973)  // Ultra Light
    static let borderLight = Color(red: 0.898, green: 0.918, blue: 0.945)       // Light Border
    static let borderMedium = Color(red: 0.827, green: 0.855, blue: 0.890)      // Medium Border
    static let borderDark = Color(red: 0.522, green: 0.576, blue: 0.647)        // Dark Border
    
    // MARK: - Chart Colors for Analytics
    static let analyticsColors: [Color] = [
        Color(red: 0.043, green: 0.522, blue: 0.898),  // Primary Blue
        Color(red: 0.102, green: 0.737, blue: 0.612),  // Success Green
        Color(red: 0.945, green: 0.518, blue: 0.094),  // Scanner Orange
        Color(red: 0.608, green: 0.349, blue: 0.714),  // Purple
        Color(red: 0.478, green: 0.333, blue: 0.902),  // OCR Purple
        Color(red: 0.902, green: 0.678, blue: 0.149),  // Premium Gold
        Color(red: 0.906, green: 0.298, blue: 0.235),  // Error Red
        Color(red: 0.204, green: 0.596, blue: 0.859)   // Cloud Blue
    ]
}

// MARK: - Theme Environment
extension EnvironmentValues {
    var scannerTheme: ScannerTheme.Type {
        get { ScannerTheme.self }
        set { }
    }
}

// MARK: - Adaptive Color System
extension ScannerTheme {
    static func adaptiveColor(
        light: Color,
        dark: Color
    ) -> Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                UIColor(dark) : UIColor(light)
        })
    }
    
    // Adaptive primary colors for scanner interface
    static let adaptivePrimary = adaptiveColor(light: lightPrimary, dark: darkPrimary)
    static let adaptiveSecondary = adaptiveColor(light: lightSecondary, dark: darkSecondary)
    static let adaptiveAccent = adaptiveColor(light: lightAccent, dark: darkAccent)
    static let adaptiveBackground = adaptiveColor(light: lightBackground, dark: darkBackground)
    static let adaptiveSurface = adaptiveColor(light: lightSurface, dark: darkSurface)
    static let adaptiveTextPrimary = adaptiveColor(light: lightTextPrimary, dark: darkTextPrimary)
    static let adaptiveTextSecondary = adaptiveColor(light: lightTextSecondary, dark: darkTextSecondary)
    static let adaptiveTextTertiary = adaptiveColor(light: lightTextTertiary, dark: darkTextTertiary)
    
    // Scanner-specific adaptive colors
    static let adaptiveScanFrame = adaptiveColor(light: viewfinderFrame, dark: darkAccent)
    static let adaptiveDocumentBackground = adaptiveColor(light: lightSurfaceSecondary, dark: darkSurfaceSecondary)
}