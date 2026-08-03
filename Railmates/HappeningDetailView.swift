//
//  HappeningDetailView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import SwiftUI
import MapKit
import EventKit

struct HappeningDetailView: View {
    let happening: Happening
    @ObservedObject var store: HappeningStore
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var showingEditSheet = false
    @State private var attendees: [User] = []
    @State private var isLoadingAttendees = false
    @State private var isJoining = false
    @State private var isLeaving = false
    @State private var errorAlert: ErrorAlert?
    
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
    
    var timeUntilEvent: String {
        let now = Date()
        let timeInterval = happening.dateTime.timeIntervalSince(now)
        
        if timeInterval < 0 {
            return "Event has passed"
        }
        
        let days = Int(timeInterval) / 86400
        let hours = (Int(timeInterval) % 86400) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if days > 0 {
            return "Starting in \(days) day\(days == 1 ? "" : "s"), \(hours) hour\(hours == 1 ? "" : "s")"
        } else if hours > 0 {
            return "Starting in \(hours) hour\(hours == 1 ? "" : "s"), \(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            return "Starting in \(minutes) minute\(minutes == 1 ? "" : "s")"
        }
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
                    
                    if !happening.isPast {
                        Label(timeUntilEvent, systemImage: "clock.fill")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    
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
                    } else if isLoadingAttendees {
                        ProgressView()
                            .padding(.vertical, 4)
                    } else if attendees.isEmpty {
                        Text("\(happening.attendeeIds.count) people attending")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(attendees) { attendee in
                                HStack(spacing: 8) {
                                    // Avatar circle with initials
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                        Text(attendee.displayName.prefix(1).uppercased())
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Text(attendee.displayName)
                                        .font(.subheadline)
                                    
                                    if attendee.id == happening.createdBy {
                                        Text("(Organizer)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
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
                    // Add to Calendar button (for all attendees and past events)
                    if isAttending || happening.isPast {
                        Button {
                            addToCalendar()
                        } label: {
                            Label("Add to Calendar", systemImage: "calendar.badge.plus")
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .buttonStyle(.bordered)
                    }
                    
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
                            if isJoining {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            } else {
                                Label("I'm Joining!", systemImage: "person.badge.plus.fill")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isJoining)
                    } else if isAttending {
                        Button {
                            leaveHappening()
                        } label: {
                            if isLeaving {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            } else {
                                Label("Leave Event", systemImage: "person.badge.minus")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(isLeaving)
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
                HStack(spacing: 12) {
                    if isCreator && !happening.isPast {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                    
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let user = authManager.user {
                EditHappeningView(happening: happening, userId: user.id ?? "") { updatedHappening in
                    store.update(updatedHappening)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [shareText])
        }
        .task {
            await loadAttendees()
        }
        .errorAlert($errorAlert)
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
        isJoining = true
        store.join(happeningId: happeningId, userId: userId)
        // Reset after a delay (the real-time listener will update the UI)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isJoining = false
        }
    }
    
    func leaveHappening() {
        guard let happeningId = happening.id,
              let userId = authManager.user?.id else { return }
        isLeaving = true
        store.leave(happeningId: happeningId, userId: userId)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLeaving = false
        }
    }
    
    func deleteHappening() {
        guard let happeningId = happening.id else { return }
        store.delete(happeningId: happeningId)
    }
    
    func loadAttendees() async {
        guard !happening.attendeeIds.isEmpty else { return }
        
        isLoadingAttendees = true
        
        let fetchedAttendees = await store.fetchUsers(userIds: happening.attendeeIds)
        
        await MainActor.run {
            self.attendees = fetchedAttendees
            self.isLoadingAttendees = false
        }
    }
    
    func addToCalendar() {
        let eventStore = EKEventStore()
        
        eventStore.requestAccess(to: .event) { granted, error in
            if granted && error == nil {
                let event = EKEvent(eventStore: eventStore)
                event.title = happening.title
                event.startDate = happening.dateTime
                event.endDate = happening.dateTime.addingTimeInterval(3600) // 1 hour duration
                event.location = happening.locationName ?? happening.city
                event.notes = happening.description
                event.calendar = eventStore.defaultCalendarForNewEvents
                
                do {
                    try eventStore.save(event, span: .thisEvent)
                    print("✅ Event added to calendar")
                } catch {
                    print("Error saving event to calendar: \(error)")
                }
            }
        }
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

