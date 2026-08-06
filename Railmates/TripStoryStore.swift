//
//  TripStoryStore.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-03.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class TripStoryStore: ObservableObject {
    @Published var stories: [TripStory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var creatorNames: [String: String] = [:]  // userId -> displayName
    
    private let db = Firestore.firestore()
    
    // MARK: - Fetch Stories
    
    func fetchPublicStories() {
        isLoading = true
        errorMessage = nil
        
        db.collection("tripStories")
            .whereField("isPublic", isEqualTo: true)
            .addSnapshotListener { snapshot, error in
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to load stories: \(error.localizedDescription)"
                    print("Error fetching stories: \(error)")
                    return
                }
                
                self.stories = (snapshot?.documents.compactMap { doc in
                    try? doc.data(as: TripStory.self)
                } ?? []).sorted { $0.createdAt > $1.createdAt }
                
                // Fetch creator names
                Task {
                    await self.fetchAllCreatorNames()
                }
            }
    }
    
    func fetchStoriesByUsers(userIds: [String]) {
        guard !userIds.isEmpty else {
            stories = []
            return
        }
        isLoading = true
        let ids = Array(userIds.prefix(30)) // Firestore `in` limit
        db.collection("tripStories")
            .whereField("isPublic", isEqualTo: true)
            .whereField("createdBy", in: ids)
            .addSnapshotListener { snapshot, error in
                self.isLoading = false
                if let error = error {
                    print("Error fetching following stories: \(error)")
                    return
                }
                self.stories = (snapshot?.documents.compactMap { try? $0.data(as: TripStory.self) } ?? [])
                    .sorted { $0.createdAt > $1.createdAt }
                Task { await self.fetchAllCreatorNames() }
            }
    }

    func fetchMyStories(userId: String) {
        isLoading = true
        errorMessage = nil
        
        db.collection("tripStories")
            .whereField("createdBy", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to load your stories: \(error.localizedDescription)"
                    print("Error fetching stories: \(error)")
                    return
                }
                
                self.stories = (snapshot?.documents.compactMap { doc in
                    try? doc.data(as: TripStory.self)
                } ?? []).sorted { $0.createdAt > $1.createdAt }
                
                Task {
                    await self.fetchAllCreatorNames()
                }
            }
    }
    
    func searchStories(query: String) {
        isLoading = true
        errorMessage = nil
        
        // Note: For production, consider using Algolia or Elasticsearch
        // Firestore array-contains only works for exact matches
        db.collection("tripStories")
            .whereField("isPublic", isEqualTo: true)
            .whereField("searchKeywords", arrayContains: query.lowercased())
            .addSnapshotListener { snapshot, error in
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Search failed: \(error.localizedDescription)"
                    return
                }
                
                self.stories = (snapshot?.documents.compactMap { doc in
                    try? doc.data(as: TripStory.self)
                } ?? []).sorted { $0.createdAt > $1.createdAt }
                
                Task {
                    await self.fetchAllCreatorNames()
                }
            }
    }
    
    // MARK: - CRUD Operations
    
    func create(_ story: TripStory) {
        do {
            let docRef = try db.collection("tripStories").addDocument(from: story)
            print("✅ Created trip story with ID: \(docRef.documentID)")
        } catch {
            errorMessage = "Failed to create story: \(error.localizedDescription)"
            print("Error creating story: \(error)")
        }
    }
    
    func update(_ story: TripStory) {
        guard let storyId = story.id else { return }
        
        var updatedStory = story
        updatedStory.updatedAt = Date()
        
        do {
            try db.collection("tripStories").document(storyId).setData(from: updatedStory, merge: true)
        } catch {
            errorMessage = "Failed to update story: \(error.localizedDescription)"
            print("Error updating story: \(error)")
        }
    }
    
    func delete(storyId: String) {
        db.collection("tripStories").document(storyId).delete() { error in
            if let error = error {
                self.errorMessage = "Failed to delete story: \(error.localizedDescription)"
                print("Error deleting story: \(error)")
            }
        }
    }
    
    // MARK: - Engagement
    
    func incrementViews(storyId: String) {
        db.collection("tripStories").document(storyId).updateData([
            "viewCount": FieldValue.increment(Int64(1))
        ])
    }
    
    func toggleLike(storyId: String, userId: String) {
        let storyRef = db.collection("tripStories").document(storyId)
        
        // Check if already liked
        if let story = stories.first(where: { $0.id == storyId }),
           story.likedBy.contains(userId) {
            // Unlike
            storyRef.updateData([
                "likeCount": FieldValue.increment(Int64(-1)),
                "likedBy": FieldValue.arrayRemove([userId])
            ])
        } else {
            // Like
            storyRef.updateData([
                "likeCount": FieldValue.increment(Int64(1)),
                "likedBy": FieldValue.arrayUnion([userId])
            ])
        }
    }
    
    // MARK: - Comments

    func fetchComments(storyId: String, completion: @escaping ([Comment]) -> Void) {
        db.collection("tripStories").document(storyId).collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching story comments: \(error)")
                    completion([])
                    return
                }
                let comments = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Comment.self)
                } ?? []
                completion(comments)
            }
    }

    func addComment(storyId: String, text: String, authorId: String, authorName: String) {
        let comment = Comment(text: text, authorId: authorId, authorName: authorName)
        do {
            _ = try db.collection("tripStories").document(storyId).collection("comments").addDocument(from: comment)
        } catch {
            errorMessage = "Failed to add comment: \(error.localizedDescription)"
        }
    }

    func deleteComment(storyId: String, commentId: String) {
        db.collection("tripStories").document(storyId).collection("comments").document(commentId).delete { error in
            if let error = error {
                print("Error deleting story comment: \(error)")
            }
        }
    }

    // MARK: - Creator Names
    
    func fetchCreatorName(userId: String) async {
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
    
    func fetchAllCreatorNames() async {
        let uniqueUserIds = Set(stories.map { $0.createdBy })
        await withTaskGroup(of: Void.self) { group in
            for userId in uniqueUserIds {
                group.addTask {
                    await self.fetchCreatorName(userId: userId)
                }
            }
        }
    }
}
