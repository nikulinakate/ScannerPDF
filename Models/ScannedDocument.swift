//
//  ScannedDocument.swift
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
        let targetSize = CGSize(width: 150, height: 200)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        let thumbnail = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: targetSize))
            
            ctx.cgContext.translateBy(x: 0, y: targetSize.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            let scale = min(targetSize.width / pageRect.width, targetSize.height / pageRect.height)
            ctx.cgContext.scaleBy(x: scale, y: scale)
            
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
