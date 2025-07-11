//
//  SettingsView.swift
//  Scanner PDF
//
//  Created by user on 07.07.2025.
//


import SwiftUI
import SwiftData
import Foundation

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var storageManager: PDFStorageManager?
    
    @EnvironmentObject private var purchaseManager: PurchaseManager

    
    // User Preferences
    @AppStorage("defaultScanQuality") private var defaultScanQuality: ScanQuality = .high
    @AppStorage("autoSaveLocation") private var autoSaveLocation: SaveLocation = .app
    @AppStorage("enableHapticFeedback") private var enableHapticFeedback = true
    @AppStorage("enableAutoBackup") private var enableAutoBackup = false
    @AppStorage("maxStorageLimit") private var maxStorageLimit: Double = 1000 // MB
    @AppStorage("enableBiometricLock") private var enableBiometricLock = false
    @AppStorage("defaultNamingConvention") private var defaultNamingConvention: NamingConvention = .dateTime
    @AppStorage("enableOCR") private var enableOCR = true
    @AppStorage("compressionLevel") private var compressionLevel: CompressionLevel = .medium
    @AppStorage("enableDarkMode") private var enableDarkMode = false
    @AppStorage("enableNotifications") private var enableNotifications = true
    
    // State variables
    @State private var showingPaywall = false
    @State private var showingStorageAlert = false
    @State private var showingDeleteAllAlert = false
    @State private var showingExportOptions = false
    @State private var isExporting = false
    @State private var exportProgress: Double = 0.0
    @State private var storageUsed: Int64 = 0
    @State private var documentCount = 0
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - App Preferences Section
                Section {
                    // Premium Paywall Section (Top Priority)
                    if purchaseManager.subscriptionStatus == .notSubscribed {
                        premiumPaywallCard
                    }
                    
                    // Scan Quality
                    Picker("Default Scan Quality", selection: $defaultScanQuality) {
                        ForEach(ScanQuality.allCases, id: \.self) { quality in
                            HStack {
                                Image(systemName: quality.icon)
                                    .foregroundColor(quality.color)
                                Text(quality.displayName)
                            }
                            .tag(quality)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    // Naming Convention
                    Picker("Document Naming", selection: $defaultNamingConvention) {
                        ForEach(NamingConvention.allCases, id: \.self) { convention in
                            Text(convention.displayName).tag(convention)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    // Compression Level
                    Picker("PDF Compression", selection: $compressionLevel) {
                        ForEach(CompressionLevel.allCases, id: \.self) { level in
                            HStack {
                                Image(systemName: level.icon)
                                    .foregroundColor(level.color)
                                Text(level.displayName)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                } header: {
                    Label("Document Settings", systemImage: "doc.text.fill")
                } footer: {
                    Text("Configure how documents are scanned and saved by default.")
                }
                
                // MARK: - Features Section
                Section {
                    Toggle(isOn: $enableOCR) {
                        HStack {
                            Image(systemName: "text.viewfinder")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Optical Character Recognition")
                                    .font(.subheadline)
                                Text("Extract text from scanned documents")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Toggle(isOn: $enableHapticFeedback) {
                        HStack {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                                .foregroundColor(.orange)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Haptic Feedback")
                                    .font(.subheadline)
                                Text("Vibrate on interactions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Toggle(isOn: $enableNotifications) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notifications")
                                    .font(.subheadline)
                                Text("Get notified about important updates")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                } header: {
                    Label("Features", systemImage: "sparkles")
                }
                
                // MARK: - Security Section
                Section {
                    Toggle(isOn: $enableBiometricLock) {
                        HStack {
                            Image(systemName: "faceid")
                                .foregroundColor(.green)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Biometric Lock")
                                    .font(.subheadline)
                                Text("Secure app with Face ID or Touch ID")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                } header: {
                    Label("Security", systemImage: "lock.shield.fill")
                }
                
                // MARK: - Storage Section
                Section {
                    // Storage Usage
                    HStack {
                        Image(systemName: "externaldrive.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Storage Used")
                                .font(.subheadline)
                            Text(formatBytes(storageUsed))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(documentCount) docs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Storage Limit
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "gauge.high")
                                .foregroundColor(.orange)
                                .frame(width: 24, height: 24)
                            Text("Storage Limit")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(maxStorageLimit)) MB")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $maxStorageLimit, in: 100...5000, step: 100) {
                            Text("Storage Limit")
                        }
                        .accentColor(.orange)
                    }
                    
                    // Clean Up Storage
                    Button(action: { showingStorageAlert = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)
                            Text("Clear Cache")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                } header: {
                    Label("Storage Management", systemImage: "externaldrive.fill")
                } footer: {
                    Text("Manage how much storage the app can use. Cache includes temporary files and thumbnails.")
                }
                
                // MARK: - Backup & Export Section
                Section {
                    Toggle(isOn: $enableAutoBackup) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto Backup")
                                    .font(.subheadline)
                                Text("Automatically backup to iCloud")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Button(action: { showingExportOptions = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                                .foregroundColor(.green)
                                .frame(width: 24, height: 24)
                            Text("Export All Documents")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(isExporting)
                    
                } header: {
                    Label("Backup & Export", systemImage: "square.and.arrow.up.fill")
                }
                
                // MARK: - Appearance Section
                Section {
                    Picker("Save Location", selection: $autoSaveLocation) {
                        ForEach(SaveLocation.allCases, id: \.self) { location in
                            HStack {
                                Image(systemName: location.icon)
                                    .foregroundColor(location.color)
                                Text(location.displayName)
                            }
                            .tag(location)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                } header: {
                    Label("Default Locations", systemImage: "folder.fill")
                } footer: {
                    Text("Choose where new documents are saved by default.")
                }
                
                // MARK: - Danger Zone
                Section {
                    Button(action: { showingDeleteAllAlert = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)
                            Text("Delete All Documents")
                                .font(.subheadline)
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                    
                } header: {
                    Label("Danger Zone", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                } footer: {
                    Text("This action cannot be undone. All documents will be permanently deleted.")
                }
                
                // MARK: - App Information
                Section {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        Text("Version")
                            .font(.subheadline)
                        Spacer()
                        Text("1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: openAppStore) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .frame(width: 24, height: 24)
                            Text("Rate App")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: contactSupport) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.green)
                                .frame(width: 24, height: 24)
                            Text("Contact Support")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                } header: {
                    Label("About", systemImage: "info.circle.fill")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            setupStorageManager()
            updateStorageInfo()
        }
        .alert("Clear Cache", isPresented: $showingStorageAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("This will remove temporary files and thumbnails. Your documents will not be affected.")
        }
        .alert("Delete All Documents", isPresented: $showingDeleteAllAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                deleteAllDocuments()
            }
        } message: {
            Text("This will permanently delete all \(documentCount) documents. This action cannot be undone.")
        }
        .confirmationDialog("Export Options", isPresented: $showingExportOptions) {
            Button("Export as ZIP") {
                exportDocuments(format: .zip)
            }
            Button("Export to Files App") {
                exportDocuments(format: .files)
            }
            Button("Share via AirDrop") {
                exportDocuments(format: .airdrop)
            }
            Button("Cancel", role: .cancel) { }
        }
        .overlay {
            if isExporting {
                ExportProgressView(progress: exportProgress)
            }
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
                .withPurchaseManager()

        }
    }
    
    
    // MARK: - Premium Paywall Card (Top Section)
    private var premiumPaywallCard: some View {
        VStack(spacing: 0) {
            // Compact Header with Gradient
            HStack(spacing: 12) {
                // Crown icon with subtle glow
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upgrade to Pro")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text("Unlock all features")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.85))
                }
                
                Spacer()
                
                // CTA Button - Primary action
                Button(action: { showingPaywall = true }) {
                    Text("Try Free")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.2, blue: 0.8),
                        Color(red: 0.2, green: 0.4, blue: 0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        
        }
    }
    
    // MARK: - Helper Methods
    private func setupStorageManager() {
        if storageManager == nil {
            storageManager = PDFStorageManager(modelContext: modelContext)
        }
    }
    
    private func updateStorageInfo() {
        guard let manager = storageManager else { return }
        storageUsed = manager.getTotalStorageUsed()
        documentCount = manager.documents.count
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func clearCache() {
        // Implementation for clearing cache
        //storageManager?.clearCache()
        updateStorageInfo()
    }
    
    private func deleteAllDocuments() {
        // Implementation for deleting all documents
        //storageManager?.deleteAllDocuments()
        updateStorageInfo()
    }
    
    private func exportDocuments(format: ExportFormat) {
        isExporting = true
        exportProgress = 0.0
        
        Task {
            await performExport(format: format)
            await MainActor.run {
                isExporting = false
                exportProgress = 0.0
            }
        }
    }
    
    private func performExport(format: ExportFormat) async {
        // Implementation for exporting documents
        guard let manager = storageManager else { return }
        
        let documents = manager.documents
        let totalDocuments = documents.count
        
        for (index, document) in documents.enumerated() {
            // Simulate export progress
            await MainActor.run {
                exportProgress = Double(index) / Double(totalDocuments)
            }
            
            // Add export logic here based on format
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay for demo
        }
        
        await MainActor.run {
            exportProgress = 1.0
        }
    }
    
    private func openAppStore() {
        // Implementation for opening App Store
        if let url = URL(string: "https://apps.apple.com") {
            UIApplication.shared.open(url)
        }
    }
    
    private func contactSupport() {
        // Implementation for contacting support
        if let url = URL(string: "mailto:support@yourapp.com") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Supporting Enums and Types
enum ScanQuality: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case ultra = "ultra"
    
    var displayName: String {
        switch self {
        case .low: return "Low (Faster)"
        case .medium: return "Medium"
        case .high: return "High (Recommended)"
        case .ultra: return "Ultra (Slower)"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "speedometer"
        case .medium: return "gauge.medium"
        case .high: return "gauge.high"
        case .ultra: return "gauge.high.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .orange
        case .medium: return .yellow
        case .high: return .green
        case .ultra: return .blue
        }
    }
}

enum SaveLocation: String, CaseIterable {
    case app = "app"
    case files = "files"
    case icloud = "icloud"
    
    var displayName: String {
        switch self {
        case .app: return "App Storage"
        case .files: return "Files App"
        case .icloud: return "iCloud Drive"
        }
    }
    
    var icon: String {
        switch self {
        case .app: return "folder.fill"
        case .files: return "folder.badge.plus"
        case .icloud: return "icloud.and.arrow.up.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .app: return .blue
        case .files: return .orange
        case .icloud: return .cyan
        }
    }
}

enum NamingConvention: String, CaseIterable {
    case dateTime = "dateTime"
    case sequential = "sequential"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .dateTime: return "Date & Time"
        case .sequential: return "Sequential Numbers"
        case .custom: return "Custom Prompt"
        }
    }
}

enum CompressionLevel: String, CaseIterable {
    case none = "none"
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .none: return "No Compression"
        case .low: return "Low (Larger files)"
        case .medium: return "Medium (Recommended)"
        case .high: return "High (Smaller files)"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "doc.fill"
        case .low: return "archivebox"
        case .medium: return "archivebox.fill"
        case .high: return "archivebox.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .none: return .gray
        case .low: return .orange
        case .medium: return .blue
        case .high: return .green
        }
    }
}

enum ExportFormat {
    case zip
    case files
    case airdrop
}

// MARK: - Export Progress View
struct ExportProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(1.2)
                
                Text("Exporting Documents...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(Int(progress * 100))% Complete")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 10)
            )
            .padding(40)
        }
    }
}
