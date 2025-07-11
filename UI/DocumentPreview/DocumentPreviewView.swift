import SwiftUI
import QuickLook
import PDFKit
import Vision
import VisionKit

// MARK: - Main Document Preview View
struct DocumentPreviewView: View {
    let url: URL
    let documentName: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingQLPreview = false
    @State private var showingShareSheet = false
    @State private var showingPDFConverter = false
    @State private var showingOCRSheet = false
    @State private var documentThumbnail: UIImage?
    @State private var pdfDocument: PDFDocument?
    @State private var extractedText: String = ""
    @State private var isProcessingOCR = false
    @State private var ocrError: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Document preview with thumbnail
                    documentPreviewCard
                    
                    // Action buttons
                    actionButtons
                    
                    // Document info
                    documentInfo
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(documentName)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Convert button (only for PDFs)
                        if isPDFDocument {
                            Button(action: { showingPDFConverter = true }) {
                                Label("Convert PDF", systemImage: "arrow.triangle.2.circlepath")
                            }
                            
                            Divider()
                        }
                        
                        // OCR Extract Text button
                        Button(action: { performOCR() }) {
                            Label("Extract Text (OCR)", systemImage: "doc.text.viewfinder")
                        }
                        
                        Divider()
                        
                        Button(action: printDocument) {
                            Label("Print", systemImage: "printer")
                        }
                        
