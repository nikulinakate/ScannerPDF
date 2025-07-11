//
//  ScannerOnboardingFlow.swift
//  ScannerPro
//
//  Enhanced PDF Scanner App Onboarding with Modern UX/UI
//

import SwiftUI
import AVFoundation

// MARK: - Main Scanner Onboarding Container
struct ScannerOnboardingFlow: View {
    @State private var currentPage = 0
    @State private var animateContent = false
    @State private var userType: ScannerUserType?
    @State private var showingUserTypeSelection = true
    @State private var showingPermissions = false
    @State private var cameraPermissionGranted = false
    @State private var notificationPermissionGranted = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    @State private var dragOffset: CGSize = .zero
    @State private var isInteracting = false
    @State private var scannerPreviewActive = false
    
    private var onboardingPages: [ScannerOnboardingPage] {
        ScannerOnboardingPage.pagesForUserType(userType ?? .personal)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView
                    .ignoresSafeArea()
                
                if showingUserTypeSelection {
                    ScannerUserTypeSelectionView(
                        selectedUserType: $userType,
                        onContinue: {
                            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                                showingUserTypeSelection = false
                                animateContent = true
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
                } else if showingPermissions {
                    PermissionRequestView(
                        cameraGranted: $cameraPermissionGranted,
                        notificationGranted: $notificationPermissionGranted,
                        onComplete: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
//                                showingPermissions = false
//                                // Complete onboarding
//                                hasSeenOnboarding = true
//                                dismiss()
                                showPaywall = true
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity
                    ))
                } else {
                    mainOnboardingContent(geometry: geometry)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity
                        ))
                }
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
                .withPurchaseManager()
        }
        .statusBarHidden(scannerPreviewActive)
    }
    
    // MARK: - Main Onboarding Content
    private func mainOnboardingContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Enhanced header with scanner-specific navigation
            enhancedHeaderView(geometry: geometry)
            
            // Main content with gesture support and scanner previews
            ZStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        ScannerOnboardingPageView(
                            page: onboardingPages[index],
                            isActive: currentPage == index,
                            animateContent: $animateContent,
                            safeAreaBottom: geometry.safeAreaInsets.bottom,
                            userType: userType ?? .personal,
                            scannerPreviewActive: $scannerPreviewActive
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .offset(x: dragOffset.width)
                .scaleEffect(isInteracting ? 0.98 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isInteracting)
                .gesture(createSwipeGesture())
            }
            
            // Enhanced bottom section with scanner-specific CTAs
            enhancedBottomSection(geometry: geometry)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateContent = true
            }
        }
        .onChange(of: currentPage) { _, _ in
            triggerPageChangeAnimation()
            triggerHapticFeedback()
        }
    }
    
    // MARK: - Enhanced Background with Scanner Elements
    private var backgroundView: some View {
        ZStack {
            // Dynamic gradient based on current scanning mode
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    (userType?.primaryColor ?? ScannerTheme.adaptivePrimary).opacity(0.05),
                    (onboardingPages.isEmpty ? ScannerTheme.adaptiveSecondary : onboardingPages[safe: currentPage]?.accentColor ?? ScannerTheme.adaptiveSecondary).opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .animation(.easeInOut(duration: 0.8), value: currentPage)
            
            // Subtle scanner grid pattern
            if animateContent {
                ScannerGridOverlay()
                    .opacity(0.02)
                    .animation(.easeIn(duration: 1.2).delay(0.5), value: animateContent)
            }
        }
    }
    
    // MARK: - Enhanced Header with Scanner Theme
    private func enhancedHeaderView(geometry: GeometryProxy) -> some View {
        HStack {
            // Back button with scanner styling
            Button {
                handleBackNavigation()
            } label: {
                Image(systemName: currentPage > 0 ? "chevron.left" : "viewfinder.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ScannerTheme.adaptiveTextSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(ScannerTheme.adaptiveSurface)
                            .shadow(color: ScannerTheme.shadowLight, radius: 6, y: 2)
                    )
            }
            .opacity(animateContent ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.3), value: animateContent)
            
            Spacer()
            
            // Enhanced progress indicator with scanner theme
            scannerProgressIndicator
            
            Spacer()
            
            // Skip with scanner UX
            Button {
                showQuickDemo()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 12, weight: .medium))
                    Text("Quick Demo")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(ScannerTheme.adaptiveTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(ScannerTheme.adaptiveSurface)
                        .overlay(
                            Capsule()
                                .stroke(ScannerTheme.borderLight, lineWidth: 1)
                        )
                )
            }
            .opacity(currentPage < onboardingPages.count - 1 ? (animateContent ? 1 : 0) : 0)
            .animation(.easeOut(duration: 0.6).delay(0.5), value: animateContent)
        }
        .padding(.top, geometry.safeAreaInsets.top + 12)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Scanner Progress Indicator
    private var scannerProgressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<onboardingPages.count, id: \.self) { index in
                ZStack {
                    // Background track
                    Capsule()
                        .fill(ScannerTheme.borderMedium)
                        .frame(width: index == currentPage ? 28 : 8, height: 4)
                    
                    // Progress fill with scanner color
                    if index <= currentPage {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        onboardingPages[safe: currentPage]?.accentColor ?? ScannerTheme.lightPrimary,
                                        (onboardingPages[safe: currentPage]?.accentColor ?? ScannerTheme.lightPrimary).opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: index == currentPage ? 28 : 8, height: 4)
                    }
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentPage)
            }
        }
        .opacity(animateContent ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateContent)
    }
    
    // MARK: - Enhanced Bottom Section
    private func enhancedBottomSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    Color(.systemBackground).opacity(0),
                    Color(.systemBackground).opacity(0.9),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 32)
            
            VStack(spacing: 20) {
                // Scanner-specific progress text
                if currentPage < onboardingPages.count - 1 {
                    scannerProgressText
                }
                
                // Enhanced CTA buttons with scanner styling
                scannerCTAButtons
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, max(geometry.safeAreaInsets.bottom, 24))
            .background(Color(.systemBackground))
        }
    }
    
    private var scannerProgressText: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.viewfinder.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ScannerTheme.adaptiveAccent)
            
            Text("Feature \(currentPage + 1) of \(onboardingPages.count)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ScannerTheme.adaptiveTextSecondary)
        }
        .opacity(animateContent ? 0.8 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.8), value: animateContent)
    }
    
    private var scannerCTAButtons: some View {
        VStack(spacing: 16) {
            // Primary CTA with high contrast
            Button {
                handlePrimaryCTA()
            } label: {
                HStack(spacing: 12) {
                    if currentPage < onboardingPages.count - 1 {
                        Text("Continue")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Start Scanning")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    onboardingPages[safe: currentPage]?.accentColor ?? ScannerTheme.lightPrimary,
                                    (onboardingPages[safe: currentPage]?.accentColor ?? ScannerTheme.lightPrimary).opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            // Add subtle inner highlight for depth
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: (onboardingPages[safe: currentPage]?.accentColor ?? ScannerTheme.lightPrimary).opacity(0.4),
                            radius: 16,
                            y: 8
                        )
                )
            }
            .scaleEffect(animateContent ? 1 : 0.95)
            .opacity(animateContent ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.9), value: animateContent)
        }
    }
    
    // MARK: - Gesture Handling
    private func createSwipeGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                if !isInteracting {
                    isInteracting = true
                }
                dragOffset = value.translation
            }
            .onEnded { value in
                isInteracting = false
                dragOffset = .zero
                
                let threshold: CGFloat = 80
                if value.translation.width > threshold && currentPage > 0 {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        currentPage -= 1
                    }
                } else if value.translation.width < -threshold && currentPage < onboardingPages.count - 1 {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        currentPage += 1
                    }
                }
            }
    }
    
    // MARK: - Helper Functions
    private func triggerPageChangeAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            animateContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
        }
    }
    
    private func triggerHapticFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func handleBackNavigation() {
        if currentPage > 0 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentPage -= 1
            }
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showingUserTypeSelection = true
                currentPage = 0
            }
        }
    }
    
    private func handlePrimaryCTA() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        if currentPage < onboardingPages.count - 1 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentPage += 1
            }
        } else {
            // Move to permissions instead of paywall
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showingPermissions = true
            }
        }
    }
    
    private func showQuickDemo() {
        let alert = UIAlertController(
            title: "Scanner Pro Demo",
            message: "✓ Scan documents instantly\n✓ OCR text recognition\n✓ Cloud sync & organization\n✓ PDF editing & sharing",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Start Scanning", style: .default) { _ in
            showingPermissions = true
        })
        
        alert.addAction(UIAlertAction(title: "See Full Features", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

// MARK: - Scanner Grid Overlay
struct ScannerGridOverlay: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 30
            
            // Draw grid lines
            for x in stride(from: 0, through: size.width, by: spacing) {
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    },
                    with: .color(ScannerTheme.adaptivePrimary),
                    lineWidth: 0.5
                )
            }
            
            for y in stride(from: 0, through: size.height, by: spacing) {
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    },
                    with: .color(ScannerTheme.adaptivePrimary),
                    lineWidth: 0.5
                )
            }
        }
    }
}

