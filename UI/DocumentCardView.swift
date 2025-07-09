//
//  DocumentCardView.swift
//  Scanner PDF
//
//  Created by user on 07.07.2025.
//


import SwiftUI

// MARK: - Enhanced Document Card View
struct DocumentCardView: View {
    let document: ScannedDocument
    let storageManager: PDFStorageManager
    @State private var isPressed = false
    @State private var showingPreview = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail section
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .aspectRatio(3/4, contentMode: .fit)
                
                if let thumbnailData = document.thumbnailData,
                   let thumbnail = UIImage(data: thumbnailData) {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .cornerRadius(16)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("PDF")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Overlay elements
                VStack {
                    HStack {
                        Spacer()
                        
                        // Favorite indicator
                        if document.isFavorite {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                                .padding(8)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                    }
                    
                    Spacer()
                    
                    // Page count badge
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 10))
                            Text("\(document.pageCount)")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        
                        Spacer()
                    }
                }
                .padding(12)
            }
            
            // Document info section
            VStack(alignment: .leading, spacing: 8) {
                Text(document.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 8) {
                    Text(storageManager.getFormattedFileSize(document.fileSize))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(document.modifiedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
                showingPreview = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }
        .onLongPressGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                document.isFavorite.toggle()
                try? storageManager.updateDocument(document)
            }
        }
        .contextMenu {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    document.isFavorite.toggle()
                    try? storageManager.updateDocument(document)
                }
            }) {
                Label(document.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                      systemImage: document.isFavorite ? "heart.slash" : "heart")
            }
            
            Button(action: { showingPreview = true }) {
                Label("Preview", systemImage: "eye")
            }
            
            Button(role: .destructive, action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    try? storageManager.deleteDocument(document)
                }
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingPreview) {
            if let fileURL = document.fileURL {
                DocumentPreviewView(url: fileURL, documentName: document.name)
            }
        }
    }
}
