//
//  Enhanced DocumentPreviewView.swift
//  Scanner PDF
//
//  Enhanced with modern UI/UX best practices
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

// MARK: - Enhanced Document Preview View
struct DocumentPreviewView: View {
    let url: URL
    let documentName: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = DocumentPreviewViewModel()
    @State private var showingActionSheet = false
    @State private var selectedTool: EditingTool = .none
    @State private var currentPage: Int = 0
    @State private var totalPages: Int = 0
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Document info header
                    if !isLoading {
                        documentInfoHeader
                    }
                    
                    // PDF View Container
                    ZStack {
                        if isLoading {
                            loadingView
                        } else {
                            PDFPreviewView(
                                url: url,
                                document: $viewModel.pdfDocument,
                                selectedTool: $selectedTool,
                                currentPage: $currentPage,
                                totalPages: $totalPages,
                                onError: { error in
                                    errorMessage = error
                                    showingError = true
                                }
                            )
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .padding(.horizontal)
                    
                    // Bottom toolbar
                    bottomToolbar
                }
            }
            .navigationTitle(documentName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingActionSheet = true }) {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.primary)
                    }
                }
            }
            .confirmationDialog("Document Actions", isPresented: $showingActionSheet) {
                actionSheetButtons
            }
            .onAppear {
                loadDocument()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
        .sheet(item: $viewModel.activeSheet) { sheet in
            sheetContent(for: sheet)
        }
    }
    
    private var documentInfoHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Document Info")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Text("\(totalPages) pages")
                    Text("•")
                    Text(formatFileSize(url: url))
                }
                .font(.subheadline)
                .foregroundColor(.primary)
            }
            
            Spacer()
            
            if totalPages > 1 {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Current Page")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(currentPage + 1) of \(totalPages)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading document...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            // Editing tools
            if selectedTool != .none {
                editingToolsView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Main toolbar
            HStack {
                if selectedTool == .none {
                    // Navigation and tools
                    HStack(spacing: 24) {
                        toolbarButton("square.and.arrow.up", "Share") {
                            viewModel.shareDocument(url: url)
                        }
                        
                        toolbarButton("pencil", "Edit") {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTool = .annotate
                            }
                        }
                        
                        toolbarButton("magnifyingglass", "Search") {
                            viewModel.showSearchView()
                        }
                        
                        toolbarButton("gear", "Settings") {
                            showingActionSheet = true
                        }
                    }
                } else {
                    // Exit editing mode
                    Button("Done Editing") {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTool = .none
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Spacer()
                
                // Page navigation (if multiple pages)
                if totalPages > 1 {
                    pageNavigationView
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray),
                alignment: .top
            )
        }
    }
    
    private var editingToolsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(EditingTool.allCases, id: \.self) { tool in
                    if tool != .none {
                        editingToolButton(tool: tool)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
    }
    
    private func editingToolButton(tool: EditingTool) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTool = tool
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: tool.icon)
                    .font(.system(size: 20))
                    .foregroundColor(selectedTool == tool ? .white : .primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(selectedTool == tool ? Color.blue : Color.clear)
                    )
                
                Text(tool.title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var pageNavigationView: some View {
        HStack(spacing: 12) {
            Button(action: { navigateToPage(currentPage - 1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
            }
            .disabled(currentPage == 0)
            
            Text("\(currentPage + 1)")
                .font(.system(size: 16, weight: .medium))
                .frame(minWidth: 30)
            
            Button(action: { navigateToPage(currentPage + 1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
            }
            .disabled(currentPage >= totalPages - 1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }
    
    private func toolbarButton(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.caption)
            }
        }
        .foregroundColor(.primary)
    }
    
    private var actionSheetButtons: some View {
        Group {
            Button("Merge Documents") {
                viewModel.activeSheet = .merge
            }
            
            Button("Convert Document") {
                viewModel.activeSheet = .convert
            }
            
            Button("Add Signature") {
                viewModel.activeSheet = .signature
            }
            
            Button("Security Settings") {
                viewModel.activeSheet = .security
            }
            
            Button("Compress PDF") {
                viewModel.activeSheet = .compression
            }
            
            Button("Page Manager") {
                viewModel.activeSheet = .pageManager
            }
            
            Button("Cancel", role: .cancel) { }
        }
    }
    
    @ViewBuilder
    private func sheetContent(for sheet: SheetType) -> some View {
        switch sheet {
        case .merge:
            EnhancedPDFMergeView(currentDocument: viewModel.pdfDocument) {
                viewModel.activeSheet = nil
            }
        case .convert:
            EnhancedPDFConvertView(document: viewModel.pdfDocument) {
                viewModel.activeSheet = nil
            }
        case .signature:
            EnhancedPDFSignatureView(document: $viewModel.pdfDocument) {
                viewModel.activeSheet = nil
            }
        case .security:
            EnhancedPDFSecurityView(document: $viewModel.pdfDocument) {
                viewModel.activeSheet = nil
            }
        case .compression:
            EnhancedPDFCompressionView(document: viewModel.pdfDocument) {
                viewModel.activeSheet = nil
            }
        case .pageManager:
            EnhancedPDFPageManagerView(document: $viewModel.pdfDocument) {
                viewModel.activeSheet = nil
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadDocument() {
        Task {
            do {
                try await viewModel.loadDocument(from: url)
                await MainActor.run {
                    isLoading = false
                    if let document = viewModel.pdfDocument {
                        totalPages = document.pageCount
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func navigateToPage(_ page: Int) {
        guard page >= 0 && page < totalPages else { return }
        currentPage = page
    }
    
    private func formatFileSize(url: URL) -> String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return "Unknown size"
        }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - View Model
@MainActor
class DocumentPreviewViewModel: ObservableObject {
    @Published var pdfDocument: PDFDocument?
    @Published var activeSheet: SheetType?
    @Published var isProcessing = false
    
    func loadDocument(from url: URL) async throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw DocumentError.accessDenied
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        guard let document = PDFDocument(url: url) else {
            throw DocumentError.invalidDocument
        }
        
        self.pdfDocument = document
    }
    
    func shareDocument(url: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = window.rootViewController?.view
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
        }
        
        window.rootViewController?.present(activityVC, animated: true)
    }
    
    func showSearchView() {
        // Implementation for search functionality
    }
}

// **MARK: - Enhanced PDF Preview View**
struct PDFPreviewView: UIViewRepresentable {
    let url: URL
    @Binding var document: PDFDocument?
    @Binding var selectedTool: EditingTool
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    let onError: (String) -> Void
    
    @MainActor
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemBackground
        
        // Add delegate for page change notifications
        pdfView.delegate = context.coordinator
        
        // Load document
        if let pdfDocument = PDFDocument(url: url) {
            pdfView.document = pdfDocument
            // Update bindings asynchronously to avoid publishing during view updates
            DispatchQueue.main.async {
                document = pdfDocument
                totalPages = pdfDocument.pageCount
            }
        } else {
            onError("Failed to load PDF document")
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Update editing mode based on selected tool
        uiView.isUserInteractionEnabled = true
        
        // Configure interaction based on selected tool
        switch selectedTool {
        case .none:
            // Normal viewing mode
            break
        case .annotate, .highlight, .draw, .text, .erase:
            // Enable annotation tools
            break
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PDFViewDelegate {
        let parent: PDFPreviewView
        
        init(_ parent: PDFPreviewView) {
            self.parent = parent
        }
        
        func pdfViewCurrentPageDidChange(_ pdfView: PDFView) {
            if let currentPage = pdfView.currentPage,
               let document = pdfView.document {
                let pageIndex = document.index(for: currentPage)
                
                // Use DispatchQueue.main.async to avoid publishing during view updates
                DispatchQueue.main.async {
                    self.parent.currentPage = pageIndex
                }
            }
        }
    }
}
// MARK: - Enhanced PDF Merge View
struct EnhancedPDFMergeView: View {
    let currentDocument: PDFDocument?
    let onDismiss: () -> Void
    
    @State private var selectedFiles: [URL] = []
    @State private var isShowingFilePicker = false
    @State private var isProcessing = false
    @State private var dragOrder: [URL] = []
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                if selectedFiles.isEmpty {
                    emptyStateView
                } else {
                    fileListView
                }
                
                // Bottom buttons
                bottomButtonsView
            }
            .navigationTitle("Merge Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onDismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Files") {
                        isShowingFilePicker = true
                    }
                    .disabled(isProcessing)
                }
            }
        }
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            handleFileSelection(result)
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK") { onDismiss() }
        } message: {
            Text("Documents merged successfully!")
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Merge multiple PDF documents into one")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let document = currentDocument {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.blue)
                    Text("Current Document")
                        .font(.headline)
                    Spacer()
                    Text("\(document.pageCount) pages")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Add PDF files to merge")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Tap 'Add Files' to select PDF documents")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var fileListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(selectedFiles, id: \.self) { file in
                    fileRowView(file: file)
                }
            }
            .padding()
        }
    }
    
    private func fileRowView(file: URL) -> some View {
        HStack {
            Image(systemName: "doc.fill")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                
                if let pageCount = getPageCount(for: file) {
                    Text("\(pageCount) pages")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                selectedFiles.removeAll { $0 == file }
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var bottomButtonsView: some View {
        VStack(spacing: 12) {
            if !selectedFiles.isEmpty {
                Button(action: mergePDFs) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "doc.on.doc")
                        }
                        Text(isProcessing ? "Merging..." : "Merge Documents")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isProcessing)
            }
        }
        .padding()
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let files):
            selectedFiles.append(contentsOf: files)
        case .failure(let error):
            print("Error selecting files: \(error)")
        }
    }
    
    private func getPageCount(for url: URL) -> Int? {
        guard let document = PDFDocument(url: url) else { return nil }
        return document.pageCount
    }
    
    private func mergePDFs() {
        guard let currentDoc = currentDocument else { return }
        
        isProcessing = true
        
        Task {
            do {
                let mergedDoc = PDFDocument()
                
                // Add pages from current document
                for pageIndex in 0..<currentDoc.pageCount {
                    if let page = currentDoc.page(at: pageIndex) {
                        mergedDoc.insert(page, at: mergedDoc.pageCount)
                    }
                }
                
                // Add pages from selected files
                for fileURL in selectedFiles {
                    if let document = PDFDocument(url: fileURL) {
                        for pageIndex in 0..<document.pageCount {
                            if let page = document.page(at: pageIndex) {
                                mergedDoc.insert(page, at: mergedDoc.pageCount)
                            }
                        }
                    }
                }
                
                // Save merged document
                try await saveMergedDocument(mergedDoc)
                
                await MainActor.run {
                    isProcessing = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    // Handle error
                }
            }
        }
    }
    
    private func saveMergedDocument(_ document: PDFDocument) async throws {
        // Implementation for saving merged document
        // This would typically involve showing a save dialog or saving to Documents
        try await Task.sleep(nanoseconds: 2_000_000_000) // Simulate processing time
    }
}

// MARK: - Supporting Types and Enums

enum EditingTool: String, CaseIterable {
    case none = "None"
    case annotate = "Annotate"
    case highlight = "Highlight"
    case draw = "Draw"
    case text = "Text"
    case erase = "Erase"
    
    var title: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .none: return ""
        case .annotate: return "note.text"
        case .highlight: return "highlighter"
        case .draw: return "pencil.tip"
        case .text: return "textformat"
        case .erase: return "eraser"
        }
    }
}