// MARK: - Scanner User Type Selection
struct ScannerUserTypeSelectionView: View {
    @Binding var selectedUserType: ScannerUserType?
    let onContinue: () -> Void
    @State private var animateIn = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Header with scanner theme
            VStack(spacing: 20) {
                ZStack {
                    // Animated scanner frame effect
                    ForEach(0..<3, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                ScannerTheme.lightPrimary.opacity(0.3 - Double(index) * 0.1),
                                lineWidth: 2
                            )
                            .frame(width: 80 + CGFloat(index * 15), height: 60 + CGFloat(index * 10))
                            .scaleEffect(animateIn ? 1 : 0.8)
                            .opacity(animateIn ? 1 : 0)
                            .animation(
                                .easeOut(duration: 0.8).delay(0.2 + Double(index) * 0.15),
                                value: animateIn
                            )
                    }
                    
                    Image(systemName: "doc.viewfinder.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(ScannerTheme.lightPrimary)
                        .scaleEffect(animateIn ? 1 : 0.5)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.6), value: animateIn)
                }
                
                VStack(spacing: 12) {
                    Text("Welcome to PDF Scanner")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(ScannerTheme.adaptiveTextPrimary)
                    
                    Text("How will you be using PDF Scanner?")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ScannerTheme.adaptiveTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 25)
                .animation(.easeOut(duration: 0.8).delay(0.8), value: animateIn)
            }
            
            // User type options with scanner styling
            VStack(spacing: 20) {
                ForEach(ScannerUserType.allCases, id: \.self) { userType in
                    ScannerUserTypeCard(
                        userType: userType,
                        isSelected: selectedUserType == userType,
                        onTap: {
                            selectedUserType = userType
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                    )
                    .opacity(animateIn ? 1 : 0)
                    .offset(x: animateIn ? 0 : -40)
                    .animation(
                        .easeOut(duration: 0.6).delay(1.0 + Double(userType.rawValue) * 0.1),
                        value: animateIn
                    )
                }
            }
            .padding(.horizontal, 20)
            
            // Continue button with proper contrast
            Button {
                onContinue()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Start Scanning Journey")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    selectedUserType?.primaryColor ?? ScannerTheme.lightPrimary,
                                    (selectedUserType?.primaryColor ?? ScannerTheme.lightPrimary).opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            // Add subtle inner shadow for depth
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: (selectedUserType?.primaryColor ?? ScannerTheme.lightPrimary).opacity(0.4),
                            radius: 16,
                            y: 8
                        )
                )
            }
            .disabled(selectedUserType == nil)
            .opacity(selectedUserType != nil ? (animateIn ? 1 : 0) : 0.6)
            .scaleEffect(selectedUserType != nil ? (animateIn ? 1 : 0.95) : 0.95)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.4), value: animateIn)
            .animation(.easeInOut(duration: 0.3), value: selectedUserType)
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
    }
}

