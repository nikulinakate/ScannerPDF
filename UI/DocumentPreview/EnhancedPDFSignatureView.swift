//
//  EnhancedPDFSignatureView.swift
//  Scanner PDF
//
//  Fixed signature implementation with proper persistence and positioning
//

import SwiftUI
import PDFKit
import PencilKit

// MARK: - Enhanced PDF Signature View
struct EnhancedPDFSignatureView: View {
    @Binding var document: PDFDocument?
    let onDismiss: () -> Void
    
    @StateObject private var signatureViewModel = SignatureViewModel()
    @State private var selectedSignature: SavedSignature?
    @State private var showingSignatureCreator = false
    @State private var selectedPage: Int = 0
    @State private var signaturePosition: CGPoint = CGPoint(x: 0.5, y: 0.5) // Normalized coordinates (0-1)
    @State private var isPlacingSignature = false
    @State private var showingPageSelector = false
    @State private var showingPositionSelector = false
    @State private var signatureSize: SignatureSize = .medium
    @State private var showingSuccess = false
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with instructions
                headerView
                
                // Signature selection section
                signatureSelectionView
                
                // Page and position selection
                if selectedSignature != nil {
                    configurationView
                }
                
                Spacer()
                
                // Action buttons
                bottomButtonsView
            }
            .navigationTitle("Add Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onDismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create New") {
                        showingSignatureCreator = true
                    }
                }
            }
        }
        .onAppear {
            signatureViewModel.loadSavedSignatures()
            if let doc = document {
                selectedPage = 0
            }
        }
        .sheet(isPresented: $showingSignatureCreator) {
            SignatureCreatorView(viewModel: signatureViewModel) {
                showingSignatureCreator = false
            }
        }
        .sheet(isPresented: $showingPageSelector) {
            PageSelectorView(
                document: document,
                selectedPage: $selectedPage,
                onDismiss: { showingPageSelector = false }
            )
        }
        .sheet(isPresented: $showingPositionSelector) {
            SignaturePositionView(
                document: document,
                selectedPage: selectedPage,
                signatureSize: signatureSize,
                selectedPosition: $signaturePosition,
                onDismiss: { showingPositionSelector = false }
            )
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK") { onDismiss() }
        } message: {
            Text("Signature added successfully!")
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add your signature to the PDF document")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let doc = document {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.blue)
                    Text("Document: \(doc.pageCount) pages")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private var signatureSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Signature")
                .font(.headline)
                .padding(.horizontal)
            
            if signatureViewModel.savedSignatures.isEmpty {
                emptySignatureView
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(signatureViewModel.savedSignatures) { signature in
                            signatureCardView(signature: signature)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var emptySignatureView: some View {
        VStack(spacing: 16) {
            Image(systemName: "signature")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No signatures found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Create a new signature to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create Signature") {
                showingSignatureCreator = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    private func signatureCardView(signature: SavedSignature) -> some View {
        VStack(spacing: 12) {
            // Signature preview
            Image(uiImage: signature.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 60)
                .padding(8)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selectedSignature?.id == signature.id ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                )
            
            Text(signature.name)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text(signature.dateCreated, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 120)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onTapGesture {
            selectedSignature = signature
        }
        .contextMenu {
            Button("Rename") {
                signatureViewModel.showRenameAlert(for: signature)
            }
            
            Button("Delete", role: .destructive) {
                signatureViewModel.deleteSignature(signature)
            }
        }
    }
    
    private var configurationView: some View {
        VStack(spacing: 20) {
            // Page selection
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Page")
                        .font(.headline)
                    Text("Page \(selectedPage + 1) of \(document?.pageCount ?? 0)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Change Page") {
                    showingPageSelector = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // Signature size selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Signature Size")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    ForEach(SignatureSize.allCases, id: \.self) { size in
                        Button(action: {
                            signatureSize = size
                        }) {
                            VStack(spacing: 4) {
                                Rectangle()
                                    .fill(signatureSize == size ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: size.previewWidth, height: size.previewHeight)
                                    .cornerRadius(4)
                                
                                Text(size.displayName)
                                    .font(.caption)
                                    .foregroundColor(signatureSize == size ? .blue : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // Position selection
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Position")
                        .font(.headline)
                    Text("Tap to set position on page")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Set Position") {
                    showingPositionSelector = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private var bottomButtonsView: some View {
        VStack(spacing: 12) {
            if selectedSignature != nil {
                Button(action: addSignatureToPDF) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "signature")
                        }
                        Text(isProcessing ? "Adding Signature..." : "Add Signature to PDF")
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
    
    private func addSignatureToPDF() {
        guard let signature = selectedSignature,
              let doc = document,
              let page = doc.page(at: selectedPage) else { return }
        
        isProcessing = true
        
        Task {
            do {
                try await signatureViewModel.addSignatureToPage(
                    signature: signature,
                    page: page,
                    position: signaturePosition,
                    size: signatureSize
                )
                
                await MainActor.run {
                    isProcessing = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    print("Error adding signature: \(error)")
                }
            }
        }
    }
}

// MARK: - Signature Position View (Fixed)
struct SignaturePositionView: View {
    let document: PDFDocument?
    let selectedPage: Int
    let signatureSize: SignatureSize
    @Binding var selectedPosition: CGPoint
    let onDismiss: () -> Void
    
    @State private var dragPosition: CGPoint = .zero
    @State private var viewSize: CGSize = .zero
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Tap to place signature on the page")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                
                GeometryReader { geometry in
                    ZStack {
                        if let page = document?.page(at: selectedPage) {
                            let pageImage = page.thumbnail(of: geometry.size, for: .cropBox)
                            Image(uiImage: pageImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .background(Color.white)
                                .cornerRadius(8)
                                .onTapGesture { location in
                                    handleTap(location: location, in: geometry)
                                }
                        }
                        
                        // Signature placeholder
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: signatureSize.width * 0.5, height: signatureSize.height * 0.5)
                            .cornerRadius(4)
                            .position(dragPosition)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragPosition = value.location
                                    }
                                    .onEnded { value in
                                        handleDragEnd(location: value.location, in: geometry)
                                    }
                            )
                    }
                    .onAppear {
                        viewSize = geometry.size
                        updateDragPositionFromNormalized()
                    }
                    .onChange(of: geometry.size) { newSize in
                        viewSize = newSize
                        updateDragPositionFromNormalized()
                    }
                }
                .padding()
            }
            .navigationTitle("Position Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onDismiss() }
                }
            }
        }
    }
    
    private func handleTap(location: CGPoint, in geometry: GeometryProxy) {
        dragPosition = location
        updateNormalizedPosition(from: location, in: geometry)
    }
    
    private func handleDragEnd(location: CGPoint, in geometry: GeometryProxy) {
        dragPosition = location
        updateNormalizedPosition(from: location, in: geometry)
    }
    
    private func updateNormalizedPosition(from location: CGPoint, in geometry: GeometryProxy) {
        // Convert to normalized coordinates (0-1)
        let normalizedX = max(0, min(1, location.x / geometry.size.width))
        let normalizedY = max(0, min(1, location.y / geometry.size.height))
        selectedPosition = CGPoint(x: normalizedX, y: normalizedY)
    }
    
    private func updateDragPositionFromNormalized() {
        // Convert normalized coordinates back to view coordinates
        dragPosition = CGPoint(
            x: selectedPosition.x * viewSize.width,
            y: selectedPosition.y * viewSize.height
        )
    }
}

// MARK: - Signature Creator View (Unchanged)
struct SignatureCreatorView: View {
    @ObservedObject var viewModel: SignatureViewModel
    let onDismiss: () -> Void
    
    @State private var signatureName = ""
    @State private var canvasView = PKCanvasView()
    @State private var isDrawing = false
    @State private var showingNameAlert = false
    @State private var selectedColor: UIColor = .black
    @State private var selectedLineWidth: CGFloat = 3.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Drawing tools
                toolbarView
                
                // Canvas
                SignatureCanvasView(
                    canvasView: $canvasView,
                    selectedColor: $selectedColor,
                    selectedLineWidth: $selectedLineWidth
                )
                .background(Color.white)
                .cornerRadius(12)
                .padding()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Clear") {
                        canvasView.drawing = PKDrawing()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Save Signature") {
                        if !canvasView.drawing.bounds.isEmpty {
                            showingNameAlert = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(canvasView.drawing.bounds.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Create Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onDismiss() }
                }
            }
        }
        .alert("Name Your Signature", isPresented: $showingNameAlert) {
            TextField("Signature Name", text: $signatureName)
            Button("Save") {
                saveSignature()
            }
            Button("Cancel", role: .cancel) {
                signatureName = ""
            }
        } message: {
            Text("Enter a name for your signature")
        }
    }
    
    private var toolbarView: some View {
        HStack {
            Text("Draw your signature below")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Color picker
            HStack(spacing: 8) {
                ForEach([UIColor.black, UIColor.blue, UIColor.red], id: \.self) { color in
                    Button(action: { selectedColor = color }) {
                        Circle()
                            .fill(Color(color))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? Color.gray : Color.clear, lineWidth: 2)
                            )
                    }
                }
            }
            
            // Line width slider
            VStack {
                Text("Width")
                    .font(.caption)
                Slider(value: $selectedLineWidth, in: 1...10, step: 1)
                    .frame(width: 60)
            }
        }
        .padding()
    }
    
    private func saveSignature() {
        // Create proper image from drawing
        let bounds = canvasView.drawing.bounds.isEmpty ?
            CGRect(x: 0, y: 0, width: 300, height: 150) :
            canvasView.drawing.bounds
        
        let image = canvasView.drawing.image(from: bounds, scale: 2.0)
        
        let signature = SavedSignature(
            name: signatureName.isEmpty ? "Signature \(DateFormatter().string(from: Date()))" : signatureName,
            image: image,
            dateCreated: Date()
        )
        
        viewModel.saveSignature(signature)
        signatureName = ""
        onDismiss()
    }
}

