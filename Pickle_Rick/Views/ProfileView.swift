//
//  ProfileView.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/23/26.
//

import SwiftUI

struct ProfileView: View {
    @State var viewModel = ProfileViewViewModel()
    @EnvironmentObject var bleManager: BLEManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let user = viewModel.user {
                        // Avatar
                        Image(systemName: "person.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.blue)
                            .frame(width: 125, height: 125)
                            .padding(.top, 40)
                        
                        // User Information Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Display:")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(user.name)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Email:")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(user.email)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Member Since:")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(Date(timeIntervalSince1970: user.joined).formatted(date: .abbreviated, time: .omitted))
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Statistics Card
                        if let stats = viewModel.userStats {
                            VStack(spacing: 16) {
                                Text("Playing Statistics")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Total Play Time
                                HStack {
                                    Text("Total Play Time:")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatPlayTime(stats.totalPlayTime))
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                
                                Divider()
                                
                                // Average Stats
                                HStack(spacing: 12) {
                                    VStack {
                                        Text("Avg RPM")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(String(format: "%.0f", stats.averageRPM))
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    Divider()
                                        .frame(height: 40)
                                    
                                    VStack {
                                        Text("Avg Speed")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(String(format: "%.1f mph", stats.averageSpeed))
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    Divider()
                                        .frame(height: 40)
                                    
                                    VStack {
                                        Text("Total Shots")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("\(stats.totalShots)")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                        
                        // Log Out Button
                        Button(action: {
                            viewModel.logOut()
                        }) {
                            Text("Log Out")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                        
                    } else {
                        VStack(spacing: 20) {
                            if let errorMessage = viewModel.errorMessage {
                                // Show error state
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.orange)
                                Text("Error Loading Profile")
                                    .font(.headline)
                                Text(errorMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button("Retry") {
                                    viewModel.fetchUser()
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.top)
                            } else {
                                // Show loading state
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Loading Profile...")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxHeight: .infinity)
                        .padding(.top, 100)
                    }
                }
            }
            .navigationTitle("Profile")
            .task {
                // Fetch user data when view appears
                viewModel.fetchUser()
            }
        }
    }
    
    // Helper function to format play time
    private func formatPlayTime(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
}

#Preview {
    ProfileView()
}
