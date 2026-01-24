//
//  ProfileViewViewModel.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/23/26.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import Combine

@Observable
class ProfileViewViewModel {
    var user: User? = nil
    var userStats: UserStats? = nil
    var errorMessage: String? = nil
    var isLoading = false
    
    private let firebaseService = FirebaseService.shared
    
    init() {}
    
    func fetchUser() {
        // Prevent multiple simultaneous fetches
        guard !isLoading else {
            print("Already fetching user, skipping...")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        guard let userId = Auth.auth().currentUser?.uid,
              let currentUser = Auth.auth().currentUser else {
            print("No user logged in")
            errorMessage = "No user logged in"
            isLoading = false
            return
        }
        
        print("Fetching user with ID: \(userId)")
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Error fetching user: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                // Check if document exists
                if let data = snapshot?.data() {
                    // Document exists - load it
                    print("User data retrieved: \(data)")
                    
                    self?.user = User(
                        id: data["id"] as? String ?? userId,
                        name: data["name"] as? String ?? "Unknown User",
                        email: data["email"] as? String ?? currentUser.email ?? "",
                        joined: data["joined"] as? TimeInterval ?? Date().timeIntervalSince1970
                    )
                    print("User object created successfully!")
                    print("Name: \(self?.user?.name ?? "nil")")
                    print("Email: \(self?.user?.email ?? "nil")")
                    
                    // Fetch stats
                    self?.fetchStats()
                } else {
                    // Document doesn't exist - this shouldn't happen if user registered properly
                    print("User document not found in Firestore!")
                    print("This means the user was created in Firebase Auth but not in Firestore.")
                    print("Please re-register or contact support.")
                    self?.errorMessage = "User profile not found. Please sign out and register again."
                }
            }
        }
    }
    
    func fetchStats() {
        Task {
            do {
                let stats = try await firebaseService.fetchUserStats()
                await MainActor.run {
                    self.userStats = stats
                }
            } catch {
                print("Error fetching stats: \(error.localizedDescription)")
            }
        }
    }
    
    func logOut() {
        do {
            try Auth.auth().signOut()
            print("User signed out successfully")
            user = nil
            userStats = nil
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
