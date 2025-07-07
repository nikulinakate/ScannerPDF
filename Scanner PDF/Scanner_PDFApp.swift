//
//  Scanner_PDFApp.swift
//  Scanner PDF
//
//  Created by Nikulina Ekaterina on 04.07.2025.
//

import SwiftUI

@main
struct Scanner_PDFApp: App {
    let modelContainer = PDFStorageManager.createModelContainer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
