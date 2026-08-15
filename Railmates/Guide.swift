import Foundation
import SwiftUI
import FirebaseFirestore

struct Guide: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var content: String
    var category: String
    var country: String = ""
    var createdBy: String?
    var authorName: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var likedBy: [String] = []
    var latitude: Double? = nil
    var longitude: Double? = nil

    var likeCount: Int { likedBy.count }

    static let categories = [
        "Booking",
        "Routes",
        "Passes",
        "Budget",
        "Packing",
        "Border Crossings",
        "Safety",
        "Other"
    ]

    static func categoryIcon(_ category: String) -> String {
        switch category {
        case "Booking":          return "ticket.fill"
        case "Routes":           return "arrow.triangle.branch"
        case "Passes":           return "creditcard.fill"
        case "Budget":           return "eurosign.circle.fill"
        case "Packing":          return "bag.fill"
        case "Border Crossings": return "flag.fill"
        case "Safety":           return "shield.fill"
        default:                 return "doc.text.fill"
        }
    }

    static func categoryColor(_ category: String) -> Color {
        switch category {
        case "Booking":          return .appGreen
        case "Routes":           return Color(red: 0.20, green: 0.40, blue: 0.80)
        case "Passes":           return .purple
        case "Budget":           return .appOchre
        case "Packing":          return .teal
        case "Border Crossings": return .orange
        case "Safety":           return .red
        default:                 return .secondary
        }
    }
}
