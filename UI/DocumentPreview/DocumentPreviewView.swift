import SwiftUI
import QuickLook

// MARK: - Main Document Preview View
struct DocumentPreviewView: View {
    let url: URL
    let documentName: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingQLPreview = false
    @State private var showingShareSheet = false
    @State private var documentThumbnail: UIImage?
    
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
            ShareSheet(url: url)
        }
        .onAppear {
            generateThumbnail()
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
            
            // Secondary actions
            HStack(spacing: 12) {
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
    
    // MARK: - Helper Functions
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
        default:
            return "doc"
        }
    }
    
    private func generateThumbnail() {
        guard let provider = CGDataProvider(url: url as CFURL) else { return }
        
        if url.pathExtension.lowercased() == "pdf" {
            if let pdfDocument = CGPDFDocument(provider) {
                if let page = pdfDocument.page(at: 1) {
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
                }
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

// MARK: - Enhanced QLPreviewController Wrapper with Editing Mode
struct QLPreviewWrapper: UIViewControllerRepresentable {
    let url: URL
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let previewController = QLPreviewController()
        previewController.dataSource = context.coordinator
        previewController.delegate = context.coordinator
        previewController.currentPreviewItemIndex = 0
        
        // Enable editing mode
        previewController.reloadData()
        
        // Add navigation controller to handle the editing flow properly
        let navigationController = UINavigationController(rootViewController: previewController)
        navigationController.navigationBar.tintColor = UIColor.systemBlue
        
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

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller.excludedActivityTypes = [.saveToCameraRoll]
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Usage Example
/*
 Usage in your main view:
 
 DocumentPreviewView(
     url: yourDocumentURL,
     documentName: "Sample Document.pdf"
 )
 
 Key Changes for Editing Mode:
 1. Wrapped QLPreviewController in UINavigationController for proper editing flow
 2. Enhanced editingModeFor delegate method to check file types
 3. Added didUpdateContentsOf and didSaveEditedCopyOf delegate methods
 4. Improved file type checking for editing capabilities
 5. Added proper navigation handling for editing workflow
 
 Supported editing file types:
 - PDF (markup, annotations, signatures)
 - TXT (text editing)
 - RTF (rich text editing)
 - DOC/DOCX (if supported by system)
 */
