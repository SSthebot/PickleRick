//
//  LeaderboardView.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/24/26.
//

import SwiftUI

enum LeaderboardCategory: String, CaseIterable {
    case averageRPM = "Avg RPM"
    case averageSpeed = "Avg Speed"
    case totalPlayTime = "Play Time"
    
    var icon: String {
        switch self {
        case .averageRPM:
            return "arrow.triangle.2.circlepath"
        case .averageSpeed:
            return "speedometer"
        case .totalPlayTime:
            return "clock.fill"
        }
    }
}

struct LeaderboardView: View {
    @State private var viewModel = LeaderboardViewModel()
    @State private var selectedCategory: LeaderboardCategory = .averageRPM
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Picker
                categoryPicker
                
                // Leaderboard Content
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else {
                    leaderboardList
                }
            }
            .navigationTitle("Leaderboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.refreshLeaderboard(category: selectedCategory)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await viewModel.loadLeaderboard(category: selectedCategory)
            }
            .onChange(of: selectedCategory) { oldValue, newValue in
                Task {
                    await viewModel.loadLeaderboard(category: newValue)
                }
            }
        }
    }
    
    private var categoryPicker: some View {
        Picker("Category", selection: $selectedCategory) {
            ForEach(LeaderboardCategory.allCases, id: \.self) { category in
                Text(category.rawValue).tag(category)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading Leaderboard...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Error Loading Leaderboard")
                .font(.headline)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                Task {
                    await viewModel.refreshLeaderboard(category: selectedCategory)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var leaderboardList: some View {
        ScrollView {
            VStack(spacing: 0) {
                if viewModel.entries.isEmpty {
                    emptyStateView
                } else {
                    ForEach(viewModel.entries) { entry in
                        LeaderboardRow(
                            entry: entry,
                            category: selectedCategory,
                            isCurrentUser: entry.id == viewModel.currentUserId
                        )
                        
                        if entry.id != viewModel.entries.last?.id {
                            Divider()
                                .padding(.leading, 80)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Data Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Be the first to start playing and climb the leaderboard!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 100)
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let category: LeaderboardCategory
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                if entry.rank <= 3 {
                    Image(systemName: medalIcon)
                        .font(.system(size: 24))
                        .foregroundColor(rankColor)
                } else {
                    Text("\(entry.rank)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(rankColor)
                }
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.name)
                        .font(.headline)
                        .fontWeight(isCurrentUser ? .bold : .regular)
                    
                    if isCurrentUser {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                Text(formatValue(entry.value, for: category))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Category Icon
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundColor(.blue.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(isCurrentUser ? Color.blue.opacity(0.1) : Color.clear)
    }
    
    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    private var medalIcon: String {
        switch entry.rank {
        case 1: return "medal.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return ""
        }
    }
    
    private func formatValue(_ value: Float, for category: LeaderboardCategory) -> String {
        switch category {
        case .averageRPM:
            return String(format: "%.0f RPM", value)
        case .averageSpeed:
            return String(format: "%.1f mph", value)
        case .totalPlayTime:
            // Convert seconds to minutes
            let minutes = Int(value / 60)
            return "\(minutes) min"
        }
    }
}

#Preview {
    LeaderboardView()
}
