//
//  EditHappeningView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import SwiftUI
import MapKit

struct EditHappeningView: View {
    @Environment(\.dismiss) private var dismiss
    let happening: Happening
    let userId: String
    var onSave: (Happening) -> Void
    
    @State private var title: String
    @State private var description: String
    @State private var city: String
    @State private var locationName: String
    @State private var category: String
    @State private var dateTime: Date
    @State private var maxAttendees: String
    @State private var hasMaxAttendees: Bool
    @State private var isSaving = false
    
    let categories = ["Meetup", "Party", "Day Trip", "Pub Crawl", "Dinner", "Sightseeing", "Other"]
    
    init(happening: Happening, userId: String, onSave: @escaping (Happening) -> Void) {
        self.happening = happening
        self.userId = userId
        self.onSave = onSave
        
        _title = State(initialValue: happening.title)
        _description = State(initialValue: happening.description)
        _city = State(initialValue: happening.city)
        _locationName = State(initialValue: happening.locationName ?? "")
        _category = State(initialValue: happening.category)
        _dateTime = State(initialValue: happening.dateTime)
        _hasMaxAttendees = State(initialValue: happening.maxAttendees != nil)
        _maxAttendees = State(initialValue: happening.maxAttendees.map { "\($0)" } ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $title)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Location") {
                    TextField("City", text: $city)
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
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        saveChanges()
                    }
                    .disabled(title.isEmpty || city.isEmpty || isSaving)
                }
            }
        }
    }
    
    func saveChanges() {
        isSaving = true
        
        let locationToGeocode = locationName.isEmpty ? city : "\(locationName), \(city)"
        
        geocode(locationName: locationToGeocode) { coordinate in
            DispatchQueue.main.async {
                let maxCount = hasMaxAttendees ? Int(maxAttendees) : nil
                
                var updated = happening
                updated.title = title
                updated.description = description
                updated.city = city
                updated.locationName = locationName.isEmpty ? nil : locationName
                
                // Only update coordinates if geocoding succeeded
                if let coord = coordinate {
                    updated.latitude = coord.latitude
                    updated.longitude = coord.longitude
                }
                
                updated.dateTime = dateTime
                updated.maxAttendees = maxCount
                updated.category = category
                
                onSave(updated)
                isSaving = false
                dismiss()
            }
        }
    }
}
