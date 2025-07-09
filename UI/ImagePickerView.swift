//
//  ImagePickerView.swift
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


// MARK: - Image Picker View
struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    let completion: ([UIImage]) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 0 // No limit
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(selectedImages: $selectedImages, completion: completion)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        @Binding var selectedImages: [UIImage]
        let completion: ([UIImage]) -> Void
        
        init(selectedImages: Binding<[UIImage]>, completion: @escaping ([UIImage]) -> Void) {
            self._selectedImages = selectedImages
            self.completion = completion
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            var images: [UIImage] = []
            let group = DispatchGroup()
            
            for result in results {
                group.enter()
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                        if let image = object as? UIImage {
                            images.append(image)
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.selectedImages = images
                self.completion(images)
            }
        }
    }
}
