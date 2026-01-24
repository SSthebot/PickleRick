//
//  ShotDetailView.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/24/26.
//

import SwiftUI

struct ShotDetailView: View {
    let shotWithId: ShotWithId
    @Environment(\.dismiss) private var dismiss
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: shotWithId.timestamp)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with icon
                VStack(spacing: 12) {
                    Image(systemName: "tennisball.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text(shotWithId.shot.shot_type)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Main metrics
                VStack(spacing: 16) {
                    MetricCard(
                        title: "Speed",
                        value: String(format: "%.1f", shotWithId.shot.speed),
                        unit: "mph",
                        icon: "speedometer",
                        color: .blue
                    )
                    
                    MetricCard(
                        title: "Spin",
                        value: String(format: "%.0f", shotWithId.shot.spin),
                        unit: "rpm",
                        icon: "tornado",
                        color: .orange
                    )
                    
                    MetricCard(
                        title: "Spin Type",
                        value: shotWithId.shot.spin_type,
                        unit: nil,
                        icon: "arrow.triangle.2.circlepath",
                        color: spinTypeColor
                    )
                }
                .padding(.horizontal)
                
                // Placeholder for 2D mapping
                VStack(spacing: 12) {
                    Text("Shot Visualization")
                        .font(.headline)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 300)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "map")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            Text("2D Mapping Coming Soon")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Shot trajectory visualization will be displayed here")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Shot Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var spinTypeColor: Color {
        switch shotWithId.shot.spin_type.lowercased() {
        case "topspin":
            return .green
        case "backspin", "slice":
            return .blue
        case "flat":
            return .orange
        default:
            return .gray
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String?
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let unit = unit {
                        Text(unit)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        ShotDetailView(shotWithId: ShotWithId(
            id: "preview",
            shot: ShotItem(
                shot_type: "Forehand",
                speed: 65.5,
                spin: 2450,
                spin_type: "Topspin"
            ),
            timestamp: Date()
        ))
    }
}
