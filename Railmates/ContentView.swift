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
    @State private var showingAddSheet = false
    @State private var selectedRadius: Double = 0 // 0 means "All"
    @State private var viewMode: ViewMode = .list

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
        guard let userLocation = locationManager.currentLocation else {
            return store.tips
        }
        let sorted = store.tips.sorted {
            $0.distance(from: userLocation) < $1.distance(from: userLocation)
        }
        if selectedRadius == 0 {
            return sorted
        }
        let radiusInMeters = selectedRadius * 1000
        return sorted.filter { $0.distance(from: userLocation) <= radiusInMeters }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.tips.isEmpty {
                    ContentUnavailableView(
                        "No Tips Yet",
                        systemImage: "map.fill",
                        description: Text("Tap + to add the first location tip for fellow interrailers")
                    )
                } else if sortedTips.isEmpty {
                    ContentUnavailableView(
                        "Nothing Nearby",
                        systemImage: "location.slash",
                        description: Text("Try a wider radius to see more tips")
                    )
                } else if viewMode == .list {
                    List(sortedTips) { tip in
                        NavigationLink {
                            TipDetailView(tip: tip, store: store)
                        } label: {
                            TipRow(
                                tip: tip,
                                distanceText: locationManager.currentLocation.map {
                                    formattedDistance(tip.distance(from: $0))
                                }
                            )
                        }
                    }
                    .listStyle(.plain)
                } else {
                    MapTipView(tips: sortedTips)
                }
            }
            .navigationTitle("Railmates")
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
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddLocationTipView { newTip in
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
        if meters < 1000 {
            return "\(Int(meters)) m away"
        } else {
            let km = meters / 1000
            return String(format: "%.1f km away", km)
        }
    }
}

struct TipRow: View {
    let tip: LocationTip
    let distanceText: String?

    var categoryIcon: String {
        switch tip.category {
        case "Hotel": return "bed.double.fill"
        case "Food": return "fork.knife"
        case "Activity": return "figure.walk"
        case "Sight": return "camera.fill"
        default: return "mappin.circle.fill"
        }
    }

    var categoryColor: Color {
        switch tip.category {
        case "Hotel": return .purple
        case "Food": return .orange
        case "Activity": return .green
        case "Sight": return .blue
        default: return .gray
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: categoryIcon)
                    .foregroundColor(categoryColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.headline)

                Text(tip.locationName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(tip.description)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    if tip.ratingCount > 0 {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", tip.averageRating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let distanceText {
                        if tip.ratingCount > 0 {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(distanceText)
                            .font(.caption)
                            .foregroundColor(categoryColor)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
}
