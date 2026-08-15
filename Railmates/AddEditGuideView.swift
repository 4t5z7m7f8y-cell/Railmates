import SwiftUI
import CoreLocation

struct AddEditGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager

    var existingGuide: Guide?
    var onSave: (Guide) -> Void

    @State private var title = ""
    @State private var content = ""
    @State private var category = Guide.categories[0]
    @State private var country = ""

    var isEditing: Bool { existingGuide != nil }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !content.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Guide Details") {
                    TextField("Title", text: $title)

                    Picker("Category", selection: $category) {
                        ForEach(Guide.categories, id: \.self) { cat in
                            HStack {
                                Image(systemName: Guide.categoryIcon(cat))
                                    .foregroundColor(Guide.categoryColor(cat))
                                Text(cat)
                            }
                            .tag(cat)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section {
                    TextField("Country or region (optional)", text: $country)
                        .autocorrectionDisabled()
                } header: {
                    Text("Location")
                } footer: {
                    Text("Leave blank for a general guide that applies to all of Europe.")
                }

                Section {
                    TextField(
                        "Write your guide here...",
                        text: $content,
                        axis: .vertical
                    )
                    .lineLimit(10...40)
                } header: {
                    Text("Content")
                } footer: {
                    Text("Include step-by-step instructions, tips, and any practical info others might need.")
                }
            }
            .navigationTitle(isEditing ? "Edit Guide" : "New Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: populate)
        }
    }

    private func populate() {
        guard let g = existingGuide else { return }
        title = g.title
        content = g.content
        category = g.category
        country = g.country
    }

    private func save() {
        var guide = existingGuide ?? Guide(
            title: "",
            content: "",
            category: category,
            createdBy: authManager.user?.id,
            authorName: authManager.user?.displayName ?? ""
        )
        guide.title    = title.trimmingCharacters(in: .whitespaces)
        guide.content  = content.trimmingCharacters(in: .whitespaces)
        guide.category = category
        guide.country  = country.trimmingCharacters(in: .whitespaces)
        guide.updatedAt = Date()

        let trimmedCountry = guide.country
        if !trimmedCountry.isEmpty {
            CLGeocoder().geocodeAddressString(trimmedCountry) { placemarks, _ in
                if let loc = placemarks?.first?.location {
                    guide.latitude  = loc.coordinate.latitude
                    guide.longitude = loc.coordinate.longitude
                }
                onSave(guide)
            }
        } else {
            onSave(guide)
        }
        dismiss()
    }
}
