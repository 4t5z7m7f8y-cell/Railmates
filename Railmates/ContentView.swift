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

    var sortedTips: [LocationTip] {
        guard let userLocation = locationManager.currentLocation else {
            return store.tips
        }
        return store.tips.sorted {
            $0.distance(from: userLocation) < $1.distance(from: userLocation)
        }
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
                } else {
                    List(sortedTips) { tip in
                        TipRow(
                            tip: tip,
                            distanceText: locationManager.currentLocation.map {
                                formattedDistance(tip.distance(from: $0))
                            }
                        )
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Railmates")
            .toolbar {
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

                if let distanceText {
                    Text(distanceText)
                        .font(.caption)
                        .foregroundColor(categoryColor)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
}
