import Foundation
import Combine
import FirebaseFirestore

@MainActor
class TripStore: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func fetchMyTrips(userId: String) {
        isLoading = true
        listener?.remove()
        listener = db.collection("trips")
            .whereField("createdBy", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to load trips: \(error.localizedDescription)"
                    return
                }
                self.trips = (snapshot?.documents.compactMap { try? $0.data(as: Trip.self) } ?? [])
                    .sorted { $0.updatedAt > $1.updatedAt }
            }
    }

    func create(_ trip: Trip) async -> String? {
        do {
            let ref = try db.collection("trips").addDocument(from: trip)
            return ref.documentID
        } catch {
            errorMessage = "Failed to create trip: \(error.localizedDescription)"
            return nil
        }
    }

    func update(_ trip: Trip) {
        guard let id = trip.id else { return }
        var t = trip
        t.updatedAt = Date()
        try? db.collection("trips").document(id).setData(from: t, merge: true)
    }

    func delete(tripId: String) {
        db.collection("trips").document(tripId).delete { [weak self] error in
            if let error = error {
                self?.errorMessage = "Failed to delete trip: \(error.localizedDescription)"
            }
        }
    }
}