// MARK: - Scanner User Type Card
struct ScannerUserTypeCard: View {
    let userType: ScannerUserType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                // Enhanced icon with scanner styling
                ZStack {
                    Circle()
                        .fill(isSelected ? userType.primaryColor : userType.primaryColor.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    if isSelected {
                        Circle()
                            .stroke(userType.primaryColor.opacity(0.3), lineWidth: 3)
                            .frame(width: 64, height: 64)
                    }
                    
                    Image(systemName: userType.iconName)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? .white : userType.primaryColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(userType.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? .white : ScannerTheme.adaptiveTextPrimary)
                    
                    Text(userType.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .white.opacity(0.9) : ScannerTheme.adaptiveTextSecondary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                }
                
                Spacer()
                
                // Selection indicator with scanner styling
                ZStack {
                    Circle()
                        .fill(isSelected ? .white : ScannerTheme.borderMedium)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(userType.primaryColor)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? userType.primaryColor : ScannerTheme.adaptiveSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? userType.primaryColor : ScannerTheme.borderLight,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? userType.primaryColor.opacity(0.3) : ScannerTheme.shadowLight,
                        radius: isSelected ? 16 : 8,
                        y: isSelected ? 8 : 4
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Enhanced Scanner Onboarding Page View
struct ScannerOnboardingPageView: View {
    let page: ScannerOnboardingPage
    let isActive: Bool
    @Binding var animateContent: Bool
    let safeAreaBottom: CGFloat
    let userType: ScannerUserType
    @Binding var scannerPreviewActive: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 48) {
                        // Interactive scanner preview section
                        interactiveScannerSection
                            .padding(.top, 24)
                        
                        // Personalized content with scanner features
                        personalizedScannerContentSection
                            .padding(.horizontal, 24)
                    }
                    .frame(minHeight: calculateMinHeight(geometry: geometry))
                    
                    Spacer()
                        .frame(height: 160 + safeAreaBottom)
                }
            }
            .scrollIndicators(.hidden)
        }
    }
    
    private func calculateMinHeight(geometry: GeometryProxy) -> CGFloat {
        let availableHeight = geometry.size.height
        let bottomSectionHeight: CGFloat = 160 + safeAreaBottom
        let headerHeight: CGFloat = 90
        
        return max(availableHeight - bottomSectionHeight - headerHeight, 450)
    }
    
    // MARK: - Interactive Scanner Section
    private var interactiveScannerSection: some View {
        VStack(spacing: 32) {
            ZStack {
                // Animated background elements
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    page.accentColor.opacity(0.12 - Double(index) * 0.02),
                                    page.accentColor.opacity(0.06 - Double(index) * 0.01)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(
                            width: 140 + CGFloat(index * 20),
                            height: 100 + CGFloat(index * 15)
                        )
                        .scaleEffect(animateContent ? 1 : 0.7 + Double(index) * 0.05)
                        .opacity(animateContent ? 1 : 0)
                        .rotationEffect(.degrees(animateContent ? Double(index * 2) : Double(index * 8)))
                        .animation(
                            .spring(response: 0.9 + Double(index) * 0.2, dampingFraction: 0.7)
                            .delay(0.1 + Double(index) * 0.1),
                            value: animateContent
                        )
                }
                
                // Main scanner icon with interaction
                Button {
                    // Simulate scanner preview
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        scannerPreviewActive.toggle()
                    }
                    
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                } label: {
                    ZStack {
                        // Scanner viewfinder frame
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(page.accentColor, lineWidth: 3)
                            .frame(width: 80, height: 60)
                        
                        // Corner markers
                        ForEach(0..<4, id: \.self) { corner in
                            ScannerCornerMarker(corner: corner, color: page.accentColor)
                        }
                        
                        Image(systemName: page.iconName)
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(page.accentColor)
                    }
                    .scaleEffect(animateContent ? 1 : 0.6)
                    .opacity(animateContent ? 1 : 0)
                    .rotationEffect(.degrees(animateContent ? 0 : -20))
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.5), value: animateContent)
                }
            }
        }
    }
    
    // MARK: - Personalized Scanner Content Section
    private var personalizedScannerContentSection: some View {
        VStack(spacing: 36) {
            // Title with scanner context
            VStack(spacing: 16) {
                Text(page.getPersonalizedTitle(for: userType))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(ScannerTheme.adaptiveTextPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: animateContent)
                
                if let subtitle = page.subtitle {
                    Text(subtitle)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(page.accentColor)
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.7), value: animateContent)
                }
            }
            
            // Personalized description
            Text(page.getPersonalizedDescription(for: userType))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ScannerTheme.adaptiveTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 25)
                .animation(.easeOut(duration: 0.8).delay(0.8), value: animateContent)
            
            // Enhanced scanner feature highlights
            if !page.features.isEmpty {
                LazyVStack(spacing: 20) {
                    ForEach(Array(page.features.enumerated()), id: \.offset) { index, feature in
                        EnhancedScannerFeatureHighlight(
                            feature: feature,
                            accentColor: page.accentColor,
                            userType: userType
                        )
                        .opacity(animateContent ? 1 : 0)
                        .offset(x: animateContent ? 0 : -30)
                        .animation(
                            .easeOut(duration: 0.6).delay(0.9 + Double(index) * 0.15),
                            value: animateContent
                        )
                    }
                }
                .padding(.top, 12)
            }
        }
    }
}

