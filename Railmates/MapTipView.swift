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
