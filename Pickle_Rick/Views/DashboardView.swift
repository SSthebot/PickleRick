//
//  DashboardView.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/23/26.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewViewModel()
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.shots.isEmpty {
                    emptyStateView
                } else {
                    shotsList
                }
                
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: viewModel.refreshShots) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        if !viewModel.shots.isEmpty {
                            Button(role: .destructive, action: {
                                showingClearAlert = true
                            }) {
                                Label("Clear All Shots", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Clear All Shots", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    viewModel.clearAllShots()
                }
            } message: {
                Text("Are you sure you want to delete all shots? This action cannot be undone.")
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tennisball")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("No Shots Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Connect your Bluetooth device and start recording shots to see them here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var shotsList: some View {
        VStack(spacing: 0) {
            // Summary statistics
            statsHeader
                .padding()
            
            // List of shots
            List {
                ForEach(viewModel.shots) { shotWithId in
                    NavigationLink(destination: ShotDetailView(shotWithId: shotWithId)) {
                        ShotCard(shotWithId: shotWithId)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteShot(id: shotWithId.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }
    
    private var statsHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Total Shots")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.shots.count)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            if !viewModel.shots.isEmpty {
                HStack(spacing: 12) {
                    StatCard(
                        title: "Avg Speed",
                        value: "\(averageSpeed)",
                        unit: "mph",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Avg Spin",
                        value: "\(averageSpin)",
                        unit: "rpm",
                        color: .orange
                    )
                }
            }
        }
    }
    
    private var averageSpeed: String {
        guard !viewModel.shots.isEmpty else { return "0" }
        let total = viewModel.shots.reduce(Float(0)) { $0 + $1.shot.speed }
        let avg = total / Float(viewModel.shots.count)
        return String(format: "%.1f", avg)
    }
    
    private var averageSpin: String {
        guard !viewModel.shots.isEmpty else { return "0" }
        let total = viewModel.shots.reduce(Float(0)) { $0 + $1.shot.spin }
        let avg = total / Float(viewModel.shots.count)
        return String(format: "%.0f", avg)
    }
}

struct ShotCard: View {
    let shotWithId: ShotWithId
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: shotWithId.timestamp, relativeTo: Date())
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(shotWithId.shot.shot_type)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "tennisball.fill")
                .font(.title2)
                .foregroundColor(.green)
        }
        .padding(.vertical, 8)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    DashboardView()
}
