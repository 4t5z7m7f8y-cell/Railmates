//
//  User.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var displayName: String
    var email: String
    var createdAt: Date = Date()
    var favoriteCities: [String] = []
    var notificationToken: String? = nil
    var savedTipIds: [String]? = nil
    var savedStoryIds: [String]? = nil
    var following: [String]? = nil  // user IDs this user follows
}
