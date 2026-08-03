//
//  HappeningStore.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import Foundation
import Combine
import FirebaseFirestore

class HappeningStore: ObservableObject {
    @Published var happenings: [Happening] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func fetchUpcoming() {
        isLoading = true
        errorMessage = nil
        
        db.collection("happenings")
            .whereField("dateTime", isGreaterThan: Date())
            .order(by: "dateTime", descending: false)
            .addSnapshotListener { snapshot, error in
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to load events: \(error.localizedDescription)"
                    print("Error fetching happenings: \(error)")
                    return
                }
                self.happenings = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Happening.self)
                } ?? []
            }
    }
    
    func create(_ happening: Happening) {
        do {
            let docRef = try db.collection("happenings").addDocument(from: happening)
            
            // Schedule reminder for creator
            Task {
                await NotificationManager.shared.scheduleHappeningReminder(for: happening)
            }
            
            print("✅ Created happening with ID: \(docRef.documentID)")
        } catch {
            errorMessage = "Failed to create event: \(error.localizedDescription)"
            print("Error creating happening: \(error)")
        }
    }
    
    func join(happeningId: String, userId: String) {
        let happeningRef = db.collection("happenings").document(happeningId)
        
        happeningRef.updateData([
            "attendeeIds": FieldValue.arrayUnion([userId])
        ]) { error in
            if let error = error {
                self.errorMessage = "Failed to join event: \(error.localizedDescription)"
                print("Error joining happening: \(error)")
            } else {
                // Schedule reminder for this user
                happeningRef.getDocument { snapshot, _ in
                    if let happening = try? snapshot?.data(as: Happening.self) {
                        Task {
                            await NotificationManager.shared.scheduleHappeningReminder(for: happening)
                        }
                    }
                }
            }
        }
    }
    
    func leave(happeningId: String, userId: String) {
        let happeningRef = db.collection("happenings").document(happeningId)
        
        happeningRef.updateData([
            "attendeeIds": FieldValue.arrayRemove([userId])
        ]) { error in
            if let error = error {
                self.errorMessage = "Failed to leave event: \(error.localizedDescription)"
                print("Error leaving happening: \(error)")
            } else {
                // Cancel reminder for this user
                Task {
                    await NotificationManager.shared.cancelHappeningReminder(happeningId: happeningId)
                }
            }
        }
    }
    
    func delete(happeningId: String) {
        db.collection("happenings").document(happeningId).delete() { error in
            if let error = error {
                self.errorMessage = "Failed to delete event: \(error.localizedDescription)"
                print("Error deleting happening: \(error)")
            }
        }
    }
    
    func update(_ happening: Happening) {
        guard let happeningId = happening.id else { return }
        
        do {
            try db.collection("happenings").document(happeningId).setData(from: happening, merge: true)
        } catch {
            errorMessage = "Failed to update event: \(error.localizedDescription)"
            print("Error updating happening: \(error)")
        }
    }
    
    func fetchUsers(userIds: [String]) async -> [User] {
        var users: [User] = []
        
        for userId in userIds {
            do {
                let document = try await db.collection("users").document(userId).getDocument()
                if let user = try? document.data(as: User.self) {
                    users.append(user)
                }
            } catch {
                print("Error fetching user \(userId): \(error)")
            }
        }
        
        return users
    }
}