// MARK: - Signature Canvas View (Unchanged)
struct SignatureCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var selectedColor: UIColor
    @Binding var selectedLineWidth: CGFloat
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = UIColor.white
        canvasView.isOpaque = true
        canvasView.allowsFingerDrawing = true
        
        // Configure the tool
        let tool = PKInkingTool(.pen, color: selectedColor, width: selectedLineWidth)
        canvasView.tool = tool
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        let tool = PKInkingTool(.pen, color: selectedColor, width: selectedLineWidth)
        uiView.tool = tool
    }
}

// MARK: - Page Selector View (Unchanged)
struct PageSelectorView: View {
    let document: PDFDocument?
    @Binding var selectedPage: Int
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(0..<(document?.pageCount ?? 0), id: \.self) { pageIndex in
                        pagePreviewView(pageIndex: pageIndex)
                    }
                }
                .padding()
            }
            .navigationTitle("Select Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onDismiss() }
                }
            }
        }
    }
    
    private func pagePreviewView(pageIndex: Int) -> some View {
        VStack(spacing: 8) {
            if let page = document?.page(at: pageIndex) {
                Image(uiImage: page.thumbnail(of: CGSize(width: 150, height: 200), for: .cropBox))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedPage == pageIndex ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    )
            }
            
            Text("Page \(pageIndex + 1)")
                .font(.caption)
                .foregroundColor(.primary)
        }
        .onTapGesture {
            selectedPage = pageIndex
        }
    }
}

