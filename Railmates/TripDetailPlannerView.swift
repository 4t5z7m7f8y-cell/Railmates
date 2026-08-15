import SwiftUI

struct TripDetailPlannerView: View {
    let trip: Trip
    @ObservedObject var tripStore: TripStore
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingAddStop      = false
    @State private var editingStop: TripStop?
    @State private var showingDeleteAlert  = false
    @State private var showingPublish      = false
    @State private var showingRenameAlert  = false
    @State private var editedTitle         = ""
    @State private var showingAddExpense   = false
    @State private var showingEditBudget   = false
    @State private var showingBudgetStats  = false

    var currentTrip: Trip {
        tripStore.trips.first(where: { $0.id == trip.id }) ?? trip
    }

    var sortedStops: [TripStop] {
        currentTrip.stops.sorted { $0.order < $1.order }
    }

    var nextOrder: Int { (sortedStops.last?.order ?? -1) + 1 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryCard
                    .padding(.horizontal)

                if sortedStops.isEmpty {
                    emptyState
                } else {
                    stopsTimeline
                }

                addStopButton
                    .padding(.horizontal)

                budgetSection
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .padding(.top)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(currentTrip.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingBudgetStats = true
                } label: {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.appGreen)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        editedTitle = currentTrip.title
                        showingRenameAlert = true
                    } label: {
                        Label("Rename Trip", systemImage: "pencil")
                    }

                    if !currentTrip.isPublished {
                        Button {
                            showingPublish = true
                        } label: {
                            Label("Publish as Story", systemImage: "square.and.arrow.up")
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Trip", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        // Add stop sheet
        .sheet(isPresented: $showingAddStop) {
            AddEditTripStopView(
                stopOrder: nextOrder
            ) { newStop in
                var updated = currentTrip
                updated.stops.append(newStop)
                tripStore.update(updated)
            }
        }
        // Edit stop sheet
        .sheet(item: $editingStop) { stop in
            AddEditTripStopView(
                existingStop: stop,
                stopOrder: stop.order
            ) { updated in
                var t = currentTrip
                if let i = t.stops.firstIndex(where: { $0.id == stop.id }) {
                    t.stops[i] = updated
                }
                tripStore.update(t)
            }
        }
        // Publish sheet
        .sheet(isPresented: $showingPublish) {
            TripPublishView(trip: currentTrip) {
                var updated = currentTrip
                updated.isPublished = true
                tripStore.update(updated)
            }
        }
        // Budget stats sheet
        .sheet(isPresented: $showingBudgetStats) {
            TripBudgetStatsView(trip: currentTrip)
        }
        // Budget sheets
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView { expense in
                var updated = currentTrip
                updated.expenses.append(expense)
                tripStore.update(updated)
            }
        }
        .sheet(isPresented: $showingEditBudget) {
            EditBudgetView(existing: currentTrip.plannedBudget) { newBudget in
                var updated = currentTrip
                updated.plannedBudget = newBudget
                tripStore.update(updated)
            }
        }
        // Rename alert
        .alert("Rename Trip", isPresented: $showingRenameAlert) {
            TextField("Trip title", text: $editedTitle)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                let name = editedTitle.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                var updated = currentTrip
                updated.title = name
                tripStore.update(updated)
            }
        }
        // Delete alert
        .alert("Delete Trip", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let id = currentTrip.id {
                    tripStore.delete(tripId: id)
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete your itinerary. This can't be undone.")
        }
    }

    // MARK: - Summary card

    @ViewBuilder
    var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if currentTrip.isPublished {
                Label("Published as Story", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.appGreen)
                    .clipShape(Capsule())
            }

            HStack(spacing: 24) {
                statPill(value: "\(sortedStops.count)", label: "Stops")
                statPill(value: "\(currentTrip.countriesVisited.count)", label: "Countries")
                if currentTrip.computedTotalBudget > 0 {
                    statPill(value: "€\(currentTrip.computedTotalBudget)", label: "Budget")
                }
            }

