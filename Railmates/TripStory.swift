//
//  TripStory.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-03.
//

import Foundation
import FirebaseFirestore

struct TripStory: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    
    // Story metadata
    var title: String
    var story: String  // Main narrative content (can be very long)
    var createdBy: String  // User ID
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isPublic: Bool = true
    
    // Trip information
    var tripStart: Date
    var tripEnd: Date
    var visitedPlaces: [PlaceVisited] = []
    
    // Media
    var photos: [StoryPhoto] = []
    
    // Engagement metrics
    var viewCount: Int = 0
    var likeCount: Int = 0
    var likedBy: [String] = []  // User IDs who liked

    // Optional trip budget in EUR
    var budget: Int? = nil
    
    // Computed properties
    var duration: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: tripStart, to: tripEnd)
        let days = components.day ?? 0
        return "\(days + 1) day\(days == 0 ? "" : "s")"
    }
    
    var routeSummary: String {
        let cities = visitedPlaces.compactMap { $0.city }
        if cities.count <= 3 {
            return cities.joined(separator: " → ")
        } else {
            return "\(cities.prefix(2).joined(separator: " → ")) → ... → \(cities.last ?? "")"
        }
    }
    
    var countriesVisited: [String] {
        Array(Set(visitedPlaces.map { $0.country }))
    }
    
    // For search optimization
    var searchKeywords: [String] {
        var keywords: [String] = []
        
        // Add title words
        keywords.append(contentsOf: title.lowercased().split(separator: " ").map(String.init))
        
        // Add story words (first 500 chars to keep reasonable)
        let storyPreview = String(story.prefix(500)).lowercased()
        keywords.append(contentsOf: storyPreview.split(separator: " ").map(String.init))
        
        // Add all cities and countries
        for place in visitedPlaces {
            if let city = place.city {
                keywords.append(city.lowercased())
            }
            keywords.append(place.country.lowercased())
        }
        
        return Array(Set(keywords))  // Remove duplicates
    }
}

struct PlaceVisited: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var city: String?
    var country: String
    var order: Int  // Order visited (1, 2, 3...)
    
    var displayName: String {
        if let city = city {
            return "\(city), \(country)"
        }
        return country
    }
    
    // For compact display
    var shortName: String {
        city ?? country
    }
}

struct StoryPhoto: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var url: String
    var caption: String?
    var location: String?  // "Paris" or "At the Eiffel Tower"
    var order: Int
    var uploadedAt: Date = Date()
}

// MARK: - Migration Support
// Keep old Journal structure temporarily for data migration
struct LegacyJournal: Codable {
    var id: String?
    var title: String
    var description: String
    var startDate: Date
    var endDate: Date?
    var createdBy: String
    var createdAt: Date
    var isPublic: Bool
    var countries: [String]
}

struct LegacyJournalEntry: Codable {
    var id: String?
    var journalId: String
    var city: String
    var country: String
    var date: Date
    var title: String
    var notes: String
    var photoURLs: [String]
}