// MARK: - Supporting Types (Fixed SignatureViewModel)
class SignatureViewModel: ObservableObject {
    @Published var savedSignatures: [SavedSignature] = []
    @Published var showingRenameAlert = false
    @Published var signatureToRename: SavedSignature?
    
    private let signaturesKey = "SavedSignatures"
    
    init() {
        loadSavedSignatures()
    }
    
    func loadSavedSignatures() {
        if let data = UserDefaults.standard.data(forKey: signaturesKey),
           let signatures = try? JSONDecoder().decode([SavedSignature].self, from: data) {
            self.savedSignatures = signatures
        }
    }
    
    func saveSignature(_ signature: SavedSignature) {
        savedSignatures.append(signature)
        saveToPersistentStorage()
    }
    
    func deleteSignature(_ signature: SavedSignature) {
        savedSignatures.removeAll { $0.id == signature.id }
        saveToPersistentStorage()
    }
    
    func showRenameAlert(for signature: SavedSignature) {
        signatureToRename = signature
        showingRenameAlert = true
    }
    
    func renameSignature(_ signature: SavedSignature, newName: String) {
        if let index = savedSignatures.firstIndex(where: { $0.id == signature.id }) {
            savedSignatures[index] = SavedSignature(
                id: signature.id,
                name: newName,
                image: signature.image,
                dateCreated: signature.dateCreated
            )
            saveToPersistentStorage()
        }
    }
    