// MARK: - Scanner Corner Marker
struct ScannerCornerMarker: View {
    let corner: Int
    let color: Color
    
    var body: some View {
        let size: CGFloat = 16
        let thickness: CGFloat = 3
        
        Path { path in
            switch corner {
            case 0: // Top-left
                path.move(to: CGPoint(x: -40, y: -30 + size))
                path.addLine(to: CGPoint(x: -40, y: -30))
                path.addLine(to: CGPoint(x: -40 + size, y: -30))
            case 1: // Top-right
                path.move(to: CGPoint(x: 40 - size, y: -30))
                path.addLine(to: CGPoint(x: 40, y: -30))
                path.addLine(to: CGPoint(x: 40, y: -30 + size))
            case 2: // Bottom-right
                path.move(to: CGPoint(x: 40, y: 30 - size))
                path.addLine(to: CGPoint(x: 40, y: 30))
                path.addLine(to: CGPoint(x: 40 - size, y: 30))
            case 3: // Bottom-left
                path.move(to: CGPoint(x: -40 + size, y: 30))
                path.addLine(to: CGPoint(x: -40, y: 30))
                path.addLine(to: CGPoint(x: -40, y: 30 - size))
            default:
                break
            }
        }
        .stroke(color, style: StrokeStyle(lineWidth: thickness, lineCap: .round))
    }
}

