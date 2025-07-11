//
//  PurchaseProvider.swift
//  AIScannerFish
//
//  Created by user on 14.03.2025.
//


import SwiftUI

// MARK: - Environment Provider for Purchase Manager
struct PurchaseProvider: ViewModifier {
    @StateObject private var purchaseManager = PurchaseManager()
    
    func body(content: Content) -> some View {
        content
            .environmentObject(purchaseManager)
            .alert(isPresented: $purchaseManager.showError) {
                Alert(
                    title: Text("Information"),
                    message: Text(purchaseManager.errorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
            }
    }
}

// MARK: - Extension for App and Views
extension View {
    func withPurchaseManager() -> some View {
        self.modifier(PurchaseProvider())
    }
}

// Use in App:
//
// @main
// struct AIScannerFishApp: App {
//     @AppStorage("darkMode") private var darkMode = false
//    
//     var body: some Scene {
//         WindowGroup {
//             ContentView()
//                 .preferredColorScheme(darkMode ? .dark : .light)
//                 .withPurchaseManager()
//         }
//     }
// }