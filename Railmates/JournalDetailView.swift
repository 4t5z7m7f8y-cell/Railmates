//
//  JournalDetailView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import SwiftUI
import PhotosUI
import FirebaseStorage
import MapKit

struct JournalDetailView: View {
    let journal: Journal
    @ObservedObject var store: JournalStore
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var entries: [JournalEntry] = []
    @State private var showingAddEntry = false
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    @State private var showingShareSheet = false
    
    var isOwner: Bool {
        authManager.user?.id == journal.createdBy
    }
    
    var creatorName: String? {
        store.creatorNames[journal.createdBy]
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(journal.startDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let end = journal.endDate {
                            Text("→")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(end.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if journal.isOngoing {
                            Text("Ongoing")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(journal.title)
                        .font(.title)
                        .bold()
                    
                    // Show creator name
                    if let name = creatorName {
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle.fill")
                                .font(.caption)
                            Text(name)
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    if !journal.description.isEmpty {
                        Text(journal.description)
                            .font(.body)
                    }
                    
                    if !journal.countries.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                                .font(.caption)
                            Text(journal.countries.joined(separator: ", "))
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Text("\(journal.duration) • \(entries.count) entr\(entries.count == 1 ? "y" : "ies")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Entries
                if entries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "map")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No entries yet")
                            .font(.headline)
                        if isOwner {
                            Text("Tap + to add your first stop")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Journey")
                            .font(.headline)
                        
                        ForEach(entries) { entry in
                            JournalEntryCard(entry: entry)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Share button (for everyone)
            if !isOwner && journal.isPublic {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            
            if isOwner {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showingShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        
                        Button {
                            showingAddEntry = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        
                        Menu {
                            Button {
                                showingEditSheet = true
                            } label: {
                                Label("Edit Journal", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Journal", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            AddJournalEntryView(journalId: journal.id ?? "") { newEntry in
                store.addEntry(newEntry, to: journal.id ?? "")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditJournalView(journal: journal) { updatedJournal in
                store.update(updatedJournal)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if journal.isPublic {
                ShareSheet(items: [createShareText()])
            }
        }
        .alert("Delete Journal", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let id = journal.id {
                    store.delete(journalId: id)
                }
            }
        } message: {
            Text("Are you sure you want to delete this journal? This can't be undone.")
        }
        .onAppear {
            if let journalId = journal.id {
                store.fetchEntries(journalId: journalId) { fetchedEntries in
                    entries = fetchedEntries
                }
            }
        }
    }
    
    func createShareText() -> String {
        var text = "Check out this travel journal on Railmates!\n\n"
        text += "📖 \(journal.title)\n"
        if let name = creatorName {
            text += "✍️ by \(name)\n"
        }
        text += "📅 \(journal.duration)\n"
        if !journal.countries.isEmpty {
            text += "🌍 \(journal.countries.joined(separator: ", "))\n"
        }
        if !journal.description.isEmpty {
            text += "\n\(journal.description)\n"
        }
        text += "\n\(entries.count) entr\(entries.count == 1 ? "y" : "ies") documenting this amazing journey!"
        return text
    }
}

struct JournalEntryCard: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label(entry.city, systemImage: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Text(entry.title)
                .font(.headline)
            
            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            if !entry.photoURLs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(entry.photoURLs, id: \.self) { urlString in
                            if let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 90)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    case .failure:
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 120, height: 90)
                                            .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                                    default:
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 120, height: 90)
                                            .overlay(ProgressView())
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct AddJournalEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let journalId: String
    var onSave: (JournalEntry) -> Void

    @State private var title = ""
    @State private var notes = ""
    @State private var city = ""
    @State private var country = ""
    @State private var date = Date()
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoData: [Data] = []
    @State private var isDetectingCountry = false
    @State private var autoDetectedCountry = ""
    @State private var isUploading = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Entry Details") {
                    TextField("Title (e.g. Arrived in Paris!)", text: $title)
                    TextField("City", text: $city)
                    HStack {
                        TextField("Country", text: $country)
                        if isDetectingCountry {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Notes") {
                    TextField("What did you do? What did you see?", text: $notes, axis: .vertical)
                        .lineLimit(5...10)
                }

                Section {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        Label("Add Photos (up to 5)", systemImage: "photo.on.rectangle.angled")
                    }

                    if !photoData.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(photoData.indices, id: \.self) { index in
                                    if let uiImage = UIImage(data: photoData[index]) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                            Button {
                                                withAnimation {
                                                    photoData.remove(at: index)
                                                    selectedPhotos.remove(at: index)
                                                }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.title3)
                                                    .foregroundStyle(.white)
                                                    .background(
                                                        Circle()
                                                            .fill(.black.opacity(0.6))
                                                            .frame(width: 24, height: 24)
                                                    )
                                            }
                                            .offset(x: 8, y: -8)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }

                        Text("\(photoData.count) photo\(photoData.count == 1 ? "" : "s") selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Photos")
                } footer: {
                    Text(photoData.isEmpty ? "Add photos to capture this moment" : "Tap X to remove a photo")
                        .font(.caption)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isUploading ? "Uploading..." : "Save") {
                        Task {
                            isUploading = true
                            let photoURLs = await uploadPhotos()
                            let entry = JournalEntry(
                                journalId: journalId,
                                city: city,
                                country: country,
                                date: date,
                                title: title,
                                notes: notes,
                                photoURLs: photoURLs
                            )
                            onSave(entry)
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty || city.isEmpty || isUploading)
                }
            }
            .onChange(of: selectedPhotos) { oldValue, newValue in
                Task {
                    photoData = []
                    for photo in newValue {
                        if let data = try? await photo.loadTransferable(type: Data.self) {
                            photoData.append(data)
                        }
                    }
                }
            }
            // Debounced country auto-detection: fires 700ms after city stops changing
            .task(id: city) {
                let trimmed = city.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                try? await Task.sleep(for: .milliseconds(700))
                guard !Task.isCancelled else { return }
                await detectCountry(for: trimmed)
            }
        }
    }

    // Geocodes city name and fills country only if the user hasn't manually overridden it
    private func detectCountry(for cityName: String) async {
        await MainActor.run { isDetectingCountry = true }
        do {
            guard let request = MKGeocodingRequest(addressString: cityName) else {
                await MainActor.run { isDetectingCountry = false }
                return
            }
            let mapItems = try await request.mapItems
            let detected: String?
            if #available(iOS 26, *) {
                detected = mapItems.first?.addressRepresentations?.regionName
            } else {
                detected = mapItems.first?.placemark.country
            }
            if let detected {
                await MainActor.run {
                    if country.isEmpty || country == autoDetectedCountry {
                        country = detected
                        autoDetectedCountry = detected
                    }
                    isDetectingCountry = false
                }
                return
            }
        } catch {}
        await MainActor.run { isDetectingCountry = false }
    }

    // Compresses and uploads photos to Firebase Storage, returns download URLs
    private func uploadPhotos() async -> [String] {
        guard !photoData.isEmpty else { return [] }
        let storage = Storage.storage()
        var urls: [String] = []
        let timestamp = Int(Date().timeIntervalSince1970)
        for (index, data) in photoData.enumerated() {
            guard let compressed = UIImage(data: data)?.jpegData(compressionQuality: 0.7) else { continue }
            let path = "journals/\(journalId)/\(timestamp)_\(index).jpg"
            let ref = storage.reference().child(path)
            do {
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    ref.putData(compressed, metadata: metadata) { _, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
                let url: URL = try await withCheckedThrowingContinuation { continuation in
                    ref.downloadURL { url, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let url = url {
                            continuation.resume(returning: url)
                        } else {
                            continuation.resume(throwing: URLError(.badServerResponse))
                        }
                    }
                }
                urls.append(url.absoluteString)
            } catch {
                print("Photo upload failed for index \(index): \(error)")
            }
        }
        return urls
    }
}

// Edit existing journal
struct EditJournalView: View {
    @Environment(\.dismiss) private var dismiss
    let journal: Journal
    var onSave: (Journal) -> Void
    
    @State private var title: String
    @State private var description: String
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var isPublic: Bool
    @State private var countries: String
    @State private var isSaving = false
    
    init(journal: Journal, onSave: @escaping (Journal) -> Void) {
        self.journal = journal
        self.onSave = onSave
        
        _title = State(initialValue: journal.title)
        _description = State(initialValue: journal.description)
        _startDate = State(initialValue: journal.startDate)
        _hasEndDate = State(initialValue: journal.endDate != nil)
        _endDate = State(initialValue: journal.endDate ?? Date())
        _isPublic = State(initialValue: journal.isPublic)
        _countries = State(initialValue: journal.countries.joined(separator: ", "))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    TextField("Title", text: $title)
                    
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
            .navigationTitle("Edit Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        saveChanges()
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }
    
    func saveChanges() {
        isSaving = true
        
        let countriesList = countries
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var updatedJournal = journal
        updatedJournal.title = title
        updatedJournal.description = description
        updatedJournal.startDate = startDate
        updatedJournal.endDate = hasEndDate ? endDate : nil
        updatedJournal.isPublic = isPublic
        updatedJournal.countries = countriesList
        
        onSave(updatedJournal)
        isSaving = false
        dismiss()
    }
}

