import SwiftUI
import Charts

struct TripStatsView: View {
    let trips: [Trip]

    private var tripsWithSpend: [Trip] { trips.filter { $0.totalActual > 0 } }
    private var totalSpent: Double { trips.map(\.totalActual).reduce(0, +) }
    private var totalCountries: Int { Set(trips.flatMap(\.countriesVisited)).count }
    private var totalNights: Int {
        trips.flatMap(\.stops).compactMap { stop -> Int? in
            guard let a = stop.arrivalDate, let d = stop.departureDate else { return nil }
            return Calendar.current.dateComponents([.day], from: a, to: d).day
        }.reduce(0, +)
    }
    private var tripsUnderBudget: Int {
        trips.filter { $0.totalPlanned > 0 && $0.totalActual <= $0.totalPlanned }.count
    }
    private var tripsWithBudget: Int { trips.filter { $0.totalPlanned > 0 }.count }

    // Monthly spend data (last 12 months)
    private struct MonthPoint: Identifiable {
        let id = UUID()
        let month: Date
        let amount: Double
    }

    private var monthlyData: [MonthPoint] {
        let cal = Calendar.current
        let now = Date()
        guard let start = cal.date(byAdding: .month, value: -11, to: cal.startOfDay(for: now)) else { return [] }
        var buckets: [Date: Double] = [:]
        for trip in trips {
            for exp in trip.expenses {
                guard exp.date >= start else { continue }
                let comps = cal.dateComponents([.year, .month], from: exp.date)
                if let bucket = cal.date(from: comps) {
                    buckets[bucket, default: 0] += exp.amount
                }
            }
        }
        return buckets.map { MonthPoint(month: $0.key, amount: $0.value) }
            .sorted { $0.month < $1.month }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summarySection
                    if tripsWithSpend.count >= 2 {
                        spendPerTripChart
                    }
                    if monthlyData.count >= 2 {
                        monthlyChart
                    }
                    funStatsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Travel Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Summary

    @ViewBuilder
    var summarySection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(value: "\(trips.count)", label: "Total Trips",  icon: "train.side.front.car", color: .appGreen)
            statCard(value: "\(totalCountries)", label: "Countries",  icon: "globe", color: .blue)
            statCard(value: totalSpent > 0 ? "€\(Int(totalSpent))" : "—",
                     label: "Total Spent", icon: "eurosign.circle.fill", color: .appOchre)
            statCard(value: "\(totalNights)", label: "Nights Away", icon: "moon.fill", color: .indigo)
        }
    }

    func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.title3).fontWeight(.bold)
                Text(label).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Spend per trip chart

    @ViewBuilder
    var spendPerTripChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spend Per Trip")
                .font(.headline)

            Chart(tripsWithSpend) { trip in
                BarMark(
                    x: .value("€", trip.totalActual),
                    y: .value("Trip", trip.title)
                )
                .foregroundStyle(Color.appGreen)
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("€\(Int(trip.totalActual))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: max(60, Double(tripsWithSpend.count) * 44))
            .chartXAxis(.hidden)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Monthly chart

    @ViewBuilder
    var monthlyChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Monthly Spend")
                .font(.headline)
            Text("Last 12 months")
                .font(.caption).foregroundColor(.secondary)

            Chart(monthlyData) { point in
                BarMark(
                    x: .value("Month", point.month, unit: .month),
                    y: .value("€", point.amount)
                )
                .foregroundStyle(Color.appGreen.gradient)
                .cornerRadius(4)
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .font(.caption2)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Fun stats

    @ViewBuilder
    var funStatsSection: some View {
        let mostExpensive = tripsWithSpend.max(by: { $0.totalActual < $1.totalActual })
        let underPct = tripsWithBudget > 0
            ? Int(Double(tripsUnderBudget) / Double(tripsWithBudget) * 100)
            : 0
        let allCountries = Set(trips.flatMap(\.countriesVisited))

        VStack(alignment: .leading, spacing: 12) {
            Text("Highlights")
                .font(.headline)

            if let top = mostExpensive {
                funRow(icon: "star.fill", color: .appOchre,
                       label: "Most expensive trip",
                       value: "\(top.title) · €\(Int(top.totalActual))")
            }

            if tripsWithBudget > 0 {
                funRow(icon: "checkmark.seal.fill", color: .appGreen,
                       label: "Trips under budget",
                       value: "\(tripsUnderBudget) of \(tripsWithBudget) (\(underPct)%)")
            }

            if !allCountries.isEmpty {
                funRow(icon: "globe.europe.africa.fill", color: .blue,
                       label: "Countries explored",
                       value: allCountries.sorted().joined(separator: ", "))
            }

            let avgPerTrip = tripsWithSpend.isEmpty ? 0 : totalSpent / Double(tripsWithSpend.count)
            if avgPerTrip > 0 {
                funRow(icon: "chart.line.uptrend.xyaxis", color: .purple,
                       label: "Average spend per trip",
                       value: "€\(Int(avgPerTrip))")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func funRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundColor(color).frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundColor(.secondary)
                Text(value).font(.subheadline)
            }
        }
    }
}
