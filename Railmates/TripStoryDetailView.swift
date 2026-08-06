//
//  TripStoryDetailView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-03.
//

import SwiftUI

struct TripStoryDetailView: View {
    let story: TripStory
    @ObservedObject var store: TripStoryStore
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var hasIncrementedView = false
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""

    // Live version from store so likes update reactively without re-navigation
    var currentStory: TripStory {
        store.stories.first(where: { $0.id == story.id }) ?? story
    }

    var isOwner: Bool {
        authManager.user?.id == story.createdBy
    }

    var creatorName: String? {
        store.creatorNames[story.createdBy]
    }

    var isLiked: Bool {
        guard let userId = authManager.user?.id else { return false }
        return currentStory.likedBy.contains(userId)
    }

    var isSaved: Bool {
        guard let storyId = story.id else { return false }
        return authManager.user?.savedStoryIds?.contains(storyId) ?? false
    }

    var isFollowing: Bool {
        authManager.user?.following?.contains(story.createdBy) ?? false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Text(currentStory.title)
                        .font(.title)
                        .fontWeight(.bold)

                    HStack {
                        if let name = creatorName {
                            Label(name, systemImage: "person.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if !isOwner {
                                Button {
                                    Task { await authManager.toggleFollow(userId: story.createdBy) }
                                } label: {
                                    Text(isFollowing ? "Following" : "Follow")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(isFollowing ? .secondary : .white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(isFollowing ? Color(.systemFill) : Color.appGreen)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        Spacer()

                        if !currentStory.isPublic {
                            Label("Private", systemImage: "lock.fill")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .clipShape(Capsule())
                        }
                    }

                    // Trip info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text("\(currentStory.tripStart.formatted(date: .abbreviated, time: .omitted)) - \(currentStory.tripEnd.formatted(date: .abbreviated, time: .omitted))")
                                .font(.subheadline)
                            Text("•")
                            Text(currentStory.duration)
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)

                        if !currentStory.visitedPlaces.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "map.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text(currentStory.routeSummary)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }

                        if !currentStory.countriesVisited.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "globe")
                                    .font(.caption)
                                Text(currentStory.countriesVisited.joined(separator: ", "))
                                    .font(.subheadline)
                            }
                            .foregroundColor(.secondary)
                        }
                    }

                    // Engagement stats
                    HStack(spacing: 16) {
                        Label("\(currentStory.viewCount)", systemImage: "eye")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Label("\(currentStory.likeCount)", systemImage: isLiked ? "heart.fill" : "heart")
                            .font(.caption)
                            .foregroundColor(isLiked ? .red : .secondary)

                        Label("\(comments.count)", systemImage: "bubble.left")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if currentStory.photos.count > 0 {
                            Label("\(currentStory.photos.count)", systemImage: "photo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)

                Divider()

                // Story content
                Text(currentStory.story)
                    .font(.body)
                    .padding(.horizontal)

                // Photos
                if !currentStory.photos.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Photos")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(currentStory.photos.sorted { $0.order < $1.order }) { photo in
                            VStack(alignment: .leading, spacing: 8) {
                                AsyncImage(url: URL(string: photo.url)) { phase in
                                    switch phase {
                                    case .empty:
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 300)
                                            .overlay { ProgressView() }
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(maxHeight: 400)
                                            .clipped()
                                    case .failure:
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 300)
                                            .overlay {
                                                Image(systemName: "photo")
                                                    .foregroundColor(.gray)
                                            }
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                if let caption = photo.caption {
                                    Text(caption)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                }

                                if let location = photo.location {
                                    Label(location, systemImage: "mappin.circle")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        toggleLike()
                    } label: {
                        Label(isLiked ? "Liked" : "Like", systemImage: isLiked ? "heart.fill" : "heart")
                            .font(.headline)
                            .foregroundColor(isLiked ? .red : .primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isLiked ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        toggleSave()
                    } label: {
                        Label(isSaved ? "Saved" : "Save", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.headline)
                            .foregroundColor(isSaved ? .blue : .primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isSaved ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)

                Divider()

                // Comments section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Comments")
                        .font(.headline)
                        .padding(.horizontal)

                    HStack {
                        TextField("Add a comment...", text: $newCommentText)
                            .textFieldStyle(.roundedBorder)
                        Button("Post") {
                            postComment()
                        }
                        .disabled(newCommentText.isEmpty)
                    }
                    .padding(.horizontal)

                    if comments.isEmpty {
                        Text("No comments yet — be the first!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        ForEach(comments) { comment in
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        if let name = comment.authorName {
                                            Text(name)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.secondary)
                                        }
                                        Text(comment.text)
                                            .font(.subheadline)
                                        Text(comment.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if isOwner, let storyId = story.id, let commentId = comment.id {
                                        Button {
                                            store.deleteComment(storyId: storyId, commentId: commentId)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                Divider()
                                    .padding(.leading)
                            }
                        }
                    }
                }
                .padding(.bottom)
            }
            .padding(.vertical)
        }
        .navigationTitle("Trip Story")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOwner {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit Story", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Story", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTripStoryView(story: story) { updatedStory in
                store.update(updatedStory)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [createShareText()])
        }
        .alert("Delete Story", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let id = story.id {
                    store.delete(storyId: id)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this story? This can't be undone.")
        }
        .onAppear {
            if !hasIncrementedView, let id = story.id {
                store.incrementViews(storyId: id)
                hasIncrementedView = true
            }
            loadComments()
        }
    }

    func toggleLike() {
        guard let userId = authManager.user?.id, let storyId = story.id else { return }
        store.toggleLike(storyId: storyId, userId: userId)
    }

    func toggleSave() {
        guard let storyId = story.id else { return }
        Task { await authManager.toggleSavedStory(storyId) }
    }

    func loadComments() {
        guard let storyId = story.id else { return }
        store.fetchComments(storyId: storyId) { fetched in
            comments = fetched
        }
    }

    func postComment() {
        guard let storyId = story.id,
              let userId = authManager.user?.id,
              let userName = authManager.user?.displayName,
              !newCommentText.isEmpty else { return }
        store.addComment(storyId: storyId, text: newCommentText, authorId: userId, authorName: userName)
        newCommentText = ""
    }

    func createShareText() -> String {
        var text = "Check out this amazing trip story on Railmates!\n\n"
        text += "📖 \(currentStory.title)\n"
        if let name = creatorName {
            text += "✍️ by \(name)\n"
        }
        text += "🗓️ \(currentStory.duration)\n"
        if !currentStory.countriesVisited.isEmpty {
            text += "🌍 \(currentStory.countriesVisited.joined(separator: ", "))\n"
        }
        if !currentStory.visitedPlaces.isEmpty {
            text += "🗺️ Route: \(currentStory.routeSummary)\n"
        }
        text += "\n\(String(currentStory.story.prefix(200)))..."
        if currentStory.photos.count > 0 {
            text += "\n\n📸 \(currentStory.photos.count) photos"
        }
        return text
    }
}

#Preview {
    NavigationStack {
        TripStoryDetailView(
            story: TripStory(
                title: "Summer Interrail 2026",
                story: "This is my amazing trip story...",
                createdBy: "test",
                isPublic: true,
                tripStart: Date(),
                tripEnd: Date()
            ),
            store: TripStoryStore()
        )
        .environmentObject(AuthenticationManager())
    }
}
