import Foundation
import FirebaseFirestore
import Combine

class GuideStore: ObservableObject {
    @Published var guides: [Guide] = []

    private let db = Firestore.firestore()

    func fetchAll() {
        db.collection("guides")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching guides: \(error)")
                    return
                }
                self.guides = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Guide.self)
                } ?? []
            }
    }

    func add(_ guide: Guide) {
        do {
            _ = try db.collection("guides").addDocument(from: guide)
        } catch {
            print("Error adding guide: \(error)")
        }
    }

    func update(_ guide: Guide) {
        guard let id = guide.id else { return }
        do {
            try db.collection("guides").document(id).setData(from: guide)
        } catch {
            print("Error updating guide: \(error)")
        }
    }

    func delete(guideId: String) {
        db.collection("guides").document(guideId).delete { error in
            if let error = error { print("Error deleting guide: \(error)") }
        }
    }

    func toggleLike(guideId: String, userId: String) {
        let ref = db.collection("guides").document(guideId)
        if let guide = guides.first(where: { $0.id == guideId }),
           guide.likedBy.contains(userId) {
            ref.updateData(["likedBy": FieldValue.arrayRemove([userId])])
        } else {
            ref.updateData(["likedBy": FieldValue.arrayUnion([userId])])
        }
    }

    func addComment(guideId: String, text: String, authorId: String?, authorName: String?) {
        let comment = Comment(text: text, authorId: authorId, authorName: authorName)
        do {
            _ = try db.collection("guides").document(guideId)
                .collection("comments").addDocument(from: comment)
        } catch {
            print("Error adding comment: \(error)")
        }
    }

    func fetchComments(guideId: String, completion: @escaping ([Comment]) -> Void) {
        db.collection("guides").document(guideId).collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching comments: \(error)")
                    completion([])
                    return
                }
                completion(snapshot?.documents.compactMap { try? $0.data(as: Comment.self) } ?? [])
            }
    }

    func deleteComment(guideId: String, commentId: String) {
        db.collection("guides").document(guideId)
            .collection("comments").document(commentId).delete { error in
                if let error = error { print("Error deleting comment: \(error)") }
            }
    }
}
