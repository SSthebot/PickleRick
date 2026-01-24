//
//  LeaderboardViewModel.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/24/26.
//

import Foundation
import FirebaseAuth

@Observable
class LeaderboardViewModel {
    var entries: [LeaderboardEntry] = []
    var isLoading = false
    var errorMessage: String?
    var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    
    @MainActor
    func loadLeaderboard(category: LeaderboardCategory) async {
        isLoading = true
        errorMessage = nil
        
        do {
            entries = try await FirebaseService.shared.fetchLeaderboard(category: category)
            isLoading = false
        } catch {
            // Provide more detailed error information
            if let firestoreError = error as NSError? {
                print("Leaderboard Error Code: \(firestoreError.code)")
                print("Leaderboard Error Domain: \(firestoreError.domain)")
                print("Leaderboard Error Description: \(firestoreError.localizedDescription)")
                errorMessage = firestoreError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    @MainActor
    func refreshLeaderboard(category: LeaderboardCategory) async {
        await loadLeaderboard(category: category)
    }
}
