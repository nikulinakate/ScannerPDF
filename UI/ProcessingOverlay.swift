//
//  ProcessingOverlay.swift
//  Scanner PDF
//
//  Created by user on 07.07.2025.
//


import SwiftUI


// MARK: - Enhanced Processing Overlay
struct ProcessingOverlay: View {
    @State private var isRotating = false
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { } // Prevent dismissal
            
            VStack(spacing: 24) {
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    // Rotating inner element
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                        .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isRotating)
                }
                .scaleEffect(scale)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: scale)
                
                VStack(spacing: 8) {
                    Text("Processing Document...")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("This may take a few moments")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
        .onAppear {
            isRotating = true
            scale = 1.1
        }
    }
}
