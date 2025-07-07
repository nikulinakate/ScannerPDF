import SwiftUI
import SwiftData
import Foundation
import PDFKit

// MARK: - Scanned Document Model
@Model
final class ScannedDocument {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdDate: Date
    var modifiedDate: Date
    var fileSize: Int64
    var pageCount: Int
    var tags: [String]
    var isFavorite: Bool
    
    // Store the PDF file path relative to documents directory
    var filePath: String
    
    // Thumbnail image data (optional)
    @Attribute(.externalStorage) var thumbnailData: Data?
    
    init(name: String, filePath: String, pageCount: Int = 0, fileSize: Int64 = 0) {
        self.id = UUID()
        self.name = name
        self.filePath = filePath
        self.pageCount = pageCount
        self.fileSize = fileSize
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.tags = []
        self.isFavorite = false
        self.thumbnailData = nil
    }
    
    // Computed property to get full file URL
    var fileURL: URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent(filePath)
    }
    
    // Generate thumbnail from PDF
    func generateThumbnail() -> UIImage? {
        guard let fileURL = fileURL,
              let pdfDocument = PDFDocument(url: fileURL),
              let firstPage = pdfDocument.page(at: 0) else {
            return nil
        }
        
        let pageRect = firstPage.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        
        let thumbnail = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)
            
            ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            firstPage.draw(with: .mediaBox, to: ctx.cgContext)
        }
        
        return thumbnail
    }
    
    // Update thumbnail data
    func updateThumbnail() {
        if let thumbnail = generateThumbnail() {
            self.thumbnailData = thumbnail.jpegData(compressionQuality: 0.8)
        }
    }
}

// MARK: - Storage Manager
@Observable
final class PDFStorageManager {
    private var modelContext: ModelContext
    private let fileManager = FileManager.default
    
