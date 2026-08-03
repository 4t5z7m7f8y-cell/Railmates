//
//  HappeningsListView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import SwiftUI
import MapKit

struct HappeningsListView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var store = HappeningStore()
    @StateObject private var locationManager = LocationManager()
    @State private var showingAddSheet = false
    @State private var selectedCity: String? = nil
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var showOnlyMyEvents = false
    @State private var showPastEvents = false
    @State private var errorAlert: ErrorAlert?
    
    var filteredHappenings: [Happening] {
        var filtered = store.happenings
        
        // Filter by city
        if let city = selectedCity {
            filtered = filtered.filter { $0.city == city }
        }
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { happening in
                happening.title.localizedCaseInsensitiveContains(searchText) ||
                happening.description.localizedCaseInsensitiveContains(searchText) ||
                happening.city.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by "My Events"
        if showOnlyMyEvents, let userId = authManager.user?.id {
            filtered = filtered.filter { $0.attendeeIds.contains(userId) }
        }
        
        return filtered
    }
    
    var availableCategories: [String] {
        Array(Set(store.happenings.map { $0.category })).sorted()
    }
    
    var availableCities: [String] {
        Array(Set(store.happenings.map { $0.city })).sorted()
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading && store.happenings.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading events...")
                            .foregroundColor(.secondary)
                    }
                } else if store.happenings.isEmpty {
                    ContentUnavailableView(
                        "No Happenings Yet",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Tap + to create the first meetup")
                    )
                } else if filteredHappenings.isEmpty {
                    ContentUnavailableView(
                        "No Matching Events",
                        systemImage: "magnifyingglass",
                        description: Text("Try adjusting your filters or search")
                    )
                } else {
                    List(filteredHappenings) { happening in
                        NavigationLink {
                            HappeningDetailView(happening: happening, store: store)
                        } label: {
                            HappeningRow(
                                happening: happening,
                                currentUserId: authManager.user?.id,
                                userLocation: locationManager.currentLocation
                            )
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search events...")
                    .refreshable {
                        store.fetchUpcoming()
                    }
                }
            }
            .navigationTitle(showPastEvents ? "Past Events" : "Happenings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Section("View") {
                            Toggle("Show Past Events", isOn: $showPastEvents)
                        }
                        
                        Section("Filters") {
                            Toggle("My Events Only", isOn: $showOnlyMyEvents)
                        }
                        
                        Section("City") {
                            Button("All Cities") {
                                selectedCity = nil
                            }
                            
                            ForEach(availableCities, id: \.self) { city in
                                Button(city) {
                                    selectedCity = city
                                }
                            }
                        }
                        
                        Section("Category") {
                            Button("All Categories") {
                                selectedCategory = nil
                            }
                            
                            ForEach(availableCategories, id: \.self) { category in
                                Button(category) {
                                    selectedCategory = category
                                }
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                if let user = authManager.user {
                    AddHappeningView(userId: user.id ?? "") { newHappening in
                        store.create(newHappening)
                    }
                }
            }
            .onAppear {
                store.fetchUpcoming()
                locationManager.requestPermission()
            }
            .errorAlert($errorAlert)
            .onChange(of: store.errorMessage) { oldValue, newValue in
                if let error = newValue {
                    errorAlert = ErrorAlert(
                        title: "Error",
                        message: error
                    )
                }
            }
        }
    }
}

struct HappeningRow: View {
    let happening: Happening
    let currentUserId: String?
    let userLocation: CLLocationCoordinate2D?
    
    var categoryIcon: String {
        switch happening.category {
        case "Meetup": return "person.3.fill"
        case "Party": return "party.popper.fill"
        case "Day Trip": return "figure.hiking"
        case "Pub Crawl": return "cup.and.saucer.fill"
        case "Dinner": return "fork.knife"
        case "Sightseeing": return "binoculars.fill"
        default: return "star.fill"
        }
    }
    
    var categoryColor: Color {
        switch happening.category {
        case "Meetup": return .blue
        case "Party": return .purple
        case "Day Trip": return .green
        case "Pub Crawl": return .orange
        case "Dinner": return .red
        case "Sightseeing": return .cyan
        default: return .gray
        }
    }
    
    var isAttending: Bool {
        guard let userId = currentUserId else { return false }
        return happening.attendeeIds.contains(userId)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Category Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: categoryIcon)
                    .foregroundColor(categoryColor)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(happening.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Attendee badge
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                        Text("\(happening.attendeeIds.count)")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.2))
                    .clipShape(Capsule())
                }
                
                HStack(spacing: 8) {
                    Label(happening.city, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if isAttending {
                        Label("Joined", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Label(
                    happening.dateTime.formatted(date: .abbreviated, time: .shortened),
                    systemImage: "calendar"
                )
                .font(.caption)
                .foregroundColor(.secondary)
                
                if !happening.description.isEmpty {
                    Text(happening.description)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                
                // Status badges
                HStack(spacing: 8) {
                    Text(happening.category)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.15))
                        .clipShape(Capsule())
                    
                    if happening.isFull {
                        Text("Full")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HappeningsListView()
        .environmentObject(AuthenticationManager())
}