                        Button(action: { showingShareSheet = true }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: openInFiles) {
                            Label("Open in Files", systemImage: "folder")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingQLPreview) {
            QLPreviewWrapper(url: url, isPresented: $showingQLPreview)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [url])
        }
        .sheet(isPresented: $showingOCRSheet) {
            OCRResultSheet(
                extractedText: extractedText,
                documentName: documentName,
                isPresented: $showingOCRSheet
            )
        }
        .fullScreenCover(isPresented: $showingPDFConverter) {
            if isPDFDocument {
                EnhancedPDFConvertView(
                    document: pdfDocument,
                    onDismiss: { showingPDFConverter = false }
                )
            }
        }
        .onAppear {
            generateThumbnail()
            loadPDFDocument()
        }
    }
    
    // MARK: - Document Preview Card with Thumbnail
    private var documentPreviewCard: some View {
        VStack(spacing: 16) {
            // Document thumbnail or icon
            ZStack {
                if let thumbnail = documentThumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(width: 200, height: 260)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: getDocumentIcon())
                                    .font(.system(size: 48, weight: .thin))
                                    .foregroundColor(.gray)
                                
                                Text("Preview Loading...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
            
            // Document name
            Text(documentName)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary action - Open document with editing
            Button(action: { showingQLPreview = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                    Text("Open Document")
                        .font(.system(size: 17, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                )
            }
            
            // OCR Extract Text button
            Button(action: { performOCR() }) {
                HStack(spacing: 12) {
                    if isProcessingOCR {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 18, weight: .medium))
                    }
                    Text(isProcessingOCR ? "Extracting Text..." : "Extract Text (OCR)")
                        .font(.system(size: 17, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green)
                )
            }
            .disabled(isProcessingOCR)
            
            // Secondary actions
            HStack(spacing: 12) {
                // Convert button (only for PDFs)
                if isPDFDocument {
                    Button(action: { showingPDFConverter = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 16, weight: .medium))
                            Text("Convert")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange)
                        )
                    }
                }
                
                Button(action: { showingShareSheet = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                        Text("Share")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                Button(action: printDocument) {
                    HStack(spacing: 8) {
                        Image(systemName: "printer")
                            .font(.system(size: 16, weight: .medium))
                        Text("Print")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    // MARK: - Document Info
    private var documentInfo: some View {
        VStack(spacing: 12) {
            if let fileSize = getFileSize(),
               let dateModified = getDateModified(),
               let fileType = getFileType() {
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("File Size")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(fileSize)
                            .font(.footnote)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Modified")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(dateModified)
                            .font(.footnote)
                            .fontWeight(.medium)
                    }
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(fileType)
                            .font(.footnote)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    // Show page count for PDFs
                    if isPDFDocument, let document = pdfDocument {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Pages")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(document.pageCount)")
                                .font(.footnote)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Computed Properties
    
    private var isPDFDocument: Bool {
        url.pathExtension.lowercased() == "pdf"
    }
    
    private var isImageDocument: Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }
    
    // MARK: - OCR Functions
    
    private func performOCR() {
        isProcessingOCR = true
        ocrError = nil
        extractedText = ""
        
        Task {
            do {
                if isPDFDocument {
                    await extractTextFromPDF()
                } else if isImageDocument {
                    await extractTextFromImage()
                } else {
                    await extractTextFromGenericDocument()
                }
            }
            
            DispatchQueue.main.async {
                isProcessingOCR = false
                if !extractedText.isEmpty {
                    showingOCRSheet = true
                }
            }
        }
    }
    
    private func extractTextFromPDF() async {
        guard let pdfDocument = pdfDocument else { return }
        
        var allText = ""
        
        // First try to extract text directly from PDF
        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex) {
                if let pageText = page.string {
                    allText += pageText + "\n\n"
                }
            }
        }
        
        // If no text found or very little text, perform OCR on each page
        if allText.trimmingCharacters(in: .whitespacesAndNewlines).count < 50 {
            allText = ""
            
            for pageIndex in 0..<pdfDocument.pageCount {
                if let page = pdfDocument.page(at: pageIndex) {
                    let pageRect = page.bounds(for: .mediaBox)
                    let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                    
                    let pageImage = renderer.image { ctx in
                        ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                        ctx.cgContext.scaleBy(x: 1, y: -1)
                        ctx.cgContext.drawPDFPage(page.pageRef!)
                    }
                    
                    let pageText = await performVisionOCR(on: pageImage)
                    allText += "Page \(pageIndex + 1):\n" + pageText + "\n\n"
                }
            }
        }
        
        DispatchQueue.main.async {
            extractedText = allText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    private func extractTextFromImage() async {
        guard let image = UIImage(contentsOfFile: url.path) else {
            DispatchQueue.main.async {
                ocrError = "Failed to load image"
            }
            return
        }
        
        let text = await performVisionOCR(on: image)
        DispatchQueue.main.async {
            extractedText = text
        }
    }
    
    private func extractTextFromGenericDocument() async {
        // For other document types, try to create a preview image and perform OCR
        if let thumbnail = documentThumbnail {
            let text = await performVisionOCR(on: thumbnail)
            DispatchQueue.main.async {
                extractedText = text
            }
        } else {
            DispatchQueue.main.async {
                ocrError = "OCR not supported for this document type"
            }
        }
    }
    
    private func performVisionOCR(on image: UIImage) async -> String {
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: "")
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    print("OCR Error: \(error)")
                    continuation.resume(returning: "")
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: recognizedText)
            }
            
            // Configure for better accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("OCR Handler Error: \(error)")
                continuation.resume(returning: "")
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadPDFDocument() {
        if isPDFDocument {
            pdfDocument = PDFDocument(url: url)
        }
    }
    
    private func getFileSize() -> String? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
        } catch {
            print("Error getting file size: \(error)")
        }
        return nil
    }
    
    private func getDateModified() -> String? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let date = attributes[.modificationDate] as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                return formatter.string(from: date)
            }
        } catch {
            print("Error getting modification date: \(error)")
        }
        return nil
    }
    
    private func getFileType() -> String? {
        return url.pathExtension.uppercased()
    }
    
    private func getDocumentIcon() -> String {
        switch url.pathExtension.lowercased() {
        case "pdf":
            return "doc.richtext"
        case "doc", "docx":
            return "doc.text"
        case "xls", "xlsx":
            return "tablecells"
        case "ppt", "pptx":
            return "rectangle.on.rectangle"
        case "txt":
            return "doc.plaintext"
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic":
            return "photo"
        default:
            return "doc"
        }
    }
    
    private func generateThumbnail() {
        if isPDFDocument {
            guard let provider = CGDataProvider(url: url as CFURL),
                  let pdfDocument = CGPDFDocument(provider),
                  let page = pdfDocument.page(at: 1) else { return }
            
            let pageRect = page.getBoxRect(.mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let image = renderer.image { ctx in
                ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1, y: -1)
                ctx.cgContext.drawPDFPage(page)
            }
            
            DispatchQueue.main.async {
                self.documentThumbnail = image
            }
        } else if isImageDocument {
            DispatchQueue.main.async {
                self.documentThumbnail = UIImage(contentsOfFile: url.path)
            }
        }
    }
    
    private func printDocument() {
        let printController = UIPrintInteractionController.shared
        printController.printingItem = url
        printController.present(animated: true)
    }
    
    private func openInFiles() {
        let documentPicker = UIDocumentPickerViewController(forExporting: [url])
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(documentPicker, animated: true)
        }
    }
}

