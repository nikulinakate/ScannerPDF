//
//  Scanner_PDFApp.swift
//  Scanner PDF
//
//  Created by Nikulina Ekaterina on 04.07.2025.
//

import SwiftUI
import SwiftData
//import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//    FirebaseApp.configure()
    return true
  }
}

@main
struct Scanner_PDFApp: App {
    let modelContainer = PDFStorageManager.createModelContainer()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var purchaseManager = PurchaseManager()
    @AppStorage("hasSeenOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    ContentView()
                        .modelContainer(modelContainer)
                } else {
//                    PaywallView()
//                        .environmentObject(purchaseManager)
                    ScannerOnboardingFlow()
                        .environmentObject(purchaseManager)

                }
            }
            .onAppear {
                // Check if we should show onboarding
                if !hasCompletedOnboarding {
                    showOnboarding = true
                }
            }        }
    }
}
