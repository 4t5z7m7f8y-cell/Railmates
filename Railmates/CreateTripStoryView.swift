//
//  CreateTripStoryView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-03.
//

import SwiftUI
import PhotosUI
import MapKit
import FirebaseStorage

struct CreateTripStoryView: View {
    @Environment(\.dismiss) private var dismiss
    let userId: String
    var onSave: (TripStory) -> Void
    
    @State private var title = ""
    @State private var story = ""
    @State private var tripStart = Date()
    @State private var tripEnd = Date()
    @State private var visitedPlaces: [PlaceVisited] = []
    @State private var isPublic = true
    @State private var isSaving = false
    @State private var uploadError: String?
    
    // Place input
    @State private var showingAddPlace = false
    @State private var newCity = ""
    @State private var newCountry = ""
    
    // Photos
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoData: [(data: Data, caption: String)] = []
    @State private var editingPhotoIndex: Int?
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, story, city, country, caption
    }
    
    var isValid: Bool {
        !title.isEmpty && title.count >= 3 &&
        !story.isEmpty &&
        !visitedPlaces.isEmpty &&
        tripStart <= tripEnd
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title, prompt: Text("e.g. My Summer Interrail Adventure"))
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
                            VStack(alignment: .leading, spacing: 2) {
                                Text(place.displayName)
                                    .font(.body)
                                if let city = place.city {
                                    Text(city)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
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
                        Text("Add at least one place you visited")
                            .foregroundColor(.red)
                    } else {
                        Text("Drag to reorder your route")
                            .font(.caption)
                    }
                }
                
                Section {
                    TextEditor(text: $story)
                        .frame(minHeight: 200)
                        .focused($focusedField, equals: .story)
                } header: {
                    Text("Your Story")
                } footer: {
                    Text("\(story.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 20,
                        matching: .images
                    ) {
                        Label("Add Photos (up to 20)", systemImage: "photo.on.rectangle.angled")
                    }
                    
                    if !photoData.isEmpty {
                        ForEach(photoData.indices, id: \.self) { index in
                            HStack(spacing: 12) {
                                if let uiImage = UIImage(data: photoData[index].data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Photo \(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Caption (optional)", text: $photoData[index].caption)
                                        .font(.subheadline)
                                }
                                
                                Spacer()
                                
                                Button {
                                    withAnimation {
                                        photoData.remove(at: index)
                                        selectedPhotos.remove(at: index)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        Text("\(photoData.count) photo\(photoData.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Photos")
                } footer: {
                    Text(photoData.isEmpty ? "Add photos to bring your story to life" : "Tap photo to add caption")
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
                    
                    Text(isPublic ? "Share your adventure with the world" : "Only you can see this story")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Privacy")
                }
            }
            .navigationTitle("Share Your Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Sharing..." : "Share Story") {
                        saveStory()
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
            .onChange(of: selectedPhotos) { oldValue, newValue in
                Task {
                    await loadPhotos(newValue)
                }
            }
            .onAppear {
                focusedField = .title
            }
            .alert("Photo Upload Failed", isPresented: .init(
                get: { uploadError != nil },
                set: { if !$0 { uploadError = nil } }
            )) {
                Button("OK") { uploadError = nil }
            } message: {
                Text(uploadError ?? "")
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
    
    func loadPhotos(_ items: [PhotosPickerItem]) async {
        photoData = []
        for photo in items {
            if let data = try? await photo.loadTransferable(type: Data.self) {
                photoData.append((data: data, caption: ""))
            }
        }
    }
    
    func saveStory() {
        isSaving = true
        Task {
            let (uploadedPhotos, firstError) = await uploadPhotos()
            if let error = firstError, uploadedPhotos.isEmpty {
                uploadError = error
                isSaving = false
                return
            }
            let newStory = TripStory(
                title: title,
                story: story,
                createdBy: userId,
                isPublic: isPublic,
                tripStart: tripStart,
                tripEnd: tripEnd,
                visitedPlaces: visitedPlaces,
                photos: uploadedPhotos
            )
            onSave(newStory)
            isSaving = false
            dismiss()
        }
    }

    private func uploadPhotos() async -> (photos: [StoryPhoto], firstError: String?) {
        guard !photoData.isEmpty else { return ([], nil) }
        let storage = Storage.storage()
        var result: [StoryPhoto] = []
        var firstError: String?
        let timestamp = Int(Date().timeIntervalSince1970)
        for (index, item) in photoData.enumerated() {
            guard let compressed = UIImage(data: item.data)?.jpegData(compressionQuality: 0.7) else { continue }
            let path = "tripStories/\(userId)/\(timestamp)_\(index).jpg"
            let ref = storage.reference().child(path)
            do {
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    ref.putData(compressed, metadata: metadata) { _, error in
                        if let error = error { continuation.resume(throwing: error) }
                        else { continuation.resume() }
                    }
                }
                let url: URL = try await withCheckedThrowingContinuation { continuation in
                    ref.downloadURL { url, error in
                        if let error = error { continuation.resume(throwing: error) }
                        else if let url = url { continuation.resume(returning: url) }
                        else { continuation.resume(throwing: URLError(.badServerResponse)) }
                    }
                }
                result.append(StoryPhoto(
                    url: url.absoluteString,
                    caption: item.caption.isEmpty ? nil : item.caption,
                    order: index
                ))
            } catch {
                print("Photo upload failed for index \(index): \(error)")
                if firstError == nil { firstError = error.localizedDescription }
            }
        }
        return (result, firstError)
    }
}

struct AddPlaceView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var city: String
    @Binding var country: String
    var onAdd: () -> Void
    
    @FocusState private var focusedField: Field?
    @State private var suggestedCountry: String?
    @State private var isLoadingCountry = false
    
    enum Field {
        case city, country
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("City (optional)", text: $city)
                        .focused($focusedField, equals: .city)
                        .onChange(of: city) { oldValue, newValue in
                            if !newValue.isEmpty && newValue.count >= 3 {
                                Task {
                                    await suggestCountry(for: newValue)
                                }
                            }
                        }
                    
                    if let suggested = suggestedCountry, country.isEmpty {
                        Button {
                            country = suggested
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Use: \(suggested)")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    TextField("Country", text: $country)
                        .focused($focusedField, equals: .country)
                } header: {
                    Text("Location")
                } footer: {
                    if isLoadingCountry {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Finding country...")
                                .font(.caption)
                        }
                    } else {
                        Text("Type a city name and we'll suggest the country")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd()
                    }
                    .disabled(country.isEmpty)
                }
            }
            .onAppear {
                focusedField = .city
            }
        }
    }
    
    func suggestCountry(for cityName: String) async {
        isLoadingCountry = true
        suggestedCountry = nil
        
        do {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = cityName
            request.resultTypes = .address
            
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            if let firstResult = response.mapItems.first {
                let detected: String?
                if #available(iOS 26, *) {
                    detected = firstResult.addressRepresentations?.regionName
                } else {
                    detected = firstResult.placemark.country
                }
                if let detected {
                    await MainActor.run {
                        self.suggestedCountry = detected
                        if self.country.isEmpty {
                            self.country = detected
                        }
                    }
                }
            }
        } catch {
            print("Geocoding error: \(error)")
        }
        
        isLoadingCountry = false
    }
}

#Preview {
    CreateTripStoryView(userId: "test") { _ in }
}
