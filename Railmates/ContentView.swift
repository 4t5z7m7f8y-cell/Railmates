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
                        systemImage: "map",
                        description: Text("Tap + to add the first location tip")
                    )
                } else {
                    List(sortedTips) { tip in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tip.title)
                                .font(.headline)
                            Text(tip.locationName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(tip.description)
                                .font(.body)
                                .lineLimit(2)

                            HStack {
                                Text(tip.category)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .clipShape(Capsule())

                                Spacer()

                                if let userLocation = locationManager.currentLocation {
                                    Text(formattedDistance(tip.distance(from: userLocation)))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
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
            return "\(Int(meters)) m"
        } else {
            let km = meters / 1000
            return String(format: "%.1f km", km)
        }
    }
}

#Preview {
    ContentView()
}