// MARK: - Enhanced Scanner Feature Highlight
struct EnhancedScannerFeatureHighlight: View {
    let feature: ScannerOnboardingFeature
    let accentColor: Color
    let userType: ScannerUserType
    @State private var isPressed = false
    @State private var showingDetail = false
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showingDetail.toggle()
            }
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } label: {
            HStack(spacing: 20) {
                // Enhanced icon with scanner styling
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.15),
                                    accentColor.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: feature.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(accentColor)
                }
                
                // Enhanced content
                VStack(alignment: .leading, spacing: 8) {
                    Text(feature.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(ScannerTheme.adaptiveTextPrimary)
                    
                    Text(feature.getPersonalizedDescription(for: userType))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(ScannerTheme.adaptiveTextSecondary)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Interactive indicator
                Image(systemName: showingDetail ? "chevron.up" : "info.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ScannerTheme.borderMedium)
                    .rotationEffect(.degrees(showingDetail ? 180 : 0))
                    .animation(.easeInOut(duration: 0.3), value: showingDetail)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(ScannerTheme.adaptiveSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(ScannerTheme.borderLight, lineWidth: 1)
                    )
                    .shadow(
                        color: isPressed ? ScannerTheme.shadowMedium : ScannerTheme.shadowLight,
                        radius: isPressed ? 16 : 12,
                        y: isPressed ? 6 : 4
                    )
            )
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture {
            isPressed = true
        }
    }
}

// MARK: - Permission Request View
struct PermissionRequestView: View {
    @Binding var cameraGranted: Bool
    @Binding var notificationGranted: Bool
    let onComplete: () -> Void
    @State private var animateIn = false
    @State private var currentStep = 0
    
    private let permissions = [
        ("camera.fill", "Camera Access", "Required to scan documents and photos"),
        ("bell.fill", "Notifications", "Get alerts for completed scans and reminders")
    ]
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Header
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundColor(ScannerTheme.lightPrimary)
                    .scaleEffect(animateIn ? 1 : 0.5)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateIn)
                
                VStack(spacing: 12) {
                    Text("Permissions Required")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(ScannerTheme.adaptiveTextPrimary)
                    
                    Text("We need these permissions to provide the best scanning experience")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ScannerTheme.adaptiveTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.4), value: animateIn)
            }
            
            // Permission cards
            VStack(spacing: 16) {
                ForEach(Array(permissions.enumerated()), id: \.offset) { index, permission in
                    PermissionCard(
                        icon: permission.0,
                        title: permission.1,
                        description: permission.2,
                        isGranted: index == 0 ? cameraGranted : notificationGranted,
                        onRequest: {
                            requestPermission(at: index)
                        }
                    )
                    .opacity(animateIn ? 1 : 0)
                    .offset(x: animateIn ? 0 : -30)
                    .animation(.easeOut(duration: 0.6).delay(0.6 + Double(index) * 0.1), value: animateIn)
                }
            }
            .padding(.horizontal, 20)
            
            // Complete button
            Button {
                onComplete()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(allPermissionsGranted ? "Start Scanning" : "Continue Anyway")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    ScannerTheme.lightPrimary,
                                    ScannerTheme.lightPrimary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: ScannerTheme.lightPrimary.opacity(0.4),
                            radius: 16,
                            y: 8
                        )
                )
            }
            .opacity(animateIn ? 1 : 0)
            .scaleEffect(animateIn ? 1 : 0.95)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0), value: animateIn)
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
    }
    
    private var allPermissionsGranted: Bool {
        cameraGranted && notificationGranted
    }
    
    private func requestPermission(at index: Int) {
        if index == 0 {
            requestCameraPermission()
        } else {
            requestNotificationPermission()
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraGranted = granted
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                notificationGranted = granted
            }
        }
    }
}

