import SwiftUI
import Charts

struct TripBudgetStatsView: View {
    let trip: Trip

    private var categoriesWithData: [BudgetCategory] {
        BudgetCategory.allCases.filter { trip.planned(for: $0) > 0 || trip.actual(for: $0) > 0 }
    }

    // Flat data for grouped bar chart
    private struct CategoryBar: Identifiable {
        let id = UUID()
        let category: String
        let type: String
        let amount: Double
        let color: Color
    }

    private var barData: [CategoryBar] {
        categoriesWithData.flatMap { cat in [
            CategoryBar(category: cat.rawValue, type: "Planned", amount: trip.planned(for: cat), color: .secondary.opacity(0.35)),
            CategoryBar(category: cat.rawValue, type: "Actual",  amount: trip.actual(for: cat),  color: trip.actual(for: cat) > trip.planned(for: cat) && trip.planned(for: cat) > 0 ? .red : cat.color)
        ]}
    }

    // Cumulative daily spend for line chart
    private struct DailyPoint: Identifiable {
        let id = UUID()
        let date: Date
        let cumulative: Double
    }

    private var dailyPoints: [DailyPoint] {
        let sorted = trip.expenses.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return [] }
        let cal = Calendar.current
        var grouped: [(Date, Double)] = []
        var current: Date?
        var running = 0.0
        for exp in sorted {
            let day = cal.startOfDay(for: exp.date)
            if day == current {
                running += exp.amount
            } else {
                if let prev = current { grouped.append((prev, running)) }
                current = day
                running = exp.amount
            }
        }
        if let last = current { grouped.append((last, running)) }
        var cumul = 0.0
        return grouped.map { date, amount -> DailyPoint in
            cumul += amount
            return DailyPoint(date: date, cumulative: cumul)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summaryCards
                    if !categoriesWithData.isEmpty {
                        categoryChart
                    }
                    if dailyPoints.count >= 2 {
                        dailyChart
                    }
                    if categoriesWithData.isEmpty && trip.expenses.isEmpty {
                        ContentUnavailableView(
                            "No Budget Data",
                            systemImage: "chart.bar",
                            description: Text("Set a budget and log expenses in the planner to see charts here.")
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Budget Stats")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Summary Cards

    @ViewBuilder
    var summaryCards: some View {
        let planned = trip.totalPlanned
        let actual  = trip.totalActual
        let diff    = actual - planned
        let over    = planned > 0 && diff > 0

        HStack(spacing: 12) {
            statCard(title: "Planned", value: planned > 0 ? "€\(Int(planned))" : "—", color: .secondary)
            statCard(title: "Spent",   value: "€\(Int(actual))",  color: over ? .red : .appGreen)
            if planned > 0 {
                statCard(
                    title: over ? "Over" : "Remaining",
                    value: "€\(Int(abs(diff)))",
                    color: over ? .red : .appGreen
                )
            }
        }

        let stops   = trip.stops.count
        let days    = trip.stops.compactMap { stop -> Int? in
            guard let a = stop.arrivalDate, let d = stop.departureDate else { return nil }
            return Calendar.current.dateComponents([.day], from: a, to: d).day
        }.reduce(0, +)
        let countries = trip.countriesVisited.count

        HStack(spacing: 12) {
            statCard(title: "Stops",     value: "\(stops)",     color: .blue)
            statCard(title: "Countries", value: "\(countries)", color: .indigo)
            if days > 0 {
                statCard(title: "Nights", value: "\(days)", color: .purple)
            }
            if actual > 0 && days > 0 {
                statCard(title: "Per Day", value: "€\(Int(actual / Double(days)))", color: .appOchre)
            }
        }
    }

    func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3).fontWeight(.bold).foregroundColor(color)
            Text(title).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Category Bar Chart

    @ViewBuilder
    var categoryChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Planned vs Actual")
                .font(.headline)

            Chart(barData) { bar in
                BarMark(
                    x: .value("Category", bar.category),
                    y: .value("€", bar.amount)
                )
                .foregroundStyle(bar.color)
                .position(by: .value("Type", bar.type))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let s = value.as(String.self) {
                            Text(s.prefix(5)).font(.caption2)
                        }
                    }
                }
            }
            .chartLegend(position: .bottom, alignment: .center)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Daily Spend Line Chart

    @ViewBuilder
    var dailyChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cumulative Spend")
                .font(.headline)
            Text("Total spend over time")
                .font(.caption).foregroundColor(.secondary)

            Chart(dailyPoints) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("€", point.cumulative)
                )
                .foregroundStyle(Color.appGreen)
                .interpolationMethod(.monotone)

                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("€", point.cumulative)
                )
                .foregroundStyle(Color.appGreen.opacity(0.12))
                .interpolationMethod(.monotone)

                PointMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("€", point.cumulative)
                )
                .foregroundStyle(Color.appGreen)
                .symbolSize(30)
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .font(.caption2)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
