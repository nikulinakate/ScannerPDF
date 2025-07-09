//
//  PDFStorageManager.swift
//  Scanner PDF
//
//  Created by user on 07.07.2025.
//


import SwiftUI
import SwiftData
import Foundation
import PDFKit
import PhotosUI
import VisionKit
import UniformTypeIdentifiers


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
    
    // MARK: - Image to PDF Conversion
    func createPDFFromImages(_ images: [UIImage], name: String) throws -> ScannedDocument {
        let pdfData = createPDFFromImages(images)
        return try savePDF(from: pdfData, name: name)
    }
    
    private func createPDFFromImages(_ images: [UIImage]) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Standard letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { context in
            for image in images {
                context.beginPage()
                
                let imageRect = calculateImageRect(for: image.size, in: pageRect)
                image.draw(in: imageRect)
            }
        }
    }
    
    private func calculateImageRect(for imageSize: CGSize, in pageRect: CGRect) -> CGRect {
        let margin: CGFloat = 40
        let availableRect = pageRect.insetBy(dx: margin, dy: margin)
        
        let scale = min(availableRect.width / imageSize.width, availableRect.height / imageSize.height)
        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        
        let x = availableRect.midX - scaledSize.width / 2
        let y = availableRect.midY - scaledSize.height / 2
        
        return CGRect(origin: CGPoint(x: x, y: y), size: scaledSize)
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
            cloudKitDatabase: .none
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
