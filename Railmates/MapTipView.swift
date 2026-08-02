//
//  MapTipView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import SwiftUI
import MapKit

struct MapTipView: View {
    let tips: [LocationTip]
    @State private var selectedTip: LocationTip?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var hasSetInitialRegion = false

    var body: some View {
        Map(position: $cameraPosition, selection: $selectedTip) {
            UserAnnotation()

            ForEach(tips) { tip in
                Marker(tip.title, systemImage: categoryIcon(for: tip.category), coordinate: CLLocationCoordinate2D(latitude: tip.latitude, longitude: tip.longitude))
                    .tint(categoryColor(for: tip.category))
                    .tag(tip)
            }
        }
        .sheet(item: $selectedTip) { tip in
            TipDetailSheet(tip: tip)
                .presentationDetents([.height(220)])
        }
        .onAppear {
            if !hasSetInitialRegion {
                setInitialRegion()
                hasSetInitialRegion = true
            }
        }
    }

    func setInitialRegion() {
        guard !tips.isEmpty else { return }

        let coordinates = tips.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }

        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let minSpan = 0.5
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, minSpan),
            longitudeDelta: max((maxLon - minLon) * 1.5, minSpan)
        )

        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }

    func categoryIcon(for category: String) -> String {
        switch category {
        case "Hotel": return "bed.double.fill"
        case "Food": return "fork.knife"
        case "Activity": return "figure.walk"
        case "Sight": return "camera.fill"
        default: return "mappin.circle.fill"
        }
    }

    func categoryColor(for category: String) -> Color {
        switch category {
        case "Hotel": return .purple
        case "Food": return .orange
        case "Activity": return .green
        case "Sight": return .blue
        default: return .gray
        }
    }
}

struct TipDetailSheet: View {
    let tip: LocationTip

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tip.title)
                .font(.title3)
                .bold()
            Text(tip.locationName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(tip.description)
                .font(.body)
            Text(tip.category)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
