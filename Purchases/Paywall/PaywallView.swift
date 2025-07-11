//
//  PaywallView.swift
//  ScannerPDF
//
//  Enhanced professional paywall with conversion-optimized design
//  Dynamic pricing with fallback prices and improved reliability
//

import SwiftUI
import StoreKit
import SafariServices

// MARK: - Fallback Price Structure
struct FallbackPrice {
    let productId: String
    let price: String
    let numericPrice: Decimal
    let locale: Locale
    
    static let fallbackPrices: [String: FallbackPrice] = [
        SubscriptionType.weeklyNoTrial.rawValue: FallbackPrice(
            productId: SubscriptionType.weeklyNoTrial.rawValue,
            price: "$6.99",
            numericPrice: 6.99,
            locale: Locale.current
        ),
        SubscriptionType.weeklyWithTrial.rawValue: FallbackPrice(
            productId: SubscriptionType.weeklyWithTrial.rawValue,
            price: "$4.99",
            numericPrice: 4.99,
            locale: Locale.current
        ),
        SubscriptionType.yearlyNoTrial.rawValue: FallbackPrice(
            productId: SubscriptionType.yearlyNoTrial.rawValue,
            price: "$39.99",
            numericPrice: 39.99,
            locale: Locale.current
        )
        ]
}

// MARK: - Supporting Views

struct ValuePropositionCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(BusinessTheme.lightAccent)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(BusinessTheme.lightAccent.opacity(0.1))
                )
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(BusinessTheme.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BusinessTheme.adaptiveTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(BusinessTheme.adaptiveSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(BusinessTheme.borderLight, lineWidth: 1)
                )
        )
    }
}

// MARK: - Compact Subscription Card
struct CompactSubscriptionCard: View {
    let product: Product
    let title: String
    let badge: String?
    let savings: String?
    let subtitle: String
    let isSelected: Bool
    let isRecommended: Bool
    let showTrial: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? BusinessTheme.lightAccent : Color.clear)
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .stroke(
                            isSelected ? BusinessTheme.lightAccent : BusinessTheme.borderMedium,
                            lineWidth: isSelected ? 0 : 2
                        )
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title and badge
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(BusinessTheme.adaptiveTextPrimary)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(BusinessTheme.premium)
                                )
                        }
                    }
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(BusinessTheme.adaptiveTextSecondary)
                }
                
                Spacer()
                
                // Pricing
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(BusinessTheme.adaptiveTextPrimary)
                    
                    if let savings = savings {
                        Text(savings)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(showTrial ? BusinessTheme.success : BusinessTheme.success)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(BusinessTheme.adaptiveSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? BusinessTheme.lightAccent : BusinessTheme.borderLight,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? BusinessTheme.lightAccent.opacity(0.15) : .black.opacity(0.03),
                        radius: isSelected ? 8 : 2,
                        y: isSelected ? 4 : 1
                    )
            )
        }
        .scaleEffect(isSelected ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(configuration.isOn ? BusinessTheme.lightAccent : Color(.systemGray4))
            .frame(width: 50, height: 30)
            .overlay(
                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isOn)
            )
            .onTapGesture {
                configuration.isOn.toggle()
            }
    }
}

// MARK: - Models
struct ValueProposition {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Product Wrapper for Consistent Interface
struct ProductInfo {
    let id: String
    let displayPrice: String
    let price: Decimal
    let isFromStore: Bool
    
    init(product: Product) {
        self.id = product.id
        self.displayPrice = product.displayPrice
        self.price = product.price
        self.isFromStore = true
    }
    
