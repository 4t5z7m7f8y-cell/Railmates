import Foundation
import SwiftUI
import FirebaseFirestore

enum BudgetCategory: String, Codable, CaseIterable {
    case transport     = "Transport"
    case accommodation = "Accommodation"
    case food          = "Food"
    case activities    = "Activities"
    case other         = "Other"

    var icon: String {
        switch self {
        case .transport:     return "train.side.front.car"
        case .accommodation: return "bed.double.fill"
        case .food:          return "fork.knife"
        case .activities:    return "figure.walk"
        case .other:         return "ellipsis.circle"
        }
    }

    var color: Color {
        switch self {
        case .transport:     return .blue
        case .accommodation: return .indigo
        case .food:          return .orange
        case .activities:    return .green
        case .other:         return .gray
        }
    }
}

struct TripExpense: Codable, Identifiable {
    var id: String = UUID().uuidString
    var date: Date  = Date()
    var amount: Double
    var category: BudgetCategory
    var note: String = ""
}

enum TransportType: String, Codable, CaseIterable {
    case train = "Train"
    case bus = "Bus"
    case ferry = "Ferry"
    case flight = "Flight"
    case walk = "Walk"
    case other = "Other"

    var icon: String {
        switch self {
        case .train:  return "train.side.front.car"
        case .bus:    return "bus.fill"
        case .ferry:  return "ferry.fill"
        case .flight: return "airplane"
        case .walk:   return "figure.walk"
        case .other:  return "arrow.right.circle"
        }
    }
}

struct TripStop: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var city: String
    var country: String
    var arrivalDate: Date? = nil
    var departureDate: Date? = nil
    var accommodationNotes: String = ""
    var budgetEUR: Int? = nil
    var transportToNext: TransportType = .train
    var notes: String = ""
    var order: Int

    var nights: Int {
        guard let arrival = arrivalDate, let departure = departureDate else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: arrival, to: departure).day ?? 0)
    }

    var displayName: String { "\(city), \(country)" }

    var dateRangeText: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        switch (arrivalDate, departureDate) {
        case let (a?, d?): return "\(fmt.string(from: a)) – \(fmt.string(from: d))"
        case let (a?, nil): return "from \(fmt.string(from: a))"
        case let (nil, d?): return "until \(fmt.string(from: d))"
        default: return ""
        }
    }
}

struct Trip: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var createdBy: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var stops: [TripStop] = []
    var notes: String = ""
    var isPublished: Bool = false
    var publishedStoryId: String? = nil
    var clonedFromStoryId: String? = nil
    var plannedBudget: [String: Double] = [:]
    var expenses: [TripExpense] = []

    var computedTotalBudget: Int {
        stops.compactMap { $0.budgetEUR }.reduce(0, +)
    }

    var totalPlanned: Double { plannedBudget.values.reduce(0, +) }
    var totalActual: Double  { expenses.map(\.amount).reduce(0, +) }

    func planned(for category: BudgetCategory) -> Double {
        plannedBudget[category.rawValue] ?? 0
    }

    func actual(for category: BudgetCategory) -> Double {
        expenses.filter { $0.category == category }.map(\.amount).reduce(0, +)
    }

    var dateRange: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        let first = stops.compactMap { $0.arrivalDate }.min()
        let last  = stops.compactMap { $0.departureDate }.max()
        switch (first, last) {
        case let (s?, e?): return "\(fmt.string(from: s)) – \(fmt.string(from: e))"
        case let (s?, nil): return fmt.string(from: s)
        default: return "No dates set"
        }
    }

    var countriesVisited: [String] {
        Array(Set(stops.map { $0.country })).sorted()
    }

    var routeSummary: String {
        let cities = stops.sorted { $0.order < $1.order }.map { $0.city }
        guard !cities.isEmpty else { return "No stops yet" }
        if cities.count <= 3 { return cities.joined(separator: " → ") }
        return "\(cities.prefix(2).joined(separator: " → ")) → ... → \(cities.last!)"
    }

    var tripStartDate: Date? { stops.compactMap { $0.arrivalDate }.min() }
    var tripEndDate: Date?   { stops.compactMap { $0.departureDate }.max() }
}
