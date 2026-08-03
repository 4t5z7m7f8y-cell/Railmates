//
//  Journal.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import Foundation
import FirebaseFirestore

struct Journal: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var startDate: Date
    var endDate: Date?
    var createdBy: String  // User ID
    var createdAt: Date = Date()
    var coverPhotoURL: String?
    var isPublic: Bool = true
    var countries: [String] = []  // List of countries visited
    
    var duration: String {
        let calendar = Calendar.current
        if let end = endDate {
            let components = calendar.dateComponents([.day], from: startDate, to: end)
            let days = components.day ?? 0
            return "\(days) day\(days == 1 ? "" : "s")"
        }
        return "Ongoing"
    }
    
    var isOngoing: Bool {
        if let end = endDate {
            return end > Date()
        }
        return true
    }
}

struct JournalEntry: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var journalId: String
    var city: String
    var country: String
    var date: Date
    var title: String
    var notes: String
    var photoURLs: [String] = []
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date = Date()
    
    // Optional references
    var visitedTipIds: [String] = []  // Tips the user visited
    var attendedHappeningIds: [String] = []  // Events attended
}
