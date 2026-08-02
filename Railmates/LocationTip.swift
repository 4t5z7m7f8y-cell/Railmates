//
//  LocationTip.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import Foundation
import FirebaseFirestore

struct LocationTip: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var category: String       // "Hotel", "Food", "Activity", "Sight"
    var description: String
    var locationName: String   // e.g. "Berlin, Germany"
    var latitude: Double
    var longitude: Double
    var createdAt: Date = Date()
}
