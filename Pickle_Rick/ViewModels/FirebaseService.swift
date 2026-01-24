//
//  FirebaseService.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/24/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    @Published var shots: [ShotWithId] = []
    
    private var listener: ListenerRegistration?
    
    private init() {}
    
    func addShot(_ shot: ShotItem) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirebaseServiceError.notAuthenticated
        }
        
        let shotData: [String: Any] = [
            "shot_type": shot.shot_type,
            "speed": shot.speed,
            "spin": shot.spin,
            "spin_type": shot.spin_type,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("users")
            .document(userId)
            .collection("shots")
            .addDocument(data: shotData)
        
        print("Shot saved successfully")
        
        // Update user stats after adding a shot
        try await updateUserStats()
    }
    
    func listenToShots() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Cannot listen to shots - user not authenticated")
            return
        }
        
        listener = db.collection("users")
            .document(userId)
            .collection("shots")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening to shots: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                self.shots = documents.compactMap { doc -> ShotWithId? in
                    let data = doc.data()
                    
                    guard let shotType = data["shot_type"] as? String,
                          let spinType = data["spin_type"] as? String else {
                        return nil
                    }
                    
                    // Handle both Float and Double from Firebase
                    let speed: Float
                    if let speedDouble = data["speed"] as? Double {
                        speed = Float(speedDouble)
                    } else if let speedFloat = data["speed"] as? Float {
                        speed = speedFloat
                    } else {
                        return nil
                    }
                    
                    let spin: Float
                    if let spinDouble = data["spin"] as? Double {
                        spin = Float(spinDouble)
                    } else if let spinFloat = data["spin"] as? Float {
                        spin = spinFloat
                    } else {
                        return nil
                    }
                    
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    
                    let shot = ShotItem(
                        shot_type: shotType,
                        speed: speed,
                        spin: spin,
                        spin_type: spinType
                    )
                    
                    return ShotWithId(id: doc.documentID, shot: shot, timestamp: timestamp)
                }
                
                print("Updated shots list: \(self.shots.count) shots")
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func deleteShot(id: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirebaseServiceError.notAuthenticated
        }
        
        try await db.collection("users")
            .document(userId)
            .collection("shots")
            .document(id)
            .delete()
    }
    
    func clearAllShots() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirebaseServiceError.notAuthenticated
        }
        
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("shots")
            .getDocuments()
        
        print("Deleting \(snapshot.documents.count) shots from Firebase")
        
        for document in snapshot.documents {
            try await document.reference.delete()
            print("Deleted shot: \(document.documentID)")
        }
        
        print("All shots cleared")
    }
    
    // MARK: - Session Tracking
    
    func saveSession(duration: TimeInterval) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirebaseServiceError.notAuthenticated
        }
        
        let statsRef = db.collection("users").document(userId)
        
        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            let statsDocument: DocumentSnapshot
            do {
                try statsDocument = transaction.getDocument(statsRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            let currentStats = statsDocument.data() ?? [:]
            let currentPlayTime = currentStats["totalPlayTime"] as? TimeInterval ?? 0
            
            let updatedData: [String: Any] = [
                "totalPlayTime": currentPlayTime + duration
            ]
            
            transaction.setData(updatedData, forDocument: statsRef, merge: true)
            return nil
        }
    }
    
    func fetchUserStats() async throws -> UserStats {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirebaseServiceError.notAuthenticated
        }
        
        let document = try await db.collection("users").document(userId).getDocument()
        let data = document.data() ?? [:]
        
        let totalPlayTime = data["totalPlayTime"] as? TimeInterval ?? 0
        
        // Fetch average RPM and speed
        let averageRPM = (data["averageRPM"] as? NSNumber)?.floatValue ?? 0
        let averageSpeed = (data["averageSpeed"] as? NSNumber)?.floatValue ?? 0
        let totalShots = data["totalShots"] as? Int ?? 0
        
        return UserStats(
            totalPlayTime: totalPlayTime,
            averageRPM: averageRPM,
            averageSpeed: averageSpeed,
            totalShots: totalShots
        )
    }
    
    // MARK: - Leaderboard
    
    func fetchLeaderboard(category: LeaderboardCategory) async throws -> [LeaderboardEntry] {
        // Fetch all users with their stats
        let usersSnapshot = try await db.collection("users").getDocuments()
        
        var leaderboardData: [(userId: String, name: String, value: Float)] = []
        
        for userDoc in usersSnapshot.documents {
            let userData = userDoc.data()
            
            // Get user name with multiple fallback options
            let name: String
            if let userName = userData["name"] as? String, !userName.isEmpty {
                name = userName
            } else if let displayName = userData["displayName"] as? String, !displayName.isEmpty {
                name = displayName
            } else if let email = userData["email"] as? String {
                // Use first part of email as fallback
                name = email.components(separatedBy: "@").first ?? "Unknown User"
            } else {
                name = "Unknown User"
            }
            
            let value: Float
            switch category {
            case .averageRPM:
                // Handle multiple numeric types
                if let rpm = userData["averageRPM"] as? Float {
                    value = rpm
                } else if let rpm = userData["averageRPM"] as? Double {
                    value = Float(rpm)
                } else if let rpm = userData["averageRPM"] as? Int {
                    value = Float(rpm)
                } else {
                    value = 0
                }
                
            case .averageSpeed:
                // Handle multiple numeric types
                if let speed = userData["averageSpeed"] as? Float {
                    value = speed
                } else if let speed = userData["averageSpeed"] as? Double {
                    value = Float(speed)
                } else if let speed = userData["averageSpeed"] as? Int {
                    value = Float(speed)
                } else {
                    value = 0
                }
                
            case .totalPlayTime:
                // Handle multiple numeric types for totalPlayTime (stored in seconds)
                if let playTime = userData["totalPlayTime"] as? TimeInterval {
                    value = Float(playTime)
                } else if let playTime = userData["totalPlayTime"] as? Double {
                    value = Float(playTime)
                } else if let playTime = userData["totalPlayTime"] as? Float {
                    value = playTime
                } else if let playTime = userData["totalPlayTime"] as? Int {
                    value = Float(playTime)
                } else {
                    value = 0
                }
            }
            
            // Only include users with non-zero values
            if value > 0 {
                leaderboardData.append((userId: userDoc.documentID, name: name, value: value))
            }
        }
        
        // Sort by value descending
        leaderboardData.sort { $0.value > $1.value }
        
        // Convert to LeaderboardEntry with ranks
        var entries: [LeaderboardEntry] = []
        for (index, data) in leaderboardData.enumerated() {
            let entry = LeaderboardEntry(
                id: data.userId,
                name: data.name,
                value: data.value,
                rank: index + 1
            )
            entries.append(entry)
        }
        
        return entries
    }
    
    // Update user stats when shots are recorded
    func updateUserStats() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirebaseServiceError.notAuthenticated
        }
        
        // Fetch all shots for this user
        let shotsSnapshot = try await db.collection("users")
            .document(userId)
            .collection("shots")
            .getDocuments()
        
        guard !shotsSnapshot.documents.isEmpty else {
            return
        }
        
        var totalRPM: Float = 0
        var totalSpeed: Float = 0
        let shotCount = shotsSnapshot.documents.count
        
        for doc in shotsSnapshot.documents {
            let data = doc.data()
            
            if let spinDouble = data["spin"] as? Double {
                totalRPM += Float(spinDouble)
            } else if let spinFloat = data["spin"] as? Float {
                totalRPM += spinFloat
            }
            
            if let speedDouble = data["speed"] as? Double {
                totalSpeed += Float(speedDouble)
            } else if let speedFloat = data["speed"] as? Float {
                totalSpeed += speedFloat
            }
        }
        
        let averageRPM = totalRPM / Float(shotCount)
        let averageSpeed = totalSpeed / Float(shotCount)
        
        // Update user document with stats
        let statsData: [String: Any] = [
            "averageRPM": averageRPM,
            "averageSpeed": averageSpeed,
            "totalShots": shotCount
        ]
        
        try await db.collection("users")
            .document(userId)
            .setData(statsData, merge: true)
    }
}

struct ShotWithId: Identifiable {
    let id: String
    let shot: ShotItem
    let timestamp: Date
}

enum FirebaseServiceError: Error {
    case notAuthenticated
    case invalidData
    
    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .invalidData:
            return "Invalid data format"
        }
    }
}