            if sortedStops.contains(where: { $0.arrivalDate != nil }) {
                Label(currentTrip.dateRange, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if sortedStops.count > 1 {
                Label(currentTrip.routeSummary, systemImage: "arrow.right")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.appGreen)
                    .lineLimit(2)
            }

            if !currentTrip.notes.isEmpty {
                Text(currentTrip.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    func statPill(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3).fontWeight(.bold)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
    }

    // MARK: - Empty state

    @ViewBuilder
    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 52))
                .foregroundColor(.appGreen.opacity(0.45))
            Text("No stops yet")
                .font(.headline)
            Text("Add your first destination to start building your itinerary.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    // MARK: - Stops timeline

    @ViewBuilder
    var stopsTimeline: some View {
        VStack(spacing: 0) {
            ForEach(Array(sortedStops.enumerated()), id: \.element.id) { index, stop in
                stopCard(stop: stop, index: index)

                if index < sortedStops.count - 1 {
                    transportConnector(type: stop.transportToNext)
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    func stopCard(stop: TripStop, index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Number badge
            ZStack {
                Circle()
                    .fill(Color.appGreen)
                    .frame(width: 32, height: 32)
                Text("\(index + 1)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stop.city)
                            .font(.headline)
                        Text(stop.country)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Button {
                            editingStop = stop
                        } label: {
                            Image(systemName: "pencil.circle")
                                .foregroundColor(.appGreen)
                                .font(.title3)
                        }
                        Button {
                            deleteStop(stop)
                        } label: {
                            Image(systemName: "trash.circle")
                                .foregroundColor(.red.opacity(0.7))
                                .font(.title3)
                        }
                    }
                }

                if !stop.dateRangeText.isEmpty {
                    Label(stop.dateRangeText, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if stop.nights > 0 {
                    Label("\(stop.nights) night\(stop.nights == 1 ? "" : "s")", systemImage: "moon.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let budget = stop.budgetEUR, budget > 0 {
                    Label("€\(budget)", systemImage: "eurosign.circle")
                        .font(.caption)
                        .foregroundColor(.appOchre)
                }

                if !stop.accommodationNotes.isEmpty {
                    Label(stop.accommodationNotes, systemImage: "bed.double")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                if !stop.notes.isEmpty {
                    Text(stop.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
    }

    @ViewBuilder
    func transportConnector(type: TransportType) -> some View {
        HStack(spacing: 8) {
            // Vertical line aligned under the circle badge
            Rectangle()
                .fill(Color.appGreen.opacity(0.3))
                .frame(width: 2, height: 28)
                .padding(.leading, 15)

            HStack(spacing: 4) {
                Image(systemName: type.icon).font(.caption2)
                Text(type.rawValue).font(.caption2)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color(.systemFill))
            .clipShape(Capsule())

            Spacer()
        }
    }

    // MARK: - Add stop button

    var addStopButton: some View {
        Button {
            showingAddStop = true
        } label: {
            Label("Add Stop", systemImage: "plus.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.appGreen)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Budget Section

    @ViewBuilder
    var budgetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Budget")
                    .font(.headline)
                Spacer()
                Button { showingEditBudget = true } label: {
                    Label("Plan", systemImage: "slider.horizontal.3")
                        .font(.caption)
                        .foregroundColor(.appGreen)
                }
                Button { showingAddExpense = true } label: {
                    Label("Expense", systemImage: "plus")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.appGreen)
                        .clipShape(Capsule())
                }
            }

            let hasBudget = currentTrip.totalPlanned > 0 || !currentTrip.expenses.isEmpty

            if hasBudget {
                // Totals summary
                let planned = currentTrip.totalPlanned
                let actual  = currentTrip.totalActual
                let over    = actual > planned && planned > 0

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Planned").font(.caption).foregroundColor(.secondary)
                        Text(planned > 0 ? "€\(Int(planned))" : "—")
                            .font(.title3).fontWeight(.semibold)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spent").font(.caption).foregroundColor(.secondary)
                        Text("€\(Int(actual))")
                            .font(.title3).fontWeight(.semibold)
                            .foregroundColor(over ? .red : .primary)
                    }
                    if planned > 0 {
                        Spacer()
                        let diff = actual - planned
                        Text(diff > 0 ? "+€\(Int(diff)) over" : "€\(Int(-diff)) left")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundColor(diff > 0 ? .red : .appGreen)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background((diff > 0 ? Color.red : Color.appGreen).opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                // Per-category breakdown
                ForEach(BudgetCategory.allCases, id: \.self) { cat in
                    let p = currentTrip.planned(for: cat)
                    let a = currentTrip.actual(for: cat)
                    if p > 0 || a > 0 {
                        categoryRow(cat: cat, planned: p, actual: a)
                    }
                }

                // Expenses list
                if !currentTrip.expenses.isEmpty {
                    Divider()
                    Text("Expenses")
                        .font(.subheadline).fontWeight(.semibold)
                    ForEach(currentTrip.expenses.sorted { $0.date > $1.date }) { expense in
                        HStack(spacing: 10) {
                            Image(systemName: expense.category.icon)
                                .foregroundColor(expense.category.color)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(expense.note.isEmpty ? expense.category.rawValue : expense.note)
                                    .font(.subheadline)
                                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("€\(String(format: "%.0f", expense.amount))")
                                .font(.subheadline).fontWeight(.medium)
                        }
                        .padding(.vertical, 2)
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 8) {
                    Text("No budget set yet")
                        .font(.subheadline).foregroundColor(.secondary)
                    Button("Plan Budget") { showingEditBudget = true }
                        .font(.subheadline).foregroundColor(.appGreen)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    func categoryRow(cat: BudgetCategory, planned: Double, actual: Double) -> some View {
        let over = actual > planned && planned > 0
        let progress = planned > 0 ? min(actual / planned, 1.0) : 0
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(cat.rawValue, systemImage: cat.icon)
                    .font(.caption).foregroundColor(cat.color)
                Spacer()
                if planned > 0 {
                    Text("€\(Int(actual)) / €\(Int(planned))")
                        .font(.caption).foregroundColor(over ? .red : .secondary)
                } else {
                    Text("€\(Int(actual))")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            if planned > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemFill))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(over ? Color.red : cat.color)
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
    }

    // MARK: - Helpers

    private func deleteStop(_ stop: TripStop) {
        var updated = currentTrip
        updated.stops.removeAll { $0.id == stop.id }
        // Re-index remaining stops
        let reindexed = updated.stops.sorted { $0.order < $1.order }.enumerated().map { i, s -> TripStop in
            var s = s; s.order = i; return s
        }
        updated.stops = reindexed
        tripStore.update(updated)
    }
}
