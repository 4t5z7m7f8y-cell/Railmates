//
//  Happening.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import Foundation
import FirebaseFirestore

struct Happening: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var city: String
    var locationName: String?
    var latitude: Double
    var longitude: Double
    var dateTime: Date
    var createdBy: String  // User ID
    var createdAt: Date = Date()
    var attendeeIds: [String] = []
    var maxAttendees: Int?
    var category: String  // e.g. "Meetup", "Party", "Day Trip", "Pub Crawl"
    
    var isFull: Bool {
        guard let max = maxAttendees else { return false }
        return attendeeIds.count >= max
    }
    
    var isPast: Bool {
        dateTime < Date()
    }
}
