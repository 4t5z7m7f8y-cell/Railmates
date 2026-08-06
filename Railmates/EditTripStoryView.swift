//
//  EditTripStoryView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-03.
//

import SwiftUI
import MapKit

struct EditTripStoryView: View {
    @Environment(\.dismiss) private var dismiss
    let story: TripStory
    var onSave: (TripStory) -> Void
    
    @State private var title: String
    @State private var storyText: String
    @State private var tripStart: Date
    @State private var tripEnd: Date
    @State private var visitedPlaces: [PlaceVisited]
    @State private var isPublic: Bool
    @State private var budgetEnabled: Bool
    @State private var budget: Int
    @State private var isSaving = false
    
    // Place editing
    @State private var showingAddPlace = false
    @State private var newCity = ""
    @State private var newCountry = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, story
    }
    
    init(story: TripStory, onSave: @escaping (TripStory) -> Void) {
        self.story = story
        self.onSave = onSave
        
        _title = State(initialValue: story.title)
        _storyText = State(initialValue: story.story)
        _tripStart = State(initialValue: story.tripStart)
        _tripEnd = State(initialValue: story.tripEnd)
        _visitedPlaces = State(initialValue: story.visitedPlaces)
        _isPublic = State(initialValue: story.isPublic)
        _budgetEnabled = State(initialValue: story.budget != nil)
        _budget = State(initialValue: story.budget ?? 500)
    }
    
    var isValid: Bool {
        !title.isEmpty && title.count >= 3 &&
        !storyText.isEmpty &&
        !visitedPlaces.isEmpty &&
        tripStart <= tripEnd
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .focused($focusedField, equals: .title)
                } header: {
                    Text("Story Title")
                } footer: {
                    if !title.isEmpty && title.count < 3 {
                        Text("Title must be at least 3 characters")
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    DatePicker("Start Date", selection: $tripStart, displayedComponents: .date)
                    DatePicker("End Date", selection: $tripEnd, in: tripStart..., displayedComponents: .date)
                } header: {
                    Text("Trip Dates")
                } footer: {
                    Text("Duration: \(calculateDuration())")
                        .font(.caption)
                }
                
                Section {
                    ForEach(visitedPlaces) { place in
                        HStack {
                            Text("\(place.order).")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            Text(place.displayName)
                            Spacer()
                            Button {
                                removePlace(place)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .onMove { from, to in
                        visitedPlaces.move(fromOffsets: from, toOffset: to)
                        reorderPlaces()
                    }
                    
                    Button {
                        showingAddPlace = true
                    } label: {
                        Label("Add Place", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Places Visited")
                } footer: {
                    if visitedPlaces.isEmpty {
                        Text("Add at least one place")
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    TextEditor(text: $storyText)
                        .frame(minHeight: 200)
                        .focused($focusedField, equals: .story)
                } header: {
                    Text("Your Story")
                } footer: {
                    Text("\(storyText.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Toggle("Add total budget", isOn: $budgetEnabled)
                    if budgetEnabled {
                        Stepper("€\(budget)", value: $budget, in: 0...20000, step: 50)
                    }
                } header: {
                    Text("Budget (optional)")
                } footer: {
                    Text("Total trip cost in EUR")
                        .font(.caption)
                }

                Section {
                    Toggle(isOn: $isPublic) {
                        HStack {
                            Image(systemName: isPublic ? "globe" : "lock.fill")
                                .foregroundColor(isPublic ? .blue : .orange)
                            Text(isPublic ? "Public" : "Private")
                        }
                    }
                } header: {
                    Text("Privacy")
                }
            }
            .navigationTitle("Edit Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        saveChanges()
                    }
                    .disabled(!isValid || isSaving)
                    .fontWeight(isValid ? .semibold : .regular)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddPlace) {
                AddPlaceView(
                    city: $newCity,
                    country: $newCountry,
                    onAdd: {
                        addPlace()
                        showingAddPlace = false
                    }
                )
            }
        }
    }
    
    func calculateDuration() -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: tripStart, to: tripEnd)
        let days = (components.day ?? 0) + 1
        return "\(days) day\(days == 1 ? "" : "s")"
    }
    
    func addPlace() {
        let order = visitedPlaces.count + 1
        let place = PlaceVisited(
            city: newCity.isEmpty ? nil : newCity,
            country: newCountry,
            order: order
        )
        visitedPlaces.append(place)
        newCity = ""
        newCountry = ""
    }
    
    func removePlace(_ place: PlaceVisited) {
        visitedPlaces.removeAll { $0.id == place.id }
        reorderPlaces()
    }
    
    func reorderPlaces() {
        for (index, _) in visitedPlaces.enumerated() {
            visitedPlaces[index].order = index + 1
        }
    }
    
    func saveChanges() {
        isSaving = true
        
        var updatedStory = story
        updatedStory.title = title
        updatedStory.story = storyText
        updatedStory.tripStart = tripStart
        updatedStory.tripEnd = tripEnd
        updatedStory.visitedPlaces = visitedPlaces
        updatedStory.isPublic = isPublic
        updatedStory.budget = budgetEnabled ? budget : nil
        
        onSave(updatedStory)
        isSaving = false
        dismiss()
    }
}

#Preview {
    EditTripStoryView(
        story: TripStory(
            title: "Test Story",
            story: "This is a test story with enough characters to pass validation.",
            createdBy: "test",
            isPublic: true,
            tripStart: Date(),
            tripEnd: Date()
        )
    ) { _ in }
}
