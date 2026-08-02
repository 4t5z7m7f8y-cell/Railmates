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
            let docRef = try db.collection("happenings").addDocument(from: happening)
            
            // Schedule reminder for creator
            Task {
                await NotificationManager.shared.scheduleHappeningReminder(for: happening)
            }
            
            print("✅ Created happening with ID: \(docRef.documentID)")
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
                print("Error deleting happening: \(error)")
            }
        }
    }
}
