import SwiftUI
import SwiftData
import Foundation
import PDFKit
import PhotosUI
import VisionKit
import UniformTypeIdentifiers


// MARK: - Import Option Enum
enum ImportOption {
    case camera
    case photoLibrary
    case files
}

// MARK: - Main Content View
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var storageManager: PDFStorageManager?
    @State private var searchText = ""
    @State private var selectedTag = ""
    @State private var showingFavoritesOnly = false
    @State private var showingImportMenu = false
    @State private var showingDocumentScanner = false
    @State private var showingImagePicker = false
    @State private var showingFilePicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var isProcessing = false
    @State private var fabExpanded = false
    @State private var showingQuickActions = false
    @State private var showingSettings = false

    var filteredDocuments: [ScannedDocument] {
        guard let manager = storageManager else { return [] }
        
        var documents = manager.documents
        
        if showingFavoritesOnly {
            documents = documents.filter { $0.isFavorite }
        }
        
        if !selectedTag.isEmpty {
            documents = documents.filter { $0.tags.contains(selectedTag) }
        }
        
        if !searchText.isEmpty {
            documents = documents.filter { document in
                document.name.localizedCaseInsensitiveContains(searchText) ||
                document.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return documents
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with search and filters
                    headerView
                    
                    // Document Grid/List
                    documentGridView
                }
                
                // Enhanced FAB positioned at bottom left
                floatingActionButton
            }
            .navigationTitle("My Documents")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Settings Button
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        
                    }
                }
            }
        }
        .onAppear {
            setupStorageManager()
        }
        .sheet(isPresented: $showingDocumentScanner) {
            if VNDocumentCameraViewController.isSupported {
                DocumentScannerView { scannedImages in
                    processScannedImages(scannedImages)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(selectedImages: $selectedImages) { images in
                processScannedImages(images)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result: result)
        }
        .actionSheet(isPresented: $showingQuickActions) {
            ActionSheet(
                title: Text("Quick Actions"),
                buttons: [
                    .default(Text("Refresh Documents")) {
                        Task { await refreshDocuments() }
                    },
                    .default(Text(showingFavoritesOnly ? "Show All" : "Show Favorites Only")) {
                        withAnimation(.spring()) {
                            showingFavoritesOnly.toggle()
                        }
                    },
                    .default(Text("Clear Search")) {
                        withAnimation(.easeInOut) {
                            searchText = ""
                        }
                    },
                    .cancel()
                ]
            )
        }
        .overlay {
            if isProcessing {
                ProcessingOverlay()
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    // MARK: - Enhanced Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // Search bar with improved design
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .frame(width: 16, height: 16)
                
                TextField("Search documents...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.subheadline)
                
                if !searchText.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            searchText = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .animation(.spring(response: 0.3), value: searchText.isEmpty)
            
            // Enhanced filter controls
            HStack {
                // Favorites filter
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showingFavoritesOnly.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: showingFavoritesOnly ? "heart.fill" : "heart")
                            .font(.system(size: 14, weight: .medium))
                        Text("Favorites")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(showingFavoritesOnly ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(showingFavoritesOnly ?
                                  LinearGradient(colors: [.red, .pink], startPoint: .leading, endPoint: .trailing) :
                                  LinearGradient(colors: [Color(.systemGray6)], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                    .scaleEffect(showingFavoritesOnly ? 1.05 : 1.0)
                }
                
                Spacer()
                
                // Storage info with improved design
                if let manager = storageManager {
                    HStack(spacing: 4) {
                        Image(systemName: "externaldrive")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text(manager.getFormattedFileSize(manager.getTotalStorageUsed()))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Enhanced Document Grid View
    private var documentGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160), spacing: 16)
            ], spacing: 20) {
                ForEach(filteredDocuments) { document in
                    DocumentCardView(document: document, storageManager: storageManager!)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120) // Extra padding for FAB
        }
        .refreshable {
            await refreshDocuments()
        }
        .overlay {
            if filteredDocuments.isEmpty {
                enhancedEmptyStateView
            }
        }
    }
    
    // MARK: - Enhanced Empty State View
    private var enhancedEmptyStateView: some View {
        VStack(spacing: 24) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "doc.text")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                Text("No Documents Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Start by scanning documents, importing PDFs, or converting photos to PDFs")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineLimit(3)
            }
            
            Button(action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showingImportMenu = true
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add First Document")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: filteredDocuments.isEmpty)
    }
    
    // MARK: - Enhanced Floating Action Button
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()

                VStack(spacing: 12) {
                    // Quick action buttons (shown when expanded)
                    if fabExpanded {
                        Group {
                            quickActionButton(
                                icon: "doc.viewfinder",
                                text: "Scan",
                                color: .green,
                                action: {
                                    showingDocumentScanner = true
                                    withAnimation(.spring()) { fabExpanded = false }
                                }
                            )
                            
                            quickActionButton(
                                icon: "photo.on.rectangle",
                                text: "Photos",
                                color: .orange,
                                action: {
                                    showingImagePicker = true
                                    withAnimation(.spring()) { fabExpanded = false }
                                }
                            )
                            
                            quickActionButton(
                                icon: "folder",
                                text: "Files",
                                color: .blue,
                                action: {
                                    showingFilePicker = true
                                    withAnimation(.spring()) { fabExpanded = false }
                                }
                            )
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }
                    
                    // Main FAB
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if fabExpanded {
                                fabExpanded = false
                            } else {
                                fabExpanded = true
                            }
                        }
                    }) {
                        ZStack {
                            // Background with gradient
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
                            
                            // Icon
                            Image(systemName: fabExpanded ? "xmark" : "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(fabExpanded ? 45 : 0))
                        }
                    }
                    .scaleEffect(fabExpanded ? 1.1 : 1.0)
                }
                
            }
            .padding(.trailing, 24)
            .padding(.bottom, 34)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: fabExpanded)
        .confirmationDialog("Add Document", isPresented: $showingImportMenu) {
            Button("Scan with Camera") {
                showingDocumentScanner = true
            }
            
            Button("Choose from Photos") {
                showingImagePicker = true
            }
            
            Button("Import PDF Files") {
                showingFilePicker = true
            }
            
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: showingImportMenu) { _, newValue in
            if !newValue {
                withAnimation(.spring()) {
                    fabExpanded = false
                }
            }
        }
    }
    
    // MARK: - Quick Action Button
    private func quickActionButton(icon: String, text: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            )
            .frame(width: 140)
        }
    }
    
    // MARK: - Helper Methods
    private func setupStorageManager() {
        if storageManager == nil {
            storageManager = PDFStorageManager(modelContext: modelContext)
        }
    }
    
    private func refreshDocuments() async {
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                storageManager?.fetchDocuments()
            }
        }
    }
    
    private func processScannedImages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }
        
        isProcessing = true
        
        Task {
            do {
                let documentName = "Scanned Document \(Date().formatted(date: .abbreviated, time: .shortened))"
                _ = try await MainActor.run {
                    try storageManager?.createPDFFromImages(images, name: documentName)
                }
                
                await MainActor.run {
                    isProcessing = false
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        // Document will automatically appear in the grid
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    storageManager?.errorMessage = "Failed to process images: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            isProcessing = true
            
            Task {
                for url in urls {
                    do {
                        let data = try Data(contentsOf: url)
                        let name = url.deletingPathExtension().lastPathComponent
                        
                        await MainActor.run {
                            try? storageManager?.savePDF(from: data, name: name)
                        }
                    } catch {
                        await MainActor.run {
                            storageManager?.errorMessage = "Failed to import \(url.lastPathComponent): \(error.localizedDescription)"
                        }
                    }
                }
                
                await MainActor.run {
                    isProcessing = false
                }
            }
            
        case .failure(let error):
            storageManager?.errorMessage = "Import failed: \(error.localizedDescription)"
        }
    }
}
