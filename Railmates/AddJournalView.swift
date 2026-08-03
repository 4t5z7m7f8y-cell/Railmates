//
//  AddJournalView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import SwiftUI

struct AddJournalView: View {
    @Environment(\.dismiss) private var dismiss
    let userId: String
    var onSave: (Journal) -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @State private var isPublic = true
    @State private var countries = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    TextField("Title (e.g. Summer Interrail 2026)", text: $title)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Dates") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    Toggle("Add End Date", isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }
                
                Section("Countries Visited") {
                    TextField("e.g. France, Germany, Italy", text: $countries)
                }
                
                Section("Privacy") {
                    Toggle("Public (visible to everyone)", isOn: $isPublic)
                    
                    Text(isPublic ? "Other travelers can see and be inspired by your journey" : "Only you can see this journal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Creating..." : "Create") {
                        saveJournal()
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }
    
    func saveJournal() {
        isSaving = true
        
        let countriesList = countries
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        let newJournal = Journal(
            title: title,
            description: description,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            createdBy: userId,
            isPublic: isPublic,
            countries: countriesList
        )
        
        onSave(newJournal)
        isSaving = false
        dismiss()
    }
}

#Preview {
    AddJournalView(userId: "test") { _ in }
}
