//
//  DashboardViewViewModel.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/24/26.
//

import Foundation
import Combine

class DashboardViewViewModel: ObservableObject {
    @Published var shots: [ShotWithId] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to shots updates from Firebase service
        firebaseService.$shots
            .receive(on: DispatchQueue.main)
            .assign(to: &$shots)
        
        // Start listening to Firebase
        firebaseService.listenToShots()
    }
    
    func deleteShot(id: String) {
        Task {
            do {
                try await firebaseService.deleteShot(id: id)
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete shot: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func clearAllShots() {
        Task {
            isLoading = true
            do {
                try await firebaseService.clearAllShots()
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to clear shots: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    func refreshShots() {
        // Re-subscribe to get fresh data
        firebaseService.stopListening()
        firebaseService.listenToShots()
    }
    
    deinit {
        firebaseService.stopListening()
    }
}
