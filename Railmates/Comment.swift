//
//  Comment.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import Foundation
import FirebaseFirestore

struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    var text: String
    var createdAt: Date = Date()
}
