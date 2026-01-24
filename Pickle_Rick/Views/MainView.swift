//
//  ContentView.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/23/26.
//

import SwiftUI

struct MainView: View {
    @StateObject var viewModel = MainViewViewModel()
    @StateObject var bleManager = BLEManager()
    
    var body: some View {
        if viewModel.isCheckingAuth {
            // Loading/Splash screen
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
        } else if viewModel.isSignedIn, !viewModel.currentUserId.isEmpty {
            accountView
                .environmentObject(bleManager)
        } else {
            LoginView()
        }
    }
    
    @ViewBuilder
    var accountView: some View {
        TabView {
            BluetoothView()
                .tabItem {
                    Label("Bluetooth", image: "bluetooth")
                }
            
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.circle")
                }
            
            LeaderboardView()
                .tabItem {
                    Label("Leaderboard", systemImage: "trophy.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
}

#Preview {
    MainView()
}