// MARK: - Permission Card
struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let onRequest: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isGranted ? ScannerTheme.scanExcellent : ScannerTheme.lightPrimary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isGranted ? ScannerTheme.scanExcellent.opacity(0.1) : ScannerTheme.lightPrimary.opacity(0.1))
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ScannerTheme.adaptiveTextPrimary)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ScannerTheme.adaptiveTextSecondary)
            }
            
            Spacer()
            
            // Action button
            Button(action: onRequest) {
                if isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(ScannerTheme.scanExcellent)
                } else {
                    Text("Allow")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ScannerTheme.lightPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(ScannerTheme.lightPrimary.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(ScannerTheme.lightPrimary, lineWidth: 1)
                                )
                        )
                }
            }
            .disabled(isGranted)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ScannerTheme.adaptiveSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isGranted ? ScannerTheme.scanExcellent : ScannerTheme.borderLight, lineWidth: 1)
                )
        )
    }
}

// MARK: - Enhanced Models for Scanner App
enum ScannerUserType: Int, CaseIterable {
    case personal = 0
    case business = 1
    case professional = 2
    
    var title: String {
        switch self {
        case .personal: return "Personal Use"
        case .business: return "Small Business"
        case .professional: return "Professional"
        }
    }
    
    var description: String {
        switch self {
        case .personal: return "Scan receipts, documents, and photos for personal organization"
        case .business: return "Manage invoices, contracts, and business documents"
        case .professional: return "Handle client documents, legal papers, and presentations"
        }
    }
    
    var iconName: String {
        switch self {
        case .personal: return "house.fill"
        case .business: return "building.2.fill"
        case .professional: return "briefcase.fill"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .personal: return ScannerTheme.lightPrimary
        case .business: return ScannerTheme.lightAccentSecondary
        case .professional: return ScannerTheme.premium
        }
    }
}

// MARK: - Scanner Onboarding Page Model
struct ScannerOnboardingPage {
    let iconName: String
    let title: String
    let subtitle: String?
    let description: String
    let accentColor: Color
    let features: [ScannerOnboardingFeature]
    
    func getPersonalizedTitle(for userType: ScannerUserType) -> String {
        switch (self.title.contains("Scan"), userType) {
        case (true, .personal):
            return "Scan Anything"
        case (true, .business):
            return "Business Document Scanner"
        case (true, .professional):
            return "Professional Document Management"
        default:
            return title
        }
    }
    
    func getPersonalizedDescription(for userType: ScannerUserType) -> String {
        switch userType {
        case .personal:
            return description.replacingOccurrences(of: "documents", with: "personal documents and photos")
        case .business:
            return description.replacingOccurrences(of: "documents", with: "business documents and invoices")
        case .professional:
            return description.replacingOccurrences(of: "documents", with: "professional documents and contracts")
        }
    }
    