enum SheetType: Identifiable {
    case merge, convert, signature, security, compression, pageManager
    
    var id: String {
        switch self {
        case .merge: return "merge"
        case .convert: return "convert"
        case .signature: return "signature"
        case .security: return "security"
        case .compression: return "compression"
        case .pageManager: return "pageManager"
        }
    }
}

enum DocumentError: Error {
    case accessDenied
    case invalidDocument
    case processingFailed
    
    var localizedDescription: String {
        switch self {
        case .accessDenied:
            return "Access to document denied"
        case .invalidDocument:
            return "Invalid or corrupted PDF document"
        case .processingFailed:
            return "Failed to process document"
        }
    }
}

struct EnhancedPDFSecurityView: View {
    @Binding var document: PDFDocument?
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            Text("Security View - To be implemented")
                .navigationTitle("Security")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { onDismiss() }
                    }
                }
        }
    }
}

struct EnhancedPDFCompressionView: View {
    let document: PDFDocument?
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            Text("Compression View - To be implemented")
                .navigationTitle("Compress PDF")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { onDismiss() }
                    }
                }
        }
    }
}

struct EnhancedPDFPageManagerView: View {
    @Binding var document: PDFDocument?
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            Text("Page Manager View - To be implemented")
                .navigationTitle("Manage Pages")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { onDismiss() }
                    }
                }
        }
    }
}