    init(fallback: FallbackPrice) {
        self.id = fallback.productId
        self.displayPrice = fallback.price
        self.price = fallback.numericPrice
        self.isFromStore = false
    }
}

// MARK: - Enhanced Paywall View
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var selectedSubscriptionIndex: Int = 0 // Default to annual (best value)
    @State private var showTrialOption: Bool = true
    @State private var isRestoring = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfUse = false
    @State private var animateContent = false
    @State private var productsLoadAttempts = 0
    @State private var showLoadingError = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    // Maximum attempts to load products before showing fallback
    private let maxLoadAttempts = 3
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic background with subtle overlay
                backgroundView
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with close button and restore
                    headerView
                        .padding(.top, 8)
                        .padding(.horizontal, 20)
                    VStack{
                        ScrollView {
                            VStack(spacing: 24) {
                                // Hero section - focused on PDF scanning
                                heroSection
                                    .padding(.top, 20)
                                
                                
                                
                                // Core value proposition with icons
                                valuePropositionSection
                                    .padding(.top, 16)
                                
                                
                                // Trust indicators and testimonial
                                trustSection
                                    .padding(.bottom, 160) // Increased space for legal buttons
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                    
                    // Fixed bottom CTA with legal buttons
                    VStack {
                        Spacer()
                        
                        // Subscription options with prominent pricing
                        subscriptionCardsSection
                            .padding(.horizontal, 20)
                            .background(Color(.systemBackground))
                        
                        // Product loading status indicator
                        if !hasValidProducts && productsLoadAttempts < maxLoadAttempts {
                            loadingIndicatorView
                                .padding(.vertical, 8)
                        }
                        
                        bottomCTAView
                    }
                }
            }
        }
        .overlay {
            if purchaseManager.isLoading && productsLoadAttempts == 0 || isRestoring {
                loadingOverlay
            }
        }
        .alert(isPresented: $purchaseManager.showError) {
            Alert(
                title: Text("Error"),
                message: Text(purchaseManager.errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Products Not Available", isPresented: $showLoadingError) {
            Button("Retry") {
                Task {
                    await loadProductsWithRetry()
                }
            }
            Button("Continue with Fallback", role: .cancel) {
                // Continue with fallback prices
            }
        } message: {
            Text("Unable to load current prices from App Store. Using fallback pricing.")
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            SafariView(url: AppConstants.URLs.privacyPolicy)
        }
        .sheet(isPresented: $showTermsOfUse) {
            SafariView(url: AppConstants.URLs.termsOfUse)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateContent = true
            }
        }
        .task {
            await loadProductsWithRetry()
        }
    }
    
    // MARK: - Product Loading Logic
    private func loadProductsWithRetry() async {
        productsLoadAttempts += 1
        
        // Debug StoreKit
        await purchaseManager.debugStoreKit()
        
        // Force reload products
        await purchaseManager.loadProducts()
        
        // Debug what we got
        print("=== PAYWALL DEBUG (Attempt \(productsLoadAttempts)) ===")
        print("Total products: \(purchaseManager.products.count)")
        for product in purchaseManager.products {
            print("  - \(product.id): \(product.displayPrice)")
        }
        print("Weekly trial: \(weeklyProductWithTrial?.id ?? "nil")")
        print("Weekly no trial: \(weeklyProductNoTrial?.id ?? "nil")")
        print("Yearly: \(yearlyProduct?.id ?? "nil")")
        print("Using fallback: \(!hasValidProducts)")
        print("====================")
        
        // If we don't have products and haven't exceeded max attempts, retry
        if !hasValidProducts && productsLoadAttempts < maxLoadAttempts {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds
            await loadProductsWithRetry()
        } else if !hasValidProducts && productsLoadAttempts >= maxLoadAttempts {
            showLoadingError = true
        }
    }
    
    // MARK: - Helper Properties
    private var hasValidProducts: Bool {
        return weeklyProductWithTrial != nil &&
        weeklyProductNoTrial != nil &&
        yearlyProduct != nil
    }
    
    private var weeklyProductInfoNoTrial: ProductInfo {
        if let product = weeklyProductNoTrial {
            return ProductInfo(product: product)
        } else if let fallback = FallbackPrice.fallbackPrices[SubscriptionType.weeklyNoTrial.rawValue] {
            return ProductInfo(fallback: fallback)
        }
        // Should never reach here, but provide ultimate fallback
        return ProductInfo(fallback: FallbackPrice(
            productId: SubscriptionType.weeklyNoTrial.rawValue,
            price: "$7.99",
            numericPrice: 7.99,
            locale: Locale.current
        ))
    }
    
    private var weeklyProductInfoWithTrial: ProductInfo {
        if let product = weeklyProductWithTrial {
            return ProductInfo(product: product)
        } else if let fallback = FallbackPrice.fallbackPrices[SubscriptionType.weeklyWithTrial.rawValue] {
            return ProductInfo(fallback: fallback)
        }
        // Should never reach here, but provide ultimate fallback
        return ProductInfo(fallback: FallbackPrice(
            productId: SubscriptionType.weeklyWithTrial.rawValue,
            price: "$5.99",
            numericPrice: 5.99,
            locale: Locale.current
        ))
    }
    
