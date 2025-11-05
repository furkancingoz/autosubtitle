//
//  MainTabView.swift
//  AutoSubtitle
//
//  Main tab bar navigation
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(1)

            CreditsView()
                .tabItem {
                    Label("Credits", systemImage: "creditcard.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(.purple)
    }
}

#Preview {
    MainTabView()
        .environmentObject(FirebaseAuthManager.shared)
        .environmentObject(UserManager.shared)
        .environmentObject(CreditManager.shared)
        .environmentObject(RevenueCatManager.shared)
        .environmentObject(VideoProcessor.shared)
}
