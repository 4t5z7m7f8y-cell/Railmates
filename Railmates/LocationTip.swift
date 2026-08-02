//
//  LocationTip.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//
import Foundation
import FirebaseFirestore
import CoreLocation

struct LocationTip: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var category: String
    var description: String
    var locationName: String
    var latitude: Double
    var longitude: Double
    var createdAt: Date = Date()
    var ratingSum: Int = 0
    var ratingCount: Int = 0

    var averageRating: Double {
        ratingCount == 0 ? 0 : Double(ratingSum) / Double(ratingCount)
    }

    func distance(from userLocation: CLLocationCoordinate2D) -> CLLocationDistance {
        let tipLocation = CLLocation(latitude: latitude, longitude: longitude)
        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        return tipLocation.distance(from: userLoc)
    }
}
