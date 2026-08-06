//
//  ContentView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var store = LocationTipStore()
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showingAddSheet = false
    @State private var selectedRadius: Double = 0
    @State private var viewMode: ViewMode = .list
    @State private var searchText = ""

    enum ViewMode: String, CaseIterable {
        case list = "List"
        case map = "Map"
    }

    let radiusOptions: [(label: String, value: Double)] = [
        ("All", 0),
        ("Within 10 km", 10),
        ("Within 50 km", 50),
        ("Within 100 km", 100),
        ("Within 500 km", 500)
    ]

    var sortedTips: [LocationTip] {
        let base: [LocationTip]
        if let userLocation = locationManager.currentLocation {
            let sorted = store.tips.sorted {
                $0.distance(from: userLocation) < $1.distance(from: userLocation)
            }
            base = selectedRadius == 0 ? sorted : sorted.filter {
                $0.distance(from: userLocation) <= selectedRadius * 1000
            }
        } else {
            base = store.tips
        }
        if searchText.isEmpty { return base }
        return base.filter { tip in
            tip.title.localizedCaseInsensitiveContains(searchText) ||
            tip.locationName.localizedCaseInsensitiveContains(searchText) ||
            tip.description.localizedCaseInsensitiveContains(searchText) ||
            tip.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.tips.isEmpty {
                    ContentUnavailableView(
                        "No Tips Yet",
                        systemImage: "mappin.and.ellipse",
                        description: Text("Be the first to share a location tip with fellow interrailers!")
                    )
                } else if sortedTips.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "Nothing Nearby" : "No Results",
                        systemImage: searchText.isEmpty ? "location.slash" : "magnifyingglass",
                        description: Text(searchText.isEmpty ? "Try a wider radius" : "Try a different search term")
                    )
                } else if viewMode == .list {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(sortedTips) { tip in
                                NavigationLink {
                                    TipDetailView(tip: tip, store: store)
                                } label: {
                                    TipCard(
                                        tip: tip,
                                        distanceText: locationManager.currentLocation.map {
                                            formattedDistance(tip.distance(from: $0))
                                        }
                                    )
                                    .appCard()
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    if tip.createdBy == authManager.user?.id, let tipId = tip.id {
                                        Button(role: .destructive) {
                                            store.delete(tipId: tipId)
                                        } label: {
                                            Label("Delete Tip", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                } else {
                    MapTipView(tips: sortedTips)
                }
            }
            .navigationTitle("Tips")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search by city, category...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Radius", selection: $selectedRadius) {
                            ForEach(radiusOptions, id: \.value) { option in
                                Text(option.label).tag(option.value)
                            }
                        }
                    } label: {
                        Label(currentRadiusLabel, systemImage: "slider.horizontal.3")
                            .foregroundColor(.appGreen)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Picker("View", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.appGreen)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddLocationTipView(userId: authManager.user?.id) { newTip in
                    store.add(newTip)
                }
            }
            .onAppear {
                store.fetchAll()
                locationManager.requestPermission()
            }
        }
    }

    var currentRadiusLabel: String {
        radiusOptions.first { $0.value == selectedRadius }?.label ?? "All"
    }

    func formattedDistance(_ meters: CLLocationDistance) -> String {
        meters < 1000
            ? "\(Int(meters)) m away"
            : String(format: "%.1f km away", meters / 1000)
    }
}

// MARK: - Tip Card (card layout replacing TipRow)
struct TipCard: View {
    let tip: LocationTip
    let distanceText: String?

    var categoryIcon: String {
        switch tip.category {
        case "Hostel": return "building.2.fill"
        case "Hotel": return "bed.double.fill"
        case "Food": return "fork.knife"
        case "Activity": return "figure.walk"
        case "Sight": return "camera.fill"
        case "Station Tip": return "train.side.front.car"
        default: return "mappin.circle.fill"
        }
    }

    var categoryColor: Color {
        switch tip.category {
        case "Food": return .appOchre
        case "Station Tip": return .appBrown
        case "Activity": return .appGreen
        case "Sight": return Color(red: 0.20, green: 0.40, blue: 0.80)
        case "Hostel": return .indigo
        case "Hotel": return .purple
        default: return .appGreen
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: categoryIcon)
                        .foregroundColor(categoryColor)
                        .font(.subheadline)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(tip.title)
                        .font(.headline)

                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(tip.locationName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(tip.category)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(categoryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Description
            Text(tip.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            // Footer stats
            HStack(spacing: 12) {
                if tip.ratingCount > 0 {
                    Label(String(format: "%.1f", tip.averageRating), systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.appOchre)
                }
                if tip.likeCount > 0 {
                    Label("\(tip.likeCount)", systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.pink.opacity(0.8))
                }
                Spacer()
                if let distanceText {
                    Text(distanceText)
                        .font(.caption)
                        .foregroundColor(categoryColor)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(16)
    }
}

// Keep TipRow as an alias for use in HomeView/SavedView
typealias TipRow = TipCard

#Preview {
    ContentView()
}