// MARK: - OCR Result Sheet
struct OCRResultSheet: View {
    let extractedText: String
    let documentName: String
    @Binding var isPresented: Bool
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Extracted Text")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("From: \(documentName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(extractedText.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Extracted text
                    if extractedText.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("No text was found in this document")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("The document may not contain readable text, or the text may be too unclear for OCR processing.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 50)
                    } else {
                        Text(extractedText)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("OCR Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { copyTextToClipboard() }) {
                            Label("Copy Text", systemImage: "doc.on.doc")
                        }
                        
                        Button(action: { showingShareSheet = true }) {
                            Label("Share Text", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: { saveTextToFile() }) {
                            Label("Save as Text File", systemImage: "doc.badge.plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .disabled(extractedText.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [extractedText])
        }
    }
    
    private func copyTextToClipboard() {
        UIPasteboard.general.string = extractedText
        // Could add a toast notification here
    }
    
    private func saveTextToFile() {
        let textFileName = "\(documentName)_extracted_text.txt"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(textFileName)
        
        do {
            try extractedText.write(to: tempURL, atomically: true, encoding: .utf8)
            
            let documentPicker = UIDocumentPickerViewController(forExporting: [tempURL])
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(documentPicker, animated: true)
            }
        } catch {
            print("Error saving text file: \(error)")
        }
    }
}

// MARK: - Enhanced QLPreviewController Wrapper with Editing Mode
struct QLPreviewWrapper: UIViewControllerRepresentable {
    let url: URL
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let previewController = QLPreviewController()
        previewController.dataSource = context.coordinator
        previewController.delegate = context.coordinator
        
        // Create navigation controller
        let navigationController = UINavigationController(rootViewController: previewController)
        
        // Add Done button to navigation bar
        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(Coordinator.dismissPreview)
        )
        
        previewController.navigationItem.rightBarButtonItem = doneButton
        
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let parent: QLPreviewWrapper
        
        init(_ parent: QLPreviewWrapper) {
            self.parent = parent
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.url as QLPreviewItem
        }
        
        func previewControllerWillDismiss(_ controller: QLPreviewController) {
            parent.isPresented = false
        }
        
        @objc func dismissPreview() {
            parent.isPresented = false
        }
        
        // Enable editing mode for supported file types
        func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
            let fileExtension = (previewItem.previewItemURL?.pathExtension ?? "").lowercased()
            
            // Enable editing for supported file types
            switch fileExtension {
            case "pdf", "txt", "rtf", "doc", "docx":
                return .updateContents
            default:
                return .disabled
            }
        }
        
        // Handle document updates after editing
        func previewController(_ controller: QLPreviewController, didUpdateContentsOf previewItem: QLPreviewItem) {
            print("Document was updated: \(previewItem.previewItemURL?.lastPathComponent ?? "Unknown")")
            // You can add custom logic here to handle the updated document
            // For example, refresh thumbnails, update UI, etc.
        }
        
        // Handle save completion
        func previewController(_ controller: QLPreviewController, didSaveEditedCopyOf previewItem: QLPreviewItem, at modifiedContentsURL: URL) {
            print("Document saved to: \(modifiedContentsURL)")
            // Handle the saved document if needed
        }
        
        // Customize the editing interface
        func previewController(_ controller: QLPreviewController, shouldOpen url: URL, for previewItem: QLPreviewItem) -> Bool {
            return true
        }
    }
}

// MARK: - Share Sheet Helper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