    private var yearlyProductInfo: ProductInfo {
        if let product = yearlyProduct {
            return ProductInfo(product: product)
        } else if let fallback = FallbackPrice.fallbackPrices[SubscriptionType.yearlyNoTrial.rawValue] {
            return ProductInfo(fallback: fallback)
        }
        // Should never reach here, but provide ultimate fallback
        return ProductInfo(fallback: FallbackPrice(
            productId: SubscriptionType.yearlyNoTrial.rawValue,
            price: "$69.99",
            numericPrice: 69.99,
            locale: Locale.current
        ))
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            // Clean gradient background
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    BusinessTheme.adaptivePrimary.opacity(0.03),
                    BusinessTheme.adaptiveSecondary.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Subtle pattern overlay
            if colorScheme == .dark {
                Color.black.opacity(0.2)
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button {
                hasSeenOnboarding = true
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(BusinessTheme.adaptiveTextSecondary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(BusinessTheme.adaptiveSurface)
                            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                    )
            }
            
            Spacer()
        }
    }
    
    // MARK: - Loading Indicator
    private var loadingIndicatorView: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(BusinessTheme.lightAccent)
            
            Text("Loading current prices...")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(BusinessTheme.adaptiveTextSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(BusinessTheme.adaptiveSurface)
                .overlay(
                    Capsule()
                        .stroke(BusinessTheme.borderLight, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 20) {
            // App Store rating
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "laurel.leading")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(BusinessTheme.premium)
                    
                    VStack(spacing: 6) {
                        Text("4.9")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(BusinessTheme.adaptiveTextPrimary)
                        
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < 5 ? "star.fill" : "star")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(BusinessTheme.premium)
                            }
                        }
                    }
                    
                    Image(systemName: "laurel.trailing")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(BusinessTheme.premium)
                }
                
                Text("App Store Rating")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(BusinessTheme.adaptiveTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(BusinessTheme.adaptiveSurface)
                            .overlay(
                                Capsule()
                                    .stroke(BusinessTheme.borderLight, lineWidth: 1)
                            )
                    )
            }
            .scaleEffect(animateContent ? 1 : 0.8)
            .opacity(animateContent ? 1 : 0)
            
            // Main headline
            VStack(spacing: 8) {
                Text("Unlock Professional")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(BusinessTheme.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Document Scanning")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(BusinessTheme.lightAccent)
                    .multilineTextAlignment(.center)
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            
            Text("Scan unlimited documents, remove ads & get advanced OCR features")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(BusinessTheme.adaptiveTextSecondary)
                .multilineTextAlignment(.center)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.5), value: animateContent)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Subscription Cards with Dynamic Pricing
    private var subscriptionCardsSection: some View {
        VStack(spacing: 12) {
            // Pricing header
            HStack {
                Text("Choose Your Plan")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(BusinessTheme.adaptiveTextPrimary)
                
                Spacer()
                
                // Show fallback indicator if using fallback prices
                if !hasValidProducts {
                    HStack(spacing: 4) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 12))
                            .foregroundColor(BusinessTheme.adaptiveTextTertiary)
                        
                        Text("Offline Pricing")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(BusinessTheme.adaptiveTextTertiary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(BusinessTheme.adaptiveTextTertiary.opacity(0.1))
                    )
                }
            }
            .opacity(animateContent ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
            
            // Annual subscription card (Featured)
            if let yearlyProduct = yearlyProduct{
                CompactSubscriptionCard(
                    product: yearlyProduct,
                    title: "Annual Plan",
                    badge: "MOST POPULAR",
                    savings: calculateSavings(for: yearlyProductInfo),
                    subtitle: "Best value for power users",
                    isSelected: selectedSubscriptionIndex == 0,
                    isRecommended: true,
                    showTrial: false
                ) {
                    selectedSubscriptionIndex = 0
                }
                .scaleEffect(animateContent ? 1 : 0.9)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateContent)
            }
            if let weeklyProductWithTrial = weeklyProductWithTrial, let weeklyProductNoTrial = weeklyProductNoTrial{
                // Weekly subscription card
                CompactSubscriptionCard(
                    product: showTrialOption ? weeklyProductWithTrial : weeklyProductNoTrial,
                    title: "Weekly Plan",
                    badge: nil,
                    savings: showTrialOption ? "3-day free trial" : nil,
                    subtitle: "Perfect for quick projects",
                    isSelected: selectedSubscriptionIndex == 1,
                    isRecommended: false,
                    showTrial: showTrialOption
                ) {
                    selectedSubscriptionIndex = 1
                }
                .scaleEffect(animateContent ? 1 : 0.9)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: animateContent)
            }
            // Trial toggle for weekly plan
            if selectedSubscriptionIndex == 1 {
                HStack {
                    Text("Free trial activated")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(BusinessTheme.success)
                    
                    Spacer()
                    
                    Toggle("", isOn: $showTrialOption)
                        .toggleStyle(ModernToggleStyle())
                        .scaleEffect(0.8)
                }
                .padding(.horizontal, 20)
                .transition(.opacity.combined(with: .scale))
            }
        }
    }
    
    // MARK: - Value Proposition
    private var valuePropositionSection: some View {
        VStack(spacing: 16) {
            Text("Everything You Need")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(BusinessTheme.adaptiveTextPrimary)
                .opacity(animateContent ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.8), value: animateContent)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(Array(valuePropositions.enumerated()), id: \.offset) { index, proposition in
                    ValuePropositionCard(
                        icon: proposition.icon,
                        title: proposition.title,
                        description: proposition.description
                    )
                    .opacity(animateContent ? 1 : 0)
                    .scaleEffect(animateContent ? 1 : 0.8)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8).delay(0.9 + Double(index) * 0.1),
                        value: animateContent
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Trust Section
    private var trustSection: some View {
        VStack(spacing: 16) {
            // Customer testimonial
            VStack(spacing: 12) {
                Text("\"Game changer for my paperless office! The OCR is incredibly accurate and the cloud sync keeps everything organized.\"")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(BusinessTheme.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)
                    .italic()
                    .padding(.horizontal, 20)
                
                HStack(spacing: 8) {
                    Text("⭐⭐⭐⭐⭐")
                    Text("Michael R., Project Manager")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(BusinessTheme.adaptiveTextSecondary)
                }
            }
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(BusinessTheme.adaptiveSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(BusinessTheme.borderLight, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
        .opacity(animateContent ? 0.8 : 0)
        .animation(.easeOut(duration: 0.6).delay(1.2), value: animateContent)
    }
    
    // MARK: - Bottom CTA with Legal Buttons
    private var bottomCTAView: some View {
        VStack(spacing: 0) {
            // Gradient overlay
            LinearGradient(
                colors: [
                    Color(.systemBackground).opacity(0),
                    Color(.systemBackground).opacity(0.9),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            
            VStack(spacing: 16) {
                // Current selection summary
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedSubscriptionIndex == 0 ? "Annual Plan" : "Weekly Plan")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(BusinessTheme.adaptiveTextPrimary)
                        
                        let selectedProductInfo = selectedProductInfo
                        Text(selectedProductInfo.displayPrice + "/" + (selectedSubscriptionIndex == 0 ? "year" : "week"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(BusinessTheme.adaptiveTextSecondary)
                    }
                    
                    Spacer()
                    
                    if selectedSubscriptionIndex == 0, let savings = calculateSavings(for: selectedProductInfo) {
                        Text(savings)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(BusinessTheme.success)
                            )
                    }
                }
                .padding(.horizontal, 20)
                
                // Main CTA button
                Button {
                    let productInfo = selectedProductInfo
                    
                    // If using store product, purchase normally
                    if productInfo.isFromStore,
                       let product = getStoreProduct(for: productInfo.id) {
                        Task {
                            let success = await purchaseManager.purchase(product)
                            if success {
                                hasSeenOnboarding = true
                                dismiss()
                            }
                        }
                    } else {
                        // Handle fallback purchase - show message to user
                        showFallbackPurchaseAlert()
                    }
                } label: {
                    HStack {
                        Spacer()
                        
                        if selectedSubscriptionIndex == 1 && showTrialOption {
                            Text("Start Free Trial")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        } else {
                            Text("Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        // Show indicator if using fallback
                        if !selectedProductInfo.isFromStore {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        BusinessTheme.lightAccent,
                                        BusinessTheme.darkAccent
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: BusinessTheme.lightAccent.opacity(0.3), radius: 8, y: 4)
                    )
                }
                .scaleEffect(animateContent ? 1 : 0.95)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0), value: animateContent)
                
                // Legal buttons
                legalButtonsView
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Legal Buttons
    private var legalButtonsView: some View {
        VStack(spacing: 12) {
            // Subscription note
            Text("Subscription will be charged to your Apple ID account. Auto-renews unless cancelled 24 hours before the end of the current period.")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(BusinessTheme.adaptiveTextTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            
            // Legal buttons
            HStack(spacing: 24) {
                Button {
                    showPrivacyPolicy = true
                } label: {
                    Text("Privacy Policy")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(BusinessTheme.lightAccent)
                        .underline()
                }
                
                Text("•")
                    .font(.system(size: 13))
                    .foregroundColor(BusinessTheme.adaptiveTextTertiary)
                
                Button {
                    showTermsOfUse = true
                } label: {
                    Text("Terms of Use")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(BusinessTheme.lightAccent)
                        .underline()
                }
                
                Text("•")
                    .font(.system(size: 13))
                    .foregroundColor(BusinessTheme.adaptiveTextTertiary)
                
                Button {
                    isRestoring = true
                    Task {
                        await purchaseManager.restorePurchases()
                        isRestoring = false
                    }
                } label: {
                    Text("Restore")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(BusinessTheme.lightAccent)
                        .underline()
                }
            }
        }
        .opacity(animateContent ? 0.8 : 0)
        .animation(.easeOut(duration: 0.6).delay(1.4), value: animateContent)
    }
    
    // MARK: - Helper Functions
    private func calculateSavings(for productInfo: ProductInfo) -> String? {
        let yearlyInfo = yearlyProductInfo
        let weeklyInfo = weeklyProductInfoNoTrial
        
        // Calculate yearly cost of weekly subscription
        let weeklyYearlyCost = weeklyInfo.price * 52
        let yearlyCost = yearlyInfo.price
        
        if weeklyYearlyCost > yearlyCost {
            let savingsPercentage = ((weeklyYearlyCost - yearlyCost) / weeklyYearlyCost) * 100
            let savings = Int(Double(truncating: savingsPercentage as NSNumber).rounded())
            return "Save \(savings)%"
        }
        
        return nil
    }
    
    private func formatMonthlyPrice(for productInfo: ProductInfo) -> String {
        let monthlyPrice = productInfo.price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: monthlyPrice as NSNumber) ?? ""
    }
    
    private func getStoreProduct(for productId: String) -> Product? {
        return purchaseManager.products.first { $0.id == productId }
    }
    
    private func showFallbackPurchaseAlert() {
        // This would typically show an alert or redirect to manual purchase flow
        let alert = UIAlertController(
            title: "Purchase Unavailable",
            message: "In-app purchases are currently unavailable. Please try again later or contact support.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            Task {
                await loadProductsWithRetry()
            }
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    // MARK: - Computed Properties
    private var weeklyProductNoTrial: Product? {
        purchaseManager.products.first { $0.id == SubscriptionType.weeklyNoTrial.rawValue }
    }
    
    private var weeklyProductWithTrial: Product? {
        purchaseManager.products.first { $0.id == SubscriptionType.weeklyWithTrial.rawValue }
    }
    
    private var yearlyProduct: Product? {
        purchaseManager.products.first { $0.id == SubscriptionType.yearlyNoTrial.rawValue }
    }
    
    private var selectedProductInfo: ProductInfo {
        if selectedSubscriptionIndex == 0 {
            return yearlyProductInfo
        } else {
            return showTrialOption ? weeklyProductInfoWithTrial : weeklyProductInfoNoTrial
        }
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
                
                Text(isRestoring ? "Restoring..." : "Loading products...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    // MARK: - Value Propositions for Scanner PDF
    private let valuePropositions = [
        ValueProposition(
            icon: "doc.text.viewfinder",
            title: "Unlimited Scans",
            description: "Scan documents without any limits"
        ),
        ValueProposition(
            icon: "textformat.abc",
            title: "Advanced OCR",
            description: "Extract text with 99% accuracy"
        ),
        ValueProposition(
            icon: "icloud.and.arrow.up",
            title: "Cloud Sync",
            description: "Access your docs across all devices"
        ),
        ValueProposition(
            icon: "rectangle.stack.badge.minus",
            title: "No Ads",
            description: "Clean, distraction-free experience"
        ),
        ValueProposition(
            icon: "doc.badge.gearshape",
            title: "Auto Enhancement",
            description: "Perfect quality with one tap"
        ),
        ValueProposition(
            icon: "folder.badge.plus",
            title: "Smart Organization",
            description: "Auto-categorize and search docs"
        )
    ]
}

