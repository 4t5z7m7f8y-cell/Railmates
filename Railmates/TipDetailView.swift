//
//  TipDetailView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//
import SwiftUI

struct TipDetailView: View {
    let tip: LocationTip
    @ObservedObject var store: LocationTipStore
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager

    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var selectedRating = 0
    @State private var showingDeleteAlert = false

    var isOwner: Bool {
        tip.createdBy != nil && tip.createdBy == authManager.user?.id
    }

    var currentTip: LocationTip {
        store.tips.first(where: { $0.id == tip.id }) ?? tip
    }

    var isLiked: Bool {
        guard let userId = authManager.user?.id else { return false }
        return currentTip.likedBy.contains(userId)
    }

    var isSaved: Bool {
        guard let tipId = tip.id else { return false }
        return authManager.user?.savedTipIds?.contains(tipId) ?? false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(tip.title)
                        .font(.title2)
                        .bold()

                    Text(tip.locationName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(tip.description)
                        .font(.body)

                    Text(tip.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(Capsule())

                    // Category-specific fields
                    if let stationName = tip.stationName, !stationName.isEmpty {
                        Label(stationName, systemImage: "train.side.front.car")
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }

                    if let hasStorage = tip.hasLuggageStorage, hasStorage {
                        Label("Luggage storage available", systemImage: "suitcase.fill")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.top, 4)
                    }

                    if let info = tip.practicalInfo, !info.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Text("💡")
                                .font(.subheadline)
                            Text(info)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }

                // Like + save action bar
                HStack(spacing: 12) {
                    Button {
                        toggleLike()
                    } label: {
                        Label("\(currentTip.likeCount)", systemImage: isLiked ? "heart.fill" : "heart")
                            .font(.subheadline)
                            .foregroundColor(isLiked ? .red : .secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isLiked ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    Button {
                        toggleSave()
                    } label: {
                        Label(isSaved ? "Saved" : "Save", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.subheadline)
                            .foregroundColor(isSaved ? .blue : .secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSaved ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    Spacer()
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Rating")
                        .font(.headline)

                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(tip.averageRating.rounded()) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                        }
                        Text(String(format: "%.1f (%d)", tip.averageRating, tip.ratingCount))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text("Rate this tip")
                        .font(.subheadline)
                        .padding(.top, 4)

                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    selectedRating = star
                                    if let tipId = tip.id {
                                        store.addRating(tipId: tipId, rating: star)
                                    }
                                }
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Comments")
                        .font(.headline)

                    HStack {
                        TextField("Add a comment...", text: $newCommentText)
                            .textFieldStyle(.roundedBorder)
                        Button("Post") {
                            postComment()
                        }
                        .disabled(newCommentText.isEmpty)
                    }

                    if comments.isEmpty {
                        Text("No comments yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(comments) { comment in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    if let name = comment.authorName {
                                        Text(name)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(comment.text)
                                    Text(comment.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                if isOwner, let tipId = tip.id, let commentId = comment.id {
                                    Spacer()
                                    Button {
                                        store.deleteComment(tipId: tipId, commentId: commentId)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Tip Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOwner {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .alert("Delete Tip", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let tipId = tip.id {
                    store.delete(tipId: tipId)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this tip? This can't be undone.")
        }
        .onAppear {
            loadComments()
        }
    }

    func loadComments() {
        guard let tipId = tip.id else { return }
        store.fetchComments(tipId: tipId) { fetchedComments in
            comments = fetchedComments
        }
    }

    func postComment() {
        guard let tipId = tip.id, !newCommentText.isEmpty else { return }
        store.addComment(
            tipId: tipId,
            text: newCommentText,
            authorId: authManager.user?.id,
            authorName: authManager.user?.displayName
        )
        newCommentText = ""
    }

    func toggleLike() {
        guard let tipId = tip.id, let userId = authManager.user?.id else { return }
        store.toggleLike(tipId: tipId, userId: userId)
    }

    func toggleSave() {
        guard let tipId = tip.id else { return }
        Task { await authManager.toggleSavedTip(tipId) }
    }
}