    static func pagesForUserType(_ userType: ScannerUserType) -> [ScannerOnboardingPage] {
        let basePages = [
            // Page 1: Document Scanning
            ScannerOnboardingPage(
                iconName: "doc.viewfinder.fill",
                title: "Scan Any Document",
                subtitle: "Instantly",
                description: "Transform any document into a high-quality PDF with our advanced scanning technology powered by AI.",
                accentColor: userType.primaryColor,
                features: [
                    ScannerOnboardingFeature(
                        icon: "camera.viewfinder",
                        title: "Smart Edge Detection",
                        description: "Automatically detects document boundaries",
                        userTypeDescriptions: [
                            .personal: "Perfect scans of receipts and letters",
                            .business: "Professional invoice and contract scanning",
                            .professional: "Legal document and presentation scanning"
                        ]
                    ),
                    ScannerOnboardingFeature(
                        icon: "wand.and.rays",
                        title: "AI Enhancement",
                        description: "Enhance image quality and remove shadows",
                        userTypeDescriptions: [
                            .personal: "Crystal clear scans of family documents",
                            .business: "Professional quality business documents",
                            .professional: "Client-ready document presentation"
                        ]
                    )
                ]
            ),
            
            // Page 2: OCR and Text Recognition
            ScannerOnboardingPage(
                iconName: "text.viewfinder",
                title: "Extract Text with",
                subtitle: "OCR Technology",
                description: "Convert any scanned document into searchable, editable text with industry-leading OCR accuracy.",
                accentColor: ScannerTheme.ocrActive,
                features: [
                    ScannerOnboardingFeature(
                        icon: "textformat.abc",
                        title: "Advanced OCR",
                        description: "99%+ accuracy text recognition in 100+ languages",
                        userTypeDescriptions: [
                            .personal: "Extract text from bills and documents",
                            .business: "Digitize invoices and customer information",
                            .professional: "Extract data from legal documents"
                        ]
                    ),
                    ScannerOnboardingFeature(
                        icon: "magnifyingglass.circle.fill",
                        title: "Smart Search",
                        description: "Find any document by searching its content",
                        userTypeDescriptions: [
                            .personal: "Quickly find specific receipts or documents",
                            .business: "Locate client documents instantly",
                            .professional: "Advanced document retrieval system"
                        ]
                    )
                ]
            )
        ]
        
        // Add user-specific third page
        let thirdPage: ScannerOnboardingPage
        switch userType {
        case .personal:
            thirdPage = ScannerOnboardingPage(
                iconName: "folder.fill.badge.plus",
                title: "Organize Your",
                subtitle: "Digital Life",
                description: "Keep all your important documents organized, backed up, and accessible from anywhere.",
                accentColor: ScannerTheme.lightSecondary,
                features: [
                    ScannerOnboardingFeature(
                        icon: "folder.badge.gearshape",
                        title: "Smart Organization",
                        description: "Auto-categorize documents by type",
                        userTypeDescriptions: [
                            .personal: "Separate receipts, bills, and personal docs",
                            .business: "Sort by client and document type",
                            .professional: "Professional categorization system"
                        ]
                    ),
                    ScannerOnboardingFeature(
                        icon: "icloud.and.arrow.up",
                        title: "Cloud Backup",
                        description: "Secure cloud storage with sync across devices",
                        userTypeDescriptions: [
                            .personal: "Never lose important documents again",
                            .business: "Team access to business documents",
                            .professional: "Enterprise-grade security and backup"
                        ]
                    )
                ]
            )

        case .business:
            thirdPage = ScannerOnboardingPage(
                iconName: "chart.line.uptrend.xyaxis",
                title: "Streamline Your",
                subtitle: "Business Operations",
                description: "Digitize invoices, contracts, and receipts to boost efficiency and reduce paperwork.",
                accentColor: ScannerTheme.lightAccentSecondary,
                features: [
                    ScannerOnboardingFeature(
                        icon: "dollarsign.square.fill",
                        title: "Expense Tracking",
                        description: "Automatically extract data from receipts",
                        userTypeDescriptions: [
                            .personal: "Track personal expenses easily",
                            .business: "Complete business expense management",
                            .professional: "Client billable expense tracking"
                        ]
                    ),
                    ScannerOnboardingFeature(
                        icon: "person.3.fill",
                        title: "Team Collaboration",
                        description: "Share documents securely with your team",
                        userTypeDescriptions: [
                            .personal: "Share documents with family",
                            .business: "Team document management",
                            .professional: "Client and colleague collaboration"
                        ]
                    )
                ]
            )
            
        case .professional:
            thirdPage = ScannerOnboardingPage(
                iconName: "seal.fill",
                title: "Professional Grade",
                subtitle: "Document Management",
                description: "Enterprise-level features for legal documents, contracts, and client communications.",
                accentColor: ScannerTheme.premium,
                features: [
                    ScannerOnboardingFeature(
                        icon: "checkmark.seal.fill",
                        title: "Digital Signatures",
                        description: "Sign documents electronically with legal validity",
                        userTypeDescriptions: [
                            .personal: "Sign important personal documents",
                            .business: "Business contract signing",
                            .professional: "Legally binding document execution"
                        ]
                    ),
                    ScannerOnboardingFeature(
                        icon: "lock.shield.fill",
                        title: "Advanced Security",
                        description: "Bank-level encryption and compliance features",
                        userTypeDescriptions: [
                            .personal: "Keep personal documents secure",
                            .business: "Business data protection",
                            .professional: "Client confidentiality and compliance"
                        ]
                    )
                ]
            )
        }
        
        return basePages + [thirdPage]
    }
}

struct ScannerOnboardingFeature {
    let icon: String
    let title: String
    let description: String
    let userTypeDescriptions: [ScannerUserType: String]?
    
    init(icon: String, title: String, description: String, userTypeDescriptions: [ScannerUserType: String]? = nil) {
        self.icon = icon
        self.title = title
        self.description = description
        self.userTypeDescriptions = userTypeDescriptions
    }
    
    func getPersonalizedDescription(for userType: ScannerUserType) -> String {
        return userTypeDescriptions?[userType] ?? description
    }
}