    // Published properties for UI binding
    var documents: [ScannedDocument] = []
    var isLoading = false
    var errorMessage: String?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        createDirectoryIfNeeded()
        fetchDocuments()
    }
    
    // MARK: - Directory Management
    private func createDirectoryIfNeeded() {
        let documentsPath = getDocumentsDirectory()
        let pdfDirectory = documentsPath.appendingPathComponent("PDFs")
        
        if !fileManager.fileExists(atPath: pdfDirectory.path) {
            try? fileManager.createDirectory(at: pdfDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private func getPDFDirectory() -> URL {
        return getDocumentsDirectory().appendingPathComponent("PDFs")
    }
    
    // MARK: - CRUD Operations
    
    func fetchDocuments() {
        isLoading = true
        errorMessage = nil
        
        do {
            let descriptor = FetchDescriptor<ScannedDocument>(
                sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)]
            )
            documents = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to fetch documents: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func savePDF(from data: Data, name: String) throws -> ScannedDocument {
        let fileName = "\(UUID().uuidString).pdf"
        let filePath = "PDFs/\(fileName)"
        let fileURL = getDocumentsDirectory().appendingPathComponent(filePath)
        
        // Write PDF data to file
        try data.write(to: fileURL)
        
        // Get file size
        let fileSize = try fileManager.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0
        
        // Get page count
        let pageCount = getPDFPageCount(from: fileURL)
        
        // Create document model
        let document = ScannedDocument(
            name: name,
            filePath: filePath,
            pageCount: pageCount,
            fileSize: fileSize
        )
        
        // Generate thumbnail
        document.updateThumbnail()
        
        // Save to SwiftData
        modelContext.insert(document)
        try modelContext.save()
        
        // Update local array
        documents.insert(document, at: 0)
        
        return document
    }
    
    func updateDocument(_ document: ScannedDocument) throws {
        document.modifiedDate = Date()
        try modelContext.save()
        fetchDocuments()
    }
    
    func deleteDocument(_ document: ScannedDocument) throws {
        // Delete physical file
        if let fileURL = document.fileURL {
            try? fileManager.removeItem(at: fileURL)
        }
        
        // Delete from SwiftData
        modelContext.delete(document)
        try modelContext.save()
        
        // Update local array
        documents.removeAll { $0.id == document.id }
    }
    
    func deleteDocuments(_ documentsToDelete: [ScannedDocument]) throws {
        for document in documentsToDelete {
            try deleteDocument(document)
        }
    }
    
    // MARK: - Search and Filter
    func searchDocuments(query: String) -> [ScannedDocument] {
        if query.isEmpty {
            return documents
        }
        
        return documents.filter { document in
            document.name.localizedCaseInsensitiveContains(query) ||
            document.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    func filterDocuments(by tag: String) -> [ScannedDocument] {
        return documents.filter { $0.tags.contains(tag) }
    }
    
    func getFavoriteDocuments() -> [ScannedDocument] {
        return documents.filter { $0.isFavorite }
    }
    
    // MARK: - Utility Methods
    private func getPDFPageCount(from url: URL) -> Int {
        guard let pdfDocument = PDFDocument(url: url) else { return 0 }
        return pdfDocument.pageCount
    }
    
    func getTotalStorageUsed() -> Int64 {
        return documents.reduce(0) { $0 + $1.fileSize }
    }
    
    func getFormattedFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - SwiftData Configuration
extension PDFStorageManager {
    static func createModelContainer() -> ModelContainer {
        let schema = Schema([
            ScannedDocument.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none // Change to .automatic for CloudKit sync
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}


// MARK: - Example View Implementation
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var storageManager: PDFStorageManager?
    @State private var searchText = ""
    @State private var selectedTag = ""
    @State private var showingFavoritesOnly = false
    
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
        NavigationView {
            VStack {
                // Search and Filter Controls
                HStack {
                    TextField("Search documents...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: { showingFavoritesOnly.toggle() }) {
                        Image(systemName: showingFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundColor(showingFavoritesOnly ? .red : .gray)
                    }
                }
                .padding()
                
                // Document List
                List {
                    ForEach(filteredDocuments) { document in
                        DocumentRowView(document: document, storageManager: storageManager!)
                    }
                    .onDelete(perform: deleteDocuments)
                }
                .refreshable {
                    storageManager?.fetchDocuments()
                }
            }
            .navigationTitle("PDF Documents")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add PDF") {
                        // Handle adding new PDF
                        addSamplePDF()
                    }
                }
            }
        }
        .onAppear {
            if storageManager == nil {
                storageManager = PDFStorageManager(modelContext: modelContext)
            }
        }
    }
    
    private func deleteDocuments(offsets: IndexSet) {
        guard let manager = storageManager else { return }
        
        let documentsToDelete = offsets.map { filteredDocuments[$0] }
        
        do {
            try manager.deleteDocuments(documentsToDelete)
        } catch {
            print("Error deleting documents: \(error)")
        }
    }
    
    private func addSamplePDF() {
        // This would typically be called after scanning/creating a PDF
        // For demo purposes, we'll create a sample PDF
        let sampleData = createSamplePDFData()
        
        do {
            try storageManager?.savePDF(from: sampleData, name: "Sample Document \(Date().timeIntervalSince1970)")
        } catch {
            print("Error saving PDF: \(error)")
        }
    }
    
    private func createSamplePDFData() -> Data {
        // Create a simple PDF for demonstration
        let pdfMetaData = [
            kCGPDFContextCreator: "PDF Scanner App",
            kCGPDFContextAuthor: "Scanner App",
            kCGPDFContextTitle: "Sample PDF"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let text = "Sample PDF Document\nCreated by Scanner App"
            let textFont = UIFont.systemFont(ofSize: 24)
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: UIColor.black
            ]
            
            text.draw(in: CGRect(x: 50, y: 50, width: pageWidth - 100, height: pageHeight - 100), withAttributes: textAttributes)
        }
        
        return data
    }
}

// MARK: - Document Row View
struct DocumentRowView: View {
    let document: ScannedDocument
    let storageManager: PDFStorageManager
    
    var body: some View {
        HStack {
            // Thumbnail
            if let thumbnailData = document.thumbnailData,
               let thumbnail = UIImage(data: thumbnailData) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 70)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 70)
                    .overlay(
                        Image(systemName: "doc.fill")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(document.pageCount) pages • \(storageManager.getFormattedFileSize(document.fileSize))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Modified: \(document.modifiedDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if !document.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(document.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            Button(action: { toggleFavorite() }) {
                Image(systemName: document.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(document.isFavorite ? .red : .gray)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
    }
    
    private func toggleFavorite() {
        document.isFavorite.toggle()
        try? storageManager.updateDocument(document)
    }
}
