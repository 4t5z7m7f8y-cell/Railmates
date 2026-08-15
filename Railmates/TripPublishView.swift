import SwiftUI
import FirebaseFirestore

struct TripPublishView: View {
    let trip: Trip
    var onPublish: () -> Void

    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var storyText = ""
    @State private var isPublic = true
    @State private var isPublishing = false
    @State private var errorMessage: String?

    private var tripStart: Date {
        trip.stops.compactMap { $0.arrivalDate }.min() ?? Date()
    }

    private var tripEnd: Date {
        trip.stops.compactMap { $0.departureDate }.max() ?? Date()
    }

    private var visitedPlaces: [PlaceVisited] {
        trip.stops.sorted { $0.order < $1.order }.enumerated().map { i, stop in
            PlaceVisited(city: stop.city, country: stop.country, order: i)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Story Title") {
                    TextField("Give your story a title", text: $title)
                }

                Section {
                    TextEditor(text: $storyText)
                        .frame(minHeight: 160)
                } header: {
                    Text("Your Story")
                } footer: {
                    Text("Share what it was actually like — the highlights, surprises, and tips for fellow travelers.")
                }

                Section("From Your Itinerary") {
                    LabeledContent("Route", value: trip.routeSummary)
                        .font(.subheadline)
                    LabeledContent("Dates", value: trip.dateRange)
                    if trip.computedTotalBudget > 0 {
                        LabeledContent("Budget", value: "€\(trip.computedTotalBudget)")
                    }
                }

                Section {
                    Toggle("Visible to everyone", isOn: $isPublic)
                } header: {
                    Text("Visibility")
                } footer: {
                    Text(isPublic
                         ? "Your story will appear in the community feed."
                         : "Only you can see this story.")
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button(action: publish) {
                        HStack {
                            Spacer()
                            if isPublishing {
                                ProgressView()
                            } else {
                                Label("Publish Story", systemImage: "square.and.arrow.up.fill")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty ||
                              storyText.trimmingCharacters(in: .whitespaces).isEmpty ||
                              isPublishing)
                }
            }
            .navigationTitle("Publish as Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { title = trip.title }
        }
    }

    private func publish() {
        guard let userId = authManager.user?.id else { return }
        isPublishing = true
        errorMessage = nil

        let story = TripStory(
            title: title.trimmingCharacters(in: .whitespaces),
            story: storyText.trimmingCharacters(in: .whitespaces),
            createdBy: userId,
            isPublic: isPublic,
            tripStart: tripStart,
            tripEnd: tripEnd,
            visitedPlaces: visitedPlaces,
            budget: trip.computedTotalBudget > 0 ? trip.computedTotalBudget : nil
        )

        do {
            _ = try Firestore.firestore().collection("tripStories").addDocument(from: story)
            onPublish()
            dismiss()
        } catch {
            isPublishing = false
            errorMessage = "Failed to publish: \(error.localizedDescription)"
        }
    }
}
