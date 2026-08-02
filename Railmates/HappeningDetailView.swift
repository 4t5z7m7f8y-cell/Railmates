//
//  HappeningDetailView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import SwiftUI
import MapKit

struct HappeningDetailView: View {
    let happening: Happening
    @ObservedObject var store: HappeningStore
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    
    var isCreator: Bool {
        authManager.user?.id == happening.createdBy
    }
    
    var isAttending: Bool {
        guard let userId = authManager.user?.id else { return false }
        return happening.attendeeIds.contains(userId)
    }
    
    var canJoin: Bool {
        !isAttending && !happening.isFull && !happening.isPast
    }
    
    var shareText: String {
        """
        📅 \(happening.title)
        
        \(happening.description)
        
        📍 \(happening.city)
        🕐 \(happening.dateTime.formatted(date: .long, time: .shortened))
        👥 \(happening.attendeeIds.count) attending
        
        Join me on Railmates!
        """
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(happening.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        if happening.isPast {
                            Text("Past Event")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if happening.isFull {
                            Text("Full")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Text(happening.title)
                        .font(.title2)
                        .bold()
                    
                    if !happening.description.isEmpty {
                        Text(happening.description)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
                
                Divider()
                
                // Date & Location Info
                VStack(alignment: .leading, spacing: 12) {
                    Label(
                        happening.dateTime.formatted(date: .long, time: .shortened),
                        systemImage: "calendar"
                    )
                    .font(.subheadline)
                    
                    Label(happening.city, systemImage: "location.fill")
                        .font(.subheadline)
                    
                    if let locationName = happening.locationName {
                        Label(locationName, systemImage: "mappin.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                
                Divider()
                
                // Attendees
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Attendees")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(happening.attendeeIds.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let max = happening.maxAttendees {
                            Text("/ \(max)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if happening.attendeeIds.isEmpty {
                        Text("No one has joined yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(happening.attendeeIds.count) people attending")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Map Preview
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: happening.latitude,
                        longitude: happening.longitude
                    ),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))) {
                    Marker(
                        happening.locationName ?? happening.city,
                        systemImage: "figure.wave",
                        coordinate: CLLocationCoordinate2D(
                            latitude: happening.latitude,
                            longitude: happening.longitude
                        )
                    )
                    .tint(.green)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Action Buttons
                VStack(spacing: 12) {
                    if isCreator {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Event", systemImage: "trash.fill")
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    } else if canJoin {
                        Button {
                            joinHappening()
                        } label: {
                            Label("I'm Joining!", systemImage: "person.badge.plus.fill")
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .buttonStyle(.borderedProminent)
                    } else if isAttending {
                        Button {
                            leaveHappening()
                        } label: {
                            Label("Leave Event", systemImage: "person.badge.minus")
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if happening.isPast {
                        Text("This event has already happened")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    } else if happening.isFull && !isAttending {
                        Text("This event is full")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [shareText])
        }
        .alert("Delete Event", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteHappening()
            }
        } message: {
            Text("Are you sure you want to delete this event? This can't be undone.")
        }
    }
    
    func joinHappening() {
        guard let happeningId = happening.id,
              let userId = authManager.user?.id else { return }
        store.join(happeningId: happeningId, userId: userId)
    }
    
    func leaveHappening() {
        guard let happeningId = happening.id,
              let userId = authManager.user?.id else { return }
        store.leave(happeningId: happeningId, userId: userId)
    }
    
    func deleteHappening() {
        guard let happeningId = happening.id else { return }
        store.delete(happeningId: happeningId)
    }
}
// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

