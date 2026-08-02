//
//  AddHappeningView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import SwiftUI
import CoreLocation

struct AddHappeningView: View {
    @Environment(\.dismiss) private var dismiss
    let userId: String
    var onSave: (Happening) -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var city = ""
    @State private var locationName = ""
    @State private var category = "Meetup"
    @State private var dateTime = Date().addingTimeInterval(3600) // 1 hour from now
    @State private var maxAttendees = ""
    @State private var hasMaxAttendees = false
    @State private var isSaving = false
    
    let categories = ["Meetup", "Party", "Day Trip", "Pub Crawl", "Dinner", "Sightseeing", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Title (e.g. Pub crawl in Prague)", text: $title)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Location") {
                    TextField("City (e.g. Berlin, Germany)", text: $city)
                    
                    TextField("Meeting point (optional)", text: $locationName)
                }
                
                Section("When") {
                    DatePicker(
                        "Date & Time",
                        selection: $dateTime,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                Section("Capacity") {
                    Toggle("Limit attendees", isOn: $hasMaxAttendees)
                    
                    if hasMaxAttendees {
                        TextField("Max attendees", text: $maxAttendees)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("New Happening")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Creating..." : "Create") {
                        saveHappening()
                    }
                    .disabled(title.isEmpty || city.isEmpty || isSaving)
                }
            }
        }
    }
    
    func saveHappening() {
        isSaving = true
        
        let locationToGeocode = locationName.isEmpty ? city : "\(locationName), \(city)"
        
        geocode(locationName: locationToGeocode) { coordinate in
            DispatchQueue.main.async {
                let maxCount = hasMaxAttendees ? Int(maxAttendees) : nil
                
                let newHappening = Happening(
                    title: title,
                    description: description,
                    city: city,
                    locationName: locationName.isEmpty ? nil : locationName,
                    latitude: coordinate?.latitude ?? 0,
                    longitude: coordinate?.longitude ?? 0,
                    dateTime: dateTime,
                    createdBy: userId,
                    attendeeIds: [userId], // Creator auto-joins
                    maxAttendees: maxCount,
                    category: category
                )
                
                onSave(newHappening)
                isSaving = false
                dismiss()
            }
        }
    }
}

#Preview {
    AddHappeningView(userId: "test-user-id") { _ in }
}
