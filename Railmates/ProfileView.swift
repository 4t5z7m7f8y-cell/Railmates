//
//  ProfileView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isEditingName = false
    @State private var newDisplayName = ""
    @State private var newCityName = ""
    @State private var showingAddCity = false
    
    var body: some View {
        NavigationStack {
            List {
                // User Info Section
                Section("Profile") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if isEditingName {
                                HStack {
                                    TextField("Display Name", text: $newDisplayName)
                                        .textFieldStyle(.roundedBorder)
                                    
                                    Button("Save") {
                                        saveDisplayName()
                                    }
                                    .disabled(newDisplayName.isEmpty)
                                }
                            } else {
                                Text(authManager.user?.displayName ?? "User")
                                    .font(.title2)
                                    .bold()
                                
                                Button("Edit Name") {
                                    newDisplayName = authManager.user?.displayName ?? ""
                                    isEditingName = true
                                }
                                .font(.caption)
                            }
                            
                            Text(authManager.user?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Favorite Cities Section
                Section {
                    if let cities = authManager.user?.favoriteCities, !cities.isEmpty {
                        ForEach(cities, id: \.self) { city in
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                Text(city)
                                
                                Spacer()
                                
                                Button {
                                    removeCity(city)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    } else {
                        Text("No favorite cities yet")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    
                    Button {
                        showingAddCity = true
                    } label: {
                        Label("Add Favorite City", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Favorite Cities")
                } footer: {
                    Text("Get notified about new happenings in these cities")
                        .font(.caption)
                }
                
                // Account Section
                Section("Account") {
                    Button(role: .destructive) {
                        authManager.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "arrow.right.circle.fill")
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingAddCity) {
                AddCitySheet(newCityName: $newCityName) {
                    addCity()
                }
            }
        }
    }
    
    func saveDisplayName() {
        Task {
            await authManager.updateDisplayName(newDisplayName)
            isEditingName = false
        }
    }
    
    func addCity() {
        guard !newCityName.isEmpty else { return }
        Task {
            await authManager.addFavoriteCity(newCityName)
            newCityName = ""
            showingAddCity = false
        }
    }
    
    func removeCity(_ city: String) {
        Task {
            await authManager.removeFavoriteCity(city)
        }
    }
}

struct AddCitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var newCityName: String
    var onAdd: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("City name (e.g. Berlin, Germany)", text: $newCityName)
                } header: {
                    Text("Add Favorite City")
                } footer: {
                    Text("You'll get notified about new happenings in this city")
                }
            }
            .navigationTitle("Favorite City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd()
                    }
                    .disabled(newCityName.isEmpty)
                }
            }
        }
        .presentationDetents([.height(200)])
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
}