// MARK: - Scanner Paywall View
struct ScannerPaywallView: View {
    let userType: ScannerUserType
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: ScannerPlan = .monthly
    @State private var animateIn = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 20) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(ScannerTheme.premium)
                            .scaleEffect(animateIn ? 1 : 0.5)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateIn)
                        
                        VStack(spacing: 12) {
                            Text("Unlock Scanner Pro")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(ScannerTheme.adaptiveTextPrimary)
                            
                            Text("Get unlimited scans and premium features")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(ScannerTheme.adaptiveTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.4), value: animateIn)
                    }
                    .padding(.top, 20)
                    
                    // Premium features
                    VStack(spacing: 16) {
                        ForEach(Array(getPremiumFeatures().enumerated()), id: \.offset) { index, feature in
                            PremiumFeatureRow(
                                icon: feature.0,
                                title: feature.1,
                                description: feature.2
                            )
                            .opacity(animateIn ? 1 : 0)
                            .offset(x: animateIn ? 0 : -30)
                            .animation(.easeOut(duration: 0.6).delay(0.6 + Double(index) * 0.1), value: animateIn)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Pricing plans
                    VStack(spacing: 16) {
                        ForEach(ScannerPlan.allCases, id: \.self) { plan in
                            PricingPlanCard(
                                plan: plan,
                                isSelected: selectedPlan == plan,
                                onSelect: { selectedPlan = plan }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Subscribe button with high contrast
                    Button {
                        // Handle subscription
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Start Free Trial")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(ScannerTheme.premiumGradient)
                                .overlay(
                                    // Add inner highlight for better visibility
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.4),
                                                    Color.clear
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(
                                    color: ScannerTheme.premium.opacity(0.4),
                                    radius: 16,
                                    y: 8
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                    .opacity(animateIn ? 1 : 0)
                    .scaleEffect(animateIn ? 1 : 0.95)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.2), value: animateIn)
                    
                    // Terms
                    Text("7-day free trial, then \(selectedPlan.price)/\(selectedPlan.period). Cancel anytime.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ScannerTheme.adaptiveTextTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(animateIn ? 0.8 : 0)
                        .animation(.easeOut(duration: 0.6).delay(1.4), value: animateIn)
                }
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
    }
    
    private func getPremiumFeatures() -> [(String, String, String)] {
        switch userType {
        case .personal:
            return [
                ("infinity", "Unlimited Scans", "Scan as many documents as you need"),
                ("icloud.and.arrow.up", "Cloud Storage", "100GB secure cloud storage"),
                ("textformat.abc", "Advanced OCR", "Extract text from any document"),
                ("folder.badge.gearshape", "Smart Organization", "AI-powered document categorization")
            ]
        case .business:
            return [
                ("dollarsign.square", "Expense Tracking", "Automatic receipt data extraction"),
                ("person.3.fill", "Team Collaboration", "Share documents with your team"),
                ("chart.bar.fill", "Business Analytics", "Track document usage and trends"),
                ("building.2.fill", "Multi-location", "Sync across all business locations")
            ]
        case .professional:
            return [
                ("checkmark.seal.fill", "Digital Signatures", "Legally binding e-signatures"),
                ("lock.shield.fill", "Enterprise Security", "Bank-level encryption and compliance"),
                ("briefcase.fill", "Client Management", "Organize documents by client"),
                ("clock.arrow.circlepath", "Version Control", "Track document changes and history")
            ]
        }
    }
}

// MARK: - Premium Feature Row
struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(ScannerTheme.premium)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(ScannerTheme.premium.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ScannerTheme.adaptiveTextPrimary)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ScannerTheme.adaptiveTextSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ScannerTheme.adaptiveSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ScannerTheme.borderLight, lineWidth: 1)
                )
        )
    }
}

// MARK: - Pricing Plan Models
enum ScannerPlan: CaseIterable {
    case monthly
    case yearly
    
    var title: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
    
    var price: String {
        switch self {
        case .monthly: return "$9.99"
        case .yearly: return "$59.99"
        }
    }
    
    var period: String {
        switch self {
        case .monthly: return "month"
        case .yearly: return "year"
        }
    }
    
    var savings: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "Save 50%"
        }
    }
    
    var monthlyEquivalent: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "$4.99/month"
        }
    }
}

// MARK: - Pricing Plan Card
struct PricingPlanCard: View {
    let plan: ScannerPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isSelected ? .white : ScannerTheme.adaptiveTextPrimary)
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(isSelected ? .white : ScannerTheme.premium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? .white.opacity(0.2) : ScannerTheme.premium.opacity(0.1))
                                )
                        }
                    }
                    
                    if let monthlyEquivalent = plan.monthlyEquivalent {
                        Text(monthlyEquivalent)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isSelected ? .white.opacity(0.8) : ScannerTheme.adaptiveTextSecondary)
                    }
                }
                
                Spacer()
                
                Text(plan.price)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isSelected ? .white : ScannerTheme.adaptiveTextPrimary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? ScannerTheme.premium : ScannerTheme.adaptiveSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? ScannerTheme.premium : ScannerTheme.borderLight,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? ScannerTheme.premium.opacity(0.3) : ScannerTheme.shadowLight,
                        radius: isSelected ? 12 : 6,
                        y: isSelected ? 6 : 3
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Safe Array Extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
