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
    
    private let db = Firestore.firestore()
    
    func fetchUpcoming() {
        db.collection("happenings")
            .whereField("dateTime", isGreaterThan: Date())
            .order(by: "dateTime", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
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
            _ = try db.collection("happenings").addDocument(from: happening)
        } catch {
            print("Error creating happening: \(error)")
        }
    }
    
    func join(happeningId: String, userId: String) {
        let happeningRef = db.collection("happenings").document(happeningId)
        
        happeningRef.updateData([
            "attendeeIds": FieldValue.arrayUnion([userId])
        ]) { error in
            if let error = error {
                print("Error joining happening: \(error)")
            }
        }
    }
    
    func leave(happeningId: String, userId: String) {
        let happeningRef = db.collection("happenings").document(happeningId)
        
        happeningRef.updateData([
            "attendeeIds": FieldValue.arrayRemove([userId])
        ]) { error in
            if let error = error {
                print("Error leaving happening: \(error)")
            }
        }
    }
    
    func delete(happeningId: String) {
        db.collection("happenings").document(happeningId).delete() { error in
            if let error = error {
                print("Error deleting happening: \(error)")
            }
        }
    }
    
    func update(_ happening: Happening) {
        guard let happeningId = happening.id else { return }
        
        do {
            try db.collection("happenings").document(happeningId).setData(from: happening, merge: true)
        } catch {
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
