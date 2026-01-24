//
//  User.swift
//  Pickle_Rick
//
//  Created by Shyaam Shanmugam on 1/23/26.
//

import Foundation


struct User: Codable {
    let id : String
    let name : String
    let email : String
    let joined : TimeInterval
}
struct UserStats: Codable {
    var totalPlayTime: TimeInterval  // Total seconds connected
    var averageRPM: Float
    var averageSpeed: Float
    var totalShots: Int
    
    init() {
        self.totalPlayTime = 0
        self.averageRPM = 0
        self.averageSpeed = 0
        self.totalShots = 0
    }
    
    init(totalPlayTime: TimeInterval, averageRPM: Float = 0, averageSpeed: Float = 0, totalShots: Int = 0) {
        self.totalPlayTime = totalPlayTime
        self.averageRPM = averageRPM
        self.averageSpeed = averageSpeed
        self.totalShots = totalShots
    }
}

struct LeaderboardEntry: Identifiable {
    let id: String  // User ID
    let name: String
    let value: Float
    let rank: Int
}

