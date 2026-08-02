//
//  AddLocationTipView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import SwiftUI
import CoreLocation

struct AddLocationTipView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (LocationTip) -> Void

    @State private var title = ""
    @State private var category = "Sight"
    @State private var description = ""
    @State private var locationName = ""
    @State private var isSaving = false

    // Category-specific fields
    @State private var stationName = ""
    @State private var hasLuggageStorage = false
    @State private var practicalInfo = ""

    let categories = ["Hostel", "Hotel", "Food", "Activity", "Sight", "Station Tip"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Tip Details") {
                    TextField("Title (e.g. Cozy hostel near station)", text: $title)

                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }

                    TextField("City / Location (e.g. Berlin, Germany)", text: $locationName)

                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                if category == "Station Tip" {
                    Section("Station Details") {
                        TextField("Station name (e.g. Berlin Hauptbahnhof)", text: $stationName)
                    }
                }

                if category == "Hostel" {
                    Section("Hostel Details") {
                        Toggle("Has luggage storage", isOn: $hasLuggageStorage)
                    }
                }

                Section("Practical Info (optional)") {
                    TextField("e.g. free wifi, avoid at night, lockers available", text: $practicalInfo, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("New Tip")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        saveTip()
                    }
                    .disabled(title.isEmpty || locationName.isEmpty || isSaving)
                }
            }
        }
    }

    func saveTip() {
        isSaving = true
        geocode(locationName: locationName) { coordinate in
            DispatchQueue.main.async {
                var newTip = LocationTip(
                    title: title,
                    category: category,
                    description: description,
                    locationName: locationName,
                    latitude: coordinate?.latitude ?? 0,
                    longitude: coordinate?.longitude ?? 0
                )

                if category == "Station Tip", !stationName.isEmpty {
                    newTip.stationName = stationName
                }
                if category == "Hostel" {
                    newTip.hasLuggageStorage = hasLuggageStorage
                }
                if !practicalInfo.isEmpty {
                    newTip.practicalInfo = practicalInfo
                }

                onSave(newTip)
                isSaving = false
                dismiss()
            }
        }
    }
}

#Preview {
    AddLocationTipView(onSave: { _ in })
}
