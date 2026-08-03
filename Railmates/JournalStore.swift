//
//  JournalStore.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import Foundation
import Combine
import FirebaseFirestore

class JournalStore: ObservableObject {
    @Published var journals: [Journal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var creatorNames: [String: String] = [:] // userId -> displayName
    
    private let db = Firestore.firestore()
    
    // Fetch all public journals
    func fetchPublicJournals() {
        isLoading = true
        errorMessage = nil
        
        db.collection("journals")
            .whereField("isPublic", isEqualTo: true)
            .addSnapshotListener { snapshot, error in
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to load journals: \(error.localizedDescription)"
                    print("Error fetching journals: \(error)")
                    return
                }
                // Sort in memory instead of in query
                self.journals = (snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Journal.self)
                } ?? []).sorted { $0.createdAt > $1.createdAt }
                
                // Fetch creator names
                Task {
                    await self.fetchAllCreatorNames()
                }
            }
    }
    
    // Fetch user's own journals
    func fetchMyJournals(userId: String) {
        isLoading = true
        errorMessage = nil
        
        db.collection("journals")
            .whereField("createdBy", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to load your journals: \(error.localizedDescription)"
                    print("Error fetching journals: \(error)")
                    return
                }
                // Sort in memory instead of in query
                self.journals = (snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Journal.self)
                } ?? []).sorted { $0.createdAt > $1.createdAt }
                
                // Fetch creator names (in case viewing other users' journals too)
                Task {
                    await self.fetchAllCreatorNames()
                }
            }
    }
    
    func create(_ journal: Journal) {
        do {
            let docRef = try db.collection("journals").addDocument(from: journal)
            print("✅ Created journal with ID: \(docRef.documentID)")
        } catch {
            errorMessage = "Failed to create journal: \(error.localizedDescription)"
            print("Error creating journal: \(error)")
        }
    }
    
    func update(_ journal: Journal) {
        guard let journalId = journal.id else { return }
        
        do {
            try db.collection("journals").document(journalId).setData(from: journal, merge: true)
        } catch {
            errorMessage = "Failed to update journal: \(error.localizedDescription)"
            print("Error updating journal: \(error)")
        }
    }
    
    func delete(journalId: String) {
        db.collection("journals").document(journalId).delete() { error in
            if let error = error {
                self.errorMessage = "Failed to delete journal: \(error.localizedDescription)"
                print("Error deleting journal: \(error)")
            }
        }
    }
    
    // Journal Entries
    func fetchEntries(journalId: String, completion: @escaping ([JournalEntry]) -> Void) {
        db.collection("journals").document(journalId).collection("entries")
            .order(by: "date", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching entries: \(error)")
                    completion([])
                    return
                }
                let entries = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: JournalEntry.self)
                } ?? []
                completion(entries)
            }
    }
    
    func addEntry(_ entry: JournalEntry, to journalId: String) {
        do {
            _ = try db.collection("journals").document(journalId).collection("entries").addDocument(from: entry)
        } catch {
            errorMessage = "Failed to add entry: \(error.localizedDescription)"
            print("Error adding entry: \(error)")
        }
    }
    
    func deleteEntry(journalId: String, entryId: String) {
        db.collection("journals").document(journalId).collection("entries").document(entryId).delete() { error in
            if let error = error {
                self.errorMessage = "Failed to delete entry: \(error.localizedDescription)"
                print("Error deleting entry: \(error)")
            }
        }
    }
    
    // Fetch creator display name
    func fetchCreatorName(userId: String) async {
        // Skip if already cached
        if creatorNames[userId] != nil {
            return
        }
        
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let displayName = document.data()?["displayName"] as? String {
                await MainActor.run {
                    self.creatorNames[userId] = displayName
                }
            }
        } catch {
            print("Error fetching creator name: \(error)")
        }
    }
    
    // Fetch all creator names for current journals
    func fetchAllCreatorNames() async {
        let uniqueUserIds = Set(journals.map { $0.createdBy })
        await withTaskGroup(of: Void.self) { group in
            for userId in uniqueUserIds {
                group.addTask {
                    await self.fetchCreatorName(userId: userId)
                }
            }
        }
    }
}
