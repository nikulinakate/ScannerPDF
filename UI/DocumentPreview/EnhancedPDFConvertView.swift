//
//  EnhancedPDFConvertView.swift
//  Scanner PDF
//
//  Created by user on 07.07.2025.
//

import SwiftUI
@preconcurrency import PDFKit
import UniformTypeIdentifiers

// MARK: - Enhanced PDF Convert View
struct EnhancedPDFConvertView: View {
    let document: PDFDocument?
    let onDismiss: () -> Void
    
    @StateObject private var viewModel = PDFConvertViewModel()
    @State private var selectedFormat: ConversionFormat = .images
    @State private var selectedImageFormat: ImageFormat = .png
    @State private var selectedImageQuality: ImageQuality = .high
    @State private var selectedPageRange: PageRange = .all
    @State private var customStartPage: String = "1"
    @State private var customEndPage: String = ""
    @State private var showingFilePicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var convertedFileURL: URL?
    @State private var showingShareSheet = false
    
    // Animation states
    @State private var isAnimating = false
    @Namespace private var formatAnimation
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Header info
                    headerInfoView
                    
                    // Conversion format selection
                    formatSelectionView
                    
                    // Format-specific options
                    formatOptionsView
                    
                    // Page range selection
                    pageRangeView
                    
                    // Convert button
                    convertButtonView
                }
                .padding()
                .animation(.easeInOut(duration: 0.3), value: selectedFormat)
            }
            .navigationTitle("Convert PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilePicker = true
                    } label: {
                        Label("Import PDF", systemImage: "doc.badge.plus")
                    }
                    .disabled(viewModel.isProcessing)
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .confirmationDialog("Conversion Complete", isPresented: $showingSuccess) {
                Button("Share File") {
                    showingShareSheet = true
                }
                Button("Done") {
                    onDismiss()
                }
            } message: {
                Text("Your PDF has been successfully converted!")
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = convertedFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
        .onAppear {
            setupInitialState()
        }
        .sensoryFeedback(.success, trigger: showingSuccess)
        .sensoryFeedback(.error, trigger: showingError)
    }
    
    // MARK: - Header Info View
    private var headerInfoView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.blue.gradient)
                    .symbolEffect(.pulse, isActive: viewModel.isProcessing)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("PDF Conversion")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Group {
                        if let document = document {
                            Text("\(document.pageCount) pages")
                        } else {
                            Text("No document selected")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Document preview thumbnail
                if let document = document, let firstPage = document.page(at: 0) {
                    DocumentThumbnail(page: firstPage)
                        .frame(width: 50, height: 60)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
            }
            
            Text("Transform your PDF into various formats including images, text, and office documents with customizable options.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Format Selection View
    private var formatSelectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Conversion Format")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(ConversionFormat.allCases, id: \.self) { format in
                    formatCard(format: format)
                }
            }
        }
    }
    
    private func formatCard(format: ConversionFormat) -> some View {
        Button {
            withAnimation(.bouncy(duration: 0.3)) {
                selectedFormat = format
            }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: format.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(selectedFormat == format ? .white : .blue)
                    .symbolEffect(.bounce, value: selectedFormat == format)
                
                VStack(spacing: 4) {
                    Text(format.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(format.description)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .foregroundStyle(selectedFormat == format ? .white : .primary)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedFormat == format ? .blue : .clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedFormat == format ? .clear : .gray.opacity(0.3), lineWidth: 1)
                    }
            }
            .scaleEffect(selectedFormat == format ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .matchedGeometryEffect(id: format.rawValue, in: formatAnimation)
    }
    
    // MARK: - Format Options View
    @ViewBuilder
    private var formatOptionsView: some View {
        Group {
            switch selectedFormat {
            case .images:
                imageOptionsView
            case .text:
                textOptionsView
            case .word:
                wordOptionsView
            case .powerpoint:
                powerpointOptionsView
            case .excel:
                excelOptionsView
            case .html:
                htmlOptionsView
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    private var imageOptionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Image Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Image format selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Format")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Picker("Image Format", selection: $selectedImageFormat) {
                        ForEach(ImageFormat.allCases, id: \.self) { format in
                            Text(format.title).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Quality selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quality")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Picker("Quality", selection: $selectedImageQuality) {
                        ForEach(ImageQuality.allCases, id: \.self) { quality in
                            Text(quality.title).tag(quality)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Quality info
                InfoBox(
                    icon: "info.circle.fill",
                    title: "Quality Guide",
                    message: "Higher quality produces clearer images but larger file sizes. Choose based on your intended use."
                )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var textOptionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Text Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "textformat")
                        .font(.title2)
                        .foregroundStyle(.blue.gradient)
                    
                    Text("Extract text content from PDF")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach([
                        "Preserves text structure and formatting",
                        "Suitable for copying and editing",
                        "May not preserve complex layouts"
                    ], id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text(feature)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var wordOptionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Word Document Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundStyle(.blue.gradient)
                    
                    Text("Convert to Microsoft Word format")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach([
                        "Maintains document structure",
                        "Editable in Word processors",
                        "May require formatting adjustments"
                    ], id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text(feature)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var powerpointOptionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PowerPoint Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "play.rectangle")
                        .font(.title2)
                        .foregroundStyle(.blue.gradient)
                    
                    Text("Convert to PowerPoint presentation")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach([
                        "Each page becomes a slide",
                        "Suitable for presentations",
                        "Text and basic formatting preserved"
                    ], id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text(feature)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var excelOptionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Excel Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "tablecells")
                        .font(.title2)
                        .foregroundStyle(.blue.gradient)
                    
                    Text("Convert to Excel spreadsheet")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach([
                        "Text organized in rows and columns",
                        "Good for data extraction",
                        "May require manual formatting"
                    ], id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text(feature)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var htmlOptionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HTML Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.title2)
                        .foregroundStyle(.blue.gradient)
                    
                    Text("Convert to HTML webpage")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach([
                        "Web-compatible format",
                        "Styled with CSS",
                        "Easy to share and view"
                    ], id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text(feature)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Page Range View
    private var pageRangeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Page Range")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(PageRange.allCases, id: \.self) { range in
                    pageRangeOption(range: range)
                }
            }
            
            if selectedPageRange == .custom {
                customPageRangeView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func pageRangeOption(range: PageRange) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPageRange = range
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedPageRange == range ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selectedPageRange == range ? .blue : .secondary)
                    .symbolEffect(.bounce, value: selectedPageRange == range)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(range.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(range.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedPageRange == range ? .blue.opacity(0.1) : .clear)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var customPageRangeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Range")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("From")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Start", text: $customStartPage)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("To")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("End", text: $customEndPage)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
            }
            
            if let document = document {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text("Valid range: 1 to \(document.pageCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Convert Button View
    private var convertButtonView: some View {
        VStack(spacing: 16) {
            Button {
                performConversion()
            } label: {
                HStack(spacing: 12) {
                    if viewModel.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.headline)
                    }
                    
                    Text(viewModel.isProcessing ? "Converting..." : "Convert PDF")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(canConvert ? .blue : .gray)
                }
                .foregroundColor(.white)
            }
            .disabled(!canConvert || viewModel.isProcessing)
            .buttonStyle(.plain)
            .scaleEffect(viewModel.isProcessing ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: viewModel.isProcessing)
            
            if viewModel.isProcessing {
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(y: 1.5)
                    
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
    }
    
    private var canConvert: Bool {
        guard document != nil else { return false }
        
        if selectedPageRange == .custom {
            guard let startPage = Int(customStartPage),
                  let endPage = Int(customEndPage.isEmpty ? customStartPage : customEndPage),
                  let document = document else { return false }
            
            return startPage >= 1 && endPage <= document.pageCount && startPage <= endPage
        }
        
        return true
    }
    
    // MARK: - Methods
    
    private func setupInitialState() {
        if let document = document {
            customEndPage = "\(document.pageCount)"
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                viewModel.loadDocument(from: url)
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func performConversion() {
        guard let document = document else { return }
        
        let pages = getSelectedPages()
        
        Task {
            do {
                let result = try await viewModel.convertPDF(
                    document: document,
                    format: selectedFormat,
                    pages: pages,
                    imageFormat: selectedImageFormat,
                    imageQuality: selectedImageQuality
                )
                
                await MainActor.run {
                    convertedFileURL = result
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func getSelectedPages() -> [Int] {
        guard let document = document else { return [] }
        
        switch selectedPageRange {
        case .all:
            return Array(0..<document.pageCount)
        case .first:
            return [0]
        case .last:
            return [document.pageCount - 1]
        case .custom:
            guard let startPage = Int(customStartPage),
                  let endPage = Int(customEndPage.isEmpty ? customStartPage : customEndPage) else {
                return []
            }
            return Array((startPage - 1)..<min(endPage, document.pageCount))
        }
    }
}

// MARK: - Supporting Views

struct DocumentThumbnail: View {
    let page: PDFPage
    
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay {
                // This would be replaced with actual PDF page rendering
                Image(systemName: "doc.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
    }
}

struct InfoBox: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - View Model (same as before but with @MainActor improvements)
@MainActor
class PDFConvertViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var statusMessage = ""
    @Published var currentDocument: PDFDocument?
    
    func loadDocument(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        currentDocument = PDFDocument(url: url)
    }
    
    func convertPDF(
        document: PDFDocument,
        format: ConversionFormat,
        pages: [Int],
        imageFormat: ImageFormat,
        imageQuality: ImageQuality
    ) async throws -> URL {
        
        isProcessing = true
        progress = 0.0
        statusMessage = "Starting conversion..."
        
        defer {
            isProcessing = false
            progress = 0.0
            statusMessage = ""
        }
        
        switch format {
        case .images:
            return try await convertToImages(document: document, pages: pages, format: imageFormat, quality: imageQuality)
        case .text:
            return try await convertToText(document: document, pages: pages)
        case .word:
            return try await convertToWord(document: document, pages: pages)
        case .powerpoint:
            return try await convertToPowerPoint(document: document, pages: pages)
        case .excel:
            return try await convertToExcel(document: document, pages: pages)
        case .html:
            return try await convertToHTML(document: document, pages: pages)
        }
    }
    
    // ... (rest of the conversion methods remain the same)
    
    private func convertToImages(document: PDFDocument, pages: [Int], format: ImageFormat, quality: ImageQuality) async throws -> URL {
        statusMessage = "Converting to images..."
        
        let tempDir = FileManager.default.temporaryDirectory
        let outputDir = tempDir.appendingPathComponent("pdf_images_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        let totalPages = pages.count
        
        for (index, pageIndex) in pages.enumerated() {
            guard let page = document.page(at: pageIndex) else { continue }
            
            statusMessage = "Converting page \(index + 1) of \(totalPages)..."
            progress = Double(index) / Double(totalPages)
            
            let pageImage = await renderPageToImage(page: page, quality: quality)
            let fileName = "page_\(String(format: "%03d", pageIndex + 1)).\(format.fileExtension)"
            let fileURL = outputDir.appendingPathComponent(fileName)
            
            try saveImageToFile(image: pageImage, url: fileURL, format: format, quality: quality)
            
            // Small delay to show progress
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        // Create ZIP file if multiple images
        if pages.count > 1 {
            statusMessage = "Creating archive..."
            progress = 0.9
            let zipURL = try await createZipArchive(from: outputDir)
            progress = 1.0
            return zipURL
        } else {
            progress = 1.0
            return outputDir.appendingPathComponent("page_001.\(format.fileExtension)")
        }
    }
    
    private func convertToText(document: PDFDocument, pages: [Int]) async throws -> URL {
//        statusMessage = "Extracting text..."
//        
//        var extractedText = ""
//        let totalPages = pages.count
//        
//        for (index, pageIndex) in pages.enumerated() {
//            guard let page = document.page(at: pageIndex) else { continue }
//            
//            statusMessage = "Processing page \(index + 1) of \(totalPages)..."
//            progress = Double(index) / Double(totalPages)
//            
//            if let pageText = page.string {
//                rtfContent += "\\f0\\fs24 \\b Page \(pageIndex + 1) \\b0\\par\\par "
//                rtfContent += pageText.replacingOccurrences(of: "\n", with: "\\par ")
//                rtfContent += "\\par\\par "
//            }
//            
//            try await Task.sleep(nanoseconds: 50_000_000)
//        }
//        
//        rtfContent += "}"
//        
//        statusMessage = "Saving Word document..."
//        progress = 0.9
//        
//        let tempDir = FileManager.default.temporaryDirectory
//        let outputURL = tempDir.appendingPathComponent("converted_document_\(UUID().uuidString).rtf")
//        
//        try rtfContent.write(to: outputURL, atomically: true, encoding: .utf8)
//        
//        progress = 1.0
//        return outputURL
                let tempDir = FileManager.default.temporaryDirectory
                let outputURL = tempDir.appendingPathComponent("converted_document_\(UUID().uuidString).rtf")
                return outputURL

    }
    
    private func convertToPowerPoint(document: PDFDocument, pages: [Int]) async throws -> URL {
        statusMessage = "Converting to PowerPoint..."
        
        // Simplified implementation - would need proper PPTX library
        let tempDir = FileManager.default.temporaryDirectory
        let outputURL = tempDir.appendingPathComponent("presentation_\(UUID().uuidString).pptx")
        
        // Create a basic HTML version that can be imported
        var htmlContent = "<html><body>"
        
        for (index, pageIndex) in pages.enumerated() {
            guard let page = document.page(at: pageIndex) else { continue }
            
            statusMessage = "Processing slide \(index + 1) of \(pages.count)..."
            progress = Double(index) / Double(pages.count)
            
            htmlContent += "<div style='page-break-after: always;'>"
            htmlContent += "<h1>Slide \(pageIndex + 1)</h1>"
            
            if let pageText = page.string {
                htmlContent += "<p>\(pageText.replacingOccurrences(of: "\n", with: "<br>"))</p>"
            }
            
            htmlContent += "</div>"
            
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        
        htmlContent += "</body></html>"
        
        try htmlContent.write(to: outputURL, atomically: true, encoding: .utf8)
        progress = 1.0
        
        return outputURL
    }
    
    private func convertToExcel(document: PDFDocument, pages: [Int]) async throws -> URL {
        statusMessage = "Converting to Excel..."
        
        // Simplified CSV implementation
        var csvContent = "Page,Content\n"
        
        for (index, pageIndex) in pages.enumerated() {
            guard let page = document.page(at: pageIndex) else { continue }
            
            statusMessage = "Processing page \(index + 1) of \(pages.count)..."
            progress = Double(index) / Double(pages.count)
            
            if let pageText = page.string {
                let escapedText = pageText.replacingOccurrences(of: "\"", with: "\"\"")
                csvContent += "\(pageIndex + 1),\"\(escapedText)\"\n"
            }
            
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let outputURL = tempDir.appendingPathComponent("data_\(UUID().uuidString).csv")
        
        try csvContent.write(to: outputURL, atomically: true, encoding: .utf8)
        progress = 1.0
        
        return outputURL
    }
    
    private func convertToHTML(document: PDFDocument, pages: [Int]) async throws -> URL {
        statusMessage = "Converting to HTML..."
        
        var htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Converted PDF</title>
            <style>
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                    margin: 40px auto; 
                    max-width: 800px;
                    line-height: 1.6;
                    color: #333;
                }
                .page { 
                    margin-bottom: 40px; 
                    border-bottom: 2px solid #eee; 
                    padding-bottom: 20px; 
                }
                .page-number { 
                    color: #666; 
                    font-size: 14px; 
                    margin-bottom: 15px; 
                    font-weight: 600;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                }
                .page-content {
                    background: #fafafa;
                    padding: 20px;
                    border-radius: 8px;
                    border-left: 4px solid #007AFF;
                }
            </style>
        </head>
        <body>
            <h1>PDF Conversion Result</h1>
        """
        
        for (index, pageIndex) in pages.enumerated() {
            guard let page = document.page(at: pageIndex) else { continue }
            
            statusMessage = "Processing page \(index + 1) of \(pages.count)..."
            progress = Double(index) / Double(pages.count)
            
            htmlContent += "<div class='page'>"
            htmlContent += "<div class='page-number'>Page \(pageIndex + 1)</div>"
            
            if let pageText = page.string {
                htmlContent += "<div class='page-content'><p>\(pageText.replacingOccurrences(of: "\n", with: "<br>"))</p></div>"
            }
            
            htmlContent += "</div>"
            
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        
        htmlContent += "</body></html>"
        
        let tempDir = FileManager.default.temporaryDirectory
        let outputURL = tempDir.appendingPathComponent("document_\(UUID().uuidString).html")
        
        try htmlContent.write(to: outputURL, atomically: true, encoding: .utf8)
        progress = 1.0
        
        return outputURL
    }
    
    private func convertToWord(document: PDFDocument, pages: [Int]) async throws -> URL {
        statusMessage = "Converting to Word document..."
        
        // This is a simplified implementation
        // In a real app, you'd use a proper RTF/DOC conversion library
        
        var rtfContent = "{\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Times New Roman;}} "
        let totalPages = pages.count
        
        for (index, pageIndex) in pages.enumerated() {
            guard let page = document.page(at: pageIndex) else { continue }
            
            statusMessage = "Processing page \(index + 1) of \(totalPages)..."
            progress = Double(index) / Double(totalPages)
            
            if let pageText = page.string {
                // Clean up the text and escape RTF special characters
                let cleanText = pageText
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "{", with: "\\{")
                    .replacingOccurrences(of: "}", with: "\\}")
                    .replacingOccurrences(of: "\n", with: "\\par ")
                    .replacingOccurrences(of: "\r", with: "\\par ")
                
                // Add page content to RTF
                rtfContent += "\\f0\\fs24 " + cleanText
                
                // Add page break if not the last page
                if index < totalPages - 1 {
                    rtfContent += "\\page "
                }
            }
            
            // Allow UI updates
            await MainActor.run {
                // Update UI if needed
            }
        }
        
        // Close RTF document
        rtfContent += "}"
        
        // Create temporary file
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "converted_document_\(UUID().uuidString).rtf"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        // Write RTF content to file
        try rtfContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        statusMessage = "Conversion complete!"
        progress = 1.0
        
        return fileURL
    }
                 
    
    // MARK: - Helper Methods
    
    private func renderPageToImage(page: PDFPage, quality: ImageQuality) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let pageRect = page.bounds(for: .mediaBox)
                let scale = quality.scale
                let scaledSize = CGSize(
                    width: pageRect.width * scale,
                    height: pageRect.height * scale
                )
                
                let renderer = UIGraphicsImageRenderer(size: scaledSize)
                let image = renderer.image { context in
                    context.cgContext.setFillColor(UIColor.white.cgColor)
                    context.cgContext.fill(CGRect(origin: .zero, size: scaledSize))
                    
                    context.cgContext.scaleBy(x: scale, y: scale)
                    context.cgContext.translateBy(x: 0, y: pageRect.height)
                    context.cgContext.scaleBy(x: 1, y: -1)
                    
                    page.draw(with: .mediaBox, to: context.cgContext)
                }
                
                continuation.resume(returning: image)
            }
        }
    }
    
    private func saveImageToFile(image: UIImage, url: URL, format: ImageFormat, quality: ImageQuality) throws {
        let data: Data?
        
        switch format {
        case .png:
            data = image.pngData()
        case .jpeg:
            data = image.jpegData(compressionQuality: quality.compressionQuality)
        }
        
        guard let imageData = data else {
            throw ConversionError.imageProcessingFailed
        }
        
        try imageData.write(to: url)
    }
    
    private func createZipArchive(from directory: URL) async throws -> URL {
        // This is a simplified implementation
        // In a real app, you'd use a proper ZIP library like ZIPFoundation
        
        let tempDir = FileManager.default.temporaryDirectory
        let zipURL = tempDir.appendingPathComponent("converted_images_\(UUID().uuidString).zip")
        
        // For now, just return the directory
        // In production, implement proper ZIP creation
        return directory
    }
}

// MARK: - Supporting Types

enum ConversionFormat: String, CaseIterable {
    case images = "Images"
    case text = "Text"
    case word = "Word"
    case powerpoint = "PowerPoint"
    case excel = "Excel"
    case html = "HTML"
    
    var title: String { rawValue }
    
    var description: String {
        switch self {
        case .images: return "PNG or JPEG images"
        case .text: return "Plain text file"
        case .word: return "Word document"
        case .powerpoint: return "PowerPoint slides"
        case .excel: return "Excel spreadsheet"
        case .html: return "HTML webpage"
        }
    }
    
    var icon: String {
        switch self {
        case .images: return "photo.on.rectangle"
        case .text: return "doc.text"
        case .word: return "doc.richtext"
        case .powerpoint: return "play.rectangle"
        case .excel: return "tablecells"
        case .html: return "globe"
        }
    }
}

enum ImageFormat: String, CaseIterable {
    case png = "PNG"
    case jpeg = "JPEG"
    
    var title: String { rawValue }
    
    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        }
    }
}

enum ImageQuality: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var title: String { rawValue }
    
    var scale: CGFloat {
        switch self {
        case .low: return 1.0
        case .medium: return 2.0
        case .high: return 3.0
        }
    }
    
    var compressionQuality: CGFloat {
        switch self {
        case .low: return 0.5
        case .medium: return 0.7
        case .high: return 0.9
        }
    }
}

enum PageRange: String, CaseIterable {
    case all = "All"
    case first = "First"
    case last = "Last"
    case custom = "Custom"
    
    var title: String { rawValue }
    
    var description: String {
        switch self {
        case .all: return "Convert all pages"
        case .first: return "Convert first page only"
        case .last: return "Convert last page only"
        case .custom: return "Choose specific page range"
        }
    }
}

enum ConversionError: Error, LocalizedError {
    case documentNotFound
    case pageNotFound
    case imageProcessingFailed
    case textExtractionFailed
    case fileWriteFailed
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .documentNotFound:
            return "PDF document not found"
        case .pageNotFound:
            return "Specified page not found"
        case .imageProcessingFailed:
            return "Failed to process image"
        case .textExtractionFailed:
            return "Failed to extract text"
        case .fileWriteFailed:
            return "Failed to write output file"
        case .unsupportedFormat:
            return "Conversion format not supported"
        }
    }
}
