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
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, description, countries
    }
    
    var isValid: Bool {
        !title.isEmpty && title.count >= 3
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title, prompt: Text("e.g. Summer Interrail 2026"))
                        .focused($focusedField, equals: .title)
                    
                    TextField("Description", text: $description, prompt: Text("What's this trip about?"), axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .description)
                } header: {
                    Text("Trip Details")
                } footer: {
                    if !title.isEmpty && title.count < 3 {
                        Text("Title must be at least 3 characters")
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    Toggle("Set End Date", isOn: $hasEndDate.animation(.spring()))
                    
                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                } header: {
                    Text("Dates")
                } footer: {
                    Text(hasEndDate ? "Your trip duration: \(calculateDuration())" : "Leave blank for ongoing trips")
                        .font(.caption)
                }
                
                Section {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        TextField("Countries", text: $countries, prompt: Text("e.g. France, Germany, Italy"))
                            .focused($focusedField, equals: .countries)
                    }
                } header: {
                    Text("Countries Visited")
                } footer: {
                    Text("Separate with commas")
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
                    
                    Text(isPublic ? "Other travelers can see and be inspired by your journey" : "Only you can see this journal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Privacy")
                }
            }
            .navigationTitle("New Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Creating..." : "Create") {
                        saveJournal()
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
            .onAppear {
                focusedField = .title
            }
        }
    }
    
    func calculateDuration() -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        let days = components.day ?? 0
        return "\(days) day\(days == 1 ? "" : "s")"
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
