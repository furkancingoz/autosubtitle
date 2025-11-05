//
//  OnboardingView.swift
//  AutoSubtitle
//
//  Onboarding flow for first-time users
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @State private var currentPage = 0
    @State private var isSigningIn = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        icon: "wand.and.stars",
                        title: "Auto Subtitle",
                        description: "Automatically generate beautiful subtitles for your videos with AI"
                    )
                    .tag(0)

                    OnboardingPage(
                        icon: "bolt.fill",
                        title: "Fast & Easy",
                        description: "Upload your video and get subtitled results in minutes"
                    )
                    .tag(1)

                    OnboardingPage(
                        icon: "paintbrush.fill",
                        title: "Customizable",
                        description: "Choose from multiple fonts, colors, and styles"
                    )
                    .tag(2)

                    OnboardingPage(
                        icon: "sparkles",
                        title: "Get Started",
                        description: "Start with 5 free credits. No credit card required!"
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button(action: signIn) {
                    if isSigningIn {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(currentPage == 3 ? "Get Started" : "Skip")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.purple)
                .cornerRadius(16)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .disabled(isSigningIn)
            }
        }
    }

    private func signIn() {
        isSigningIn = true
        Task {
            do {
                try await authManager.signInAnonymously()
            } catch {
                print("❌ Sign-in failed: \(error.localizedDescription)")
            }
            isSigningIn = false
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 100))
                .foregroundColor(.white)

            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(FirebaseAuthManager.shared)
}
