//
//  LocationTipStore.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//
import Foundation
import FirebaseFirestore
import Combine

class LocationTipStore: ObservableObject {
    @Published var tips: [LocationTip] = []

    private let db = Firestore.firestore()

    func fetchAll() {
        db.collection("locationTips")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching tips: \(error)")
                    return
                }
                self.tips = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: LocationTip.self)
                } ?? []
            }
    }

    func add(_ tip: LocationTip) {
        do {
            _ = try db.collection("locationTips").addDocument(from: tip)
        } catch {
            print("Error adding tip: \(error)")
        }
    }

    func delete(tipId: String) {
        db.collection("locationTips").document(tipId).delete { error in
            if let error = error {
                print("Error deleting tip: \(error)")
            }
        }
    }

    func deleteComment(tipId: String, commentId: String) {
        db.collection("locationTips").document(tipId).collection("comments").document(commentId).delete { error in
            if let error = error {
                print("Error deleting comment: \(error)")
            }
        }
    }

    func addRating(tipId: String, rating: Int) {
        let tipRef = db.collection("locationTips").document(tipId)
        tipRef.updateData([
            "ratingSum": FieldValue.increment(Int64(rating)),
            "ratingCount": FieldValue.increment(Int64(1))
        ])
    }

    func toggleLike(tipId: String, userId: String) {
        let tipRef = db.collection("locationTips").document(tipId)
        if let tip = tips.first(where: { $0.id == tipId }),
           tip.likedBy.contains(userId) {
            tipRef.updateData(["likedBy": FieldValue.arrayRemove([userId])])
        } else {
            tipRef.updateData(["likedBy": FieldValue.arrayUnion([userId])])
        }
    }

    func addComment(tipId: String, text: String, authorId: String? = nil, authorName: String? = nil) {
        let comment = Comment(text: text, authorId: authorId, authorName: authorName)
        do {
            _ = try db.collection("locationTips").document(tipId).collection("comments").addDocument(from: comment)
        } catch {
            print("Error adding comment: \(error)")
        }
    }

    func fetchComments(tipId: String, completion: @escaping ([Comment]) -> Void) {
        db.collection("locationTips").document(tipId).collection("comments")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching comments: \(error)")
                    completion([])
                    return
                }
                let comments = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Comment.self)
                } ?? []
                completion(comments)
            }
    }
}