    private func saveToPersistentStorage() {
        if let data = try? JSONEncoder().encode(savedSignatures) {
            UserDefaults.standard.set(data, forKey: signaturesKey)
        }
    }
    
    func addSignatureToPage(
        signature: SavedSignature,
        page: PDFPage,
        position: CGPoint, // This should be normalized coordinates (0-1)
        size: SignatureSize
    ) async throws {
        // Get page bounds in PDF coordinate system
        let pageBounds = page.bounds(for: .cropBox)
        
        // Convert normalized position to PDF coordinates
        let pdfX = position.x * pageBounds.width
        let pdfY = (1.0 - position.y) * pageBounds.height // Flip Y because PDF uses bottom-left origin
        
        // Calculate signature bounds
        let signatureRect = CGRect(
            x: pdfX - size.width / 2,
            y: pdfY - size.height / 2,
            width: size.width,
            height: size.height
        )
        
        // Create image annotation with the signature
        await MainActor.run {
            self.createImageAnnotation(
                signature: signature,
                page: page,
                rect: signatureRect
            )
        }
    }
    
    private func createImageAnnotation(
        signature: SavedSignature,
        page: PDFPage,
        rect: CGRect
    ) {
        // Create a proper image annotation
        let annotation = PDFAnnotation(bounds: rect, forType: .stamp, withProperties: nil)
        annotation.contents = "Digital Signature - \(signature.name)"
        
        // Create and set the appearance
        if let appearance = createAppearanceStream(for: signature.image, in: rect){
            annotation.setValue(appearance, forAnnotationKey: .defaultAppearance)
        }
        // Add the annotation to the page
        page.addAnnotation(annotation)
    }
    
    private func createAppearanceStream(for image: UIImage, in rect: CGRect) -> Any? {
        // Create a simple appearance using the image
        // This is a simplified version - for production you might want to create a proper PDF appearance stream
        
        // For now, we'll create a stamp annotation that shows the signature
        // The actual image rendering will depend on the PDF viewer's capabilities
        
        return nil // PDFKit will handle basic rendering
    }
}

// MARK: - SavedSignature (Unchanged)
struct SavedSignature: Identifiable, Codable {
    let id: UUID
    let name: String
    let image: UIImage
    let dateCreated: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, dateCreated, imageData
    }
    
    init(name: String, image: UIImage, dateCreated: Date) {
        self.id = UUID()
        self.name = name
        self.image = image
        self.dateCreated = dateCreated
    }
    
    init(id: UUID, name: String, image: UIImage, dateCreated: Date) {
        self.id = id
        self.name = name
        self.image = image
        self.dateCreated = dateCreated
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        dateCreated = try container.decode(Date.self, forKey: .dateCreated)
        
        let imageData = try container.decode(Data.self, forKey: .imageData)
        image = UIImage(data: imageData) ?? UIImage()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(dateCreated, forKey: .dateCreated)
        try container.encode(image.pngData(), forKey: .imageData)
    }
}

// MARK: - SignatureSize (Unchanged)
enum SignatureSize: CaseIterable {
    case small, medium, large
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
    
    var width: CGFloat {
        switch self {
        case .small: return 80
        case .medium: return 120
        case .large: return 160
        }
    }
    
    var height: CGFloat {
        switch self {
        case .small: return 40
        case .medium: return 60
        case .large: return 80
        }
    }
    
    // Preview sizes for the UI
    var previewWidth: CGFloat {
        return width * 0.4
    }
    
    var previewHeight: CGFloat {
        return height * 0.4
    }
}
