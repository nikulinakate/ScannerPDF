//
//  SubscriptionType.swift
//  AIScannerFish
//
//  Created by user on 14.03.2025.
//
//
//  SubscriptionType.swift
//  AIScannerFish
//
//  Created by user on 14.03.2025.
//

import SwiftUI
import StoreKit

// MARK: - Product Identifiers
enum SubscriptionType: String, CaseIterable {
    case weeklyNoTrial = "com.nikulinakateapp.pdfeditor.subscription.weekly.notrial"
    case weeklyWithTrial = "com.nikulinakateapp.pdfeditor.subscription.weekly.trial"
    case yearlyNoTrial = "com.nikulinakateapp.pdfeditor.subscription.yearly"
    
    var displayName: String {
        switch self {
        case .weeklyNoTrial:
            return "Weekly Premium"
        case .weeklyWithTrial:
            return "Weekly Premium (with trial)"
        case .yearlyNoTrial:
            return "Annual Premium"
        }
    }
}

// MARK: - Subscription Status
enum SubscriptionStatus: Equatable {
    case notSubscribed
    case subscribed(expiryDate: Date)
}

// MARK: - Purchase Manager
class PurchaseManager: ObservableObject {
    // Published properties
    @Published private(set) var products: [Product] = []
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // Transaction listener
    private var transactionListener: Task<Void, Error>?
    
    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Product Loading
    @MainActor
    func loadProducts() async {
        print("🔄 Starting to load products...")
        isLoading = true
        defer {
            isLoading = false
            print("✅ Finished loading products. Count: \(products.count)")
        }
        
        do {
            let productIdentifiers = Set(SubscriptionType.allCases.map { $0.rawValue })
            print("🔍 Looking for products: \(productIdentifiers)")
            
            let storeProducts = try await Product.products(for: productIdentifiers)
            print("📦 Found \(storeProducts.count) products from App Store")
            
            // Debug each product
            for product in storeProducts {
                print("   - \(product.id): \(product.displayName) - \(product.displayPrice)")
            }
            
            // Sort products by price
            products = storeProducts.sorted {
                $0.price < $1.price
            }
            
            if products.isEmpty {
                print("⚠️ No products loaded - check App Store Connect configuration")
                showMessage("Unable to load subscription options. Please check your internet connection and try again.")
            }
            
        } catch {
            print("❌ Error loading products: \(error)")
            handleError(error)
        }
    }
    
    // MARK: - Transaction Handling
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // Update subscription status
                    await self.updateSubscriptionStatus()
                    
                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    // Handle transaction errors
                    await self.handleError(error)
                }
            }
        }
    }
    
    @MainActor
    func debugStoreKit() async {
        print("=== STOREKIT DEBUG ===")
        
        // Check if StoreKit is available
        print("StoreKit available: \(AppStore.canMakePayments)")
        
        // Check network connectivity
        do {
            let url = URL(string: "https://apps.apple.com")!
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print("Network status: \(httpResponse.statusCode)")
            }
        } catch {
            print("Network error: \(error)")
        }
        
        // Try to load a known Apple product for testing
        do {
            let testProducts = try await Product.products(for: ["com.apple.TestFlight"])
            print("Test product load successful: \(testProducts.count > 0)")
        } catch {
            print("Test product load failed: \(error)")
        }
        
        print("===================")
    }
    
    // MARK: - Purchase Methods
    @MainActor
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus()
                await transaction.finish()
                return true // Purchase successful
            case .userCancelled:
                return false // User cancelled
            case .pending:
                // Handle pending transactions (e.g., parental approval)
                showMessage("Purchase is pending approval")
                return false // Not completed yet
            default:
                return false
            }
        } catch {
            handleError(error)
            return false // Purchase failed
        }
    }
    
    // MARK: - Restore Purchases
    @MainActor
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            showMessage("Purchases restored successfully")
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Subscription Status Check
    @MainActor
    func updateSubscriptionStatus() async {
        // Check for active subscriptions
        var isSubscribed = false
        var expirationDate: Date?
        
        // Get all active transactions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if we have an active subscription
                // In StoreKit 2, check expiration date from transaction
                if transaction.productType == .autoRenewable,
                   let expiryDate = transaction.expirationDate,
                   transaction.revocationDate == nil,
                   expiryDate > Date() {
                    isSubscribed = true
                    expirationDate = expiryDate
                }
            } catch {
                print("Verification error: \(error)")
            }
        }
        
        // Update subscription status
        if isSubscribed, let expirationDate = expirationDate {
            self.subscriptionStatus = .subscribed(expiryDate: expirationDate)
        } else {
            self.subscriptionStatus = .notSubscribed
        }
        
    }
    
    // MARK: - Helper Methods
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.failedVerification
        }
    }
    
    @MainActor
    func handleError(_ error: Error) {
        print("Store error: \(error)")
        errorMessage = error.localizedDescription
        showError = true
    }
    
    @MainActor
    func showMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Custom Errors
enum StoreError: Error {
    case failedVerification
    case unknown
}
