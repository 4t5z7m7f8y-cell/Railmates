import SwiftUI

struct TripPlannerView: View {
    @ObservedObject var tripStore: TripStore
    @Binding var createTrigger: Bool
    @EnvironmentObject var authManager: AuthenticationManager

    @State private var showingCreateAlert = false
    @State private var newTripTitle = ""

    var body: some View {
        Group {
            if tripStore.isLoading && tripStore.trips.isEmpty {
                ProgressView("Loading your trips...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if tripStore.trips.isEmpty {
                emptyState
            } else {
                tripList
            }
        }
        .onAppear {
            if let userId = authManager.user?.id {
                tripStore.fetchMyTrips(userId: userId)
            }
        }
        .onChange(of: createTrigger) { _, triggered in
            if triggered {
                showingCreateAlert = true
                createTrigger = false
            }
        }
        .alert("New Trip", isPresented: $showingCreateAlert) {
            TextField("Trip title (e.g. Interrail Summer 2026)", text: $newTripTitle)
            Button("Cancel", role: .cancel) { newTripTitle = "" }
            Button("Create") { createTrip() }
        } message: {
            Text("Give your itinerary a name to get started.")
        }
    }

    // MARK: - Empty state

    @ViewBuilder
    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.fill")
                .font(.system(size: 64))
                .foregroundColor(.appGreen.opacity(0.35))

            Text("No Trip Plans Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Build your dream interrail itinerary before you go — stops, dates, budgets, and accommodation notes all in one place.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showingCreateAlert = true
            } label: {
                Label("Plan a Trip", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.appGreen)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Trip list

    @ViewBuilder
    var tripList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(tripStore.trips) { trip in
                    NavigationLink {
                        TripDetailPlannerView(trip: trip, tripStore: tripStore)
                    } label: {
                        TripPlanCard(trip: trip)
                            .appCard()
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            if let id = trip.id { tripStore.delete(tripId: id) }
                        } label: {
                            Label("Delete Trip", systemImage: "trash")
                        }
                    }
                }

                // Inline "new trip" button at bottom of list
                Button {
                    showingCreateAlert = true
                } label: {
                    Label("New Trip", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.appGreen)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appGreen.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }

    // MARK: - Helpers

    private func createTrip() {
        let name = newTripTitle.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, let userId = authManager.user?.id else {
            newTripTitle = ""
            return
        }
        let trip = Trip(title: name, createdBy: userId)
        Task { await tripStore.create(trip) }
        newTripTitle = ""
    }
}

// MARK: - Trip plan card

struct TripPlanCard: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)

                    if !trip.stops.isEmpty {
                        Label(trip.routeSummary, systemImage: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.appGreen)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if trip.isPublished {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.appGreen)
                        .font(.subheadline)
                }
            }

            HStack(spacing: 14) {
                Label("\(trip.stops.count) stop\(trip.stops.count == 1 ? "" : "s")",
                      systemImage: "mappin")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if trip.stops.contains(where: { $0.arrivalDate != nil }) {
                    Label(trip.dateRange, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if trip.computedTotalBudget > 0 {
                    Label("€\(trip.computedTotalBudget)", systemImage: "eurosign.circle")
                        .font(.caption)
                        .foregroundColor(.appOchre)
                }
            }
        }
        .padding(16)
    }
}
