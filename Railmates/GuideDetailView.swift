import SwiftUI

struct GuideDetailView: View {
    let guide: Guide
    @ObservedObject var store: GuideStore
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager

    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var currentGuide: Guide {
        store.guides.first(where: { $0.id == guide.id }) ?? guide
    }

    var isOwner: Bool {
        guide.createdBy != nil && guide.createdBy == authManager.user?.id
    }

    var isLiked: Bool {
        guard let userId = authManager.user?.id else { return false }
        return currentGuide.likedBy.contains(userId)
    }

    var isSaved: Bool {
        guard let guideId = guide.id else { return false }
        return authManager.user?.savedGuideIds?.contains(guideId) ?? false
    }

    private var color: Color { Guide.categoryColor(guide.category) }
    private var icon: String  { Guide.categoryIcon(guide.category) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .foregroundColor(color)
                        Text(guide.category)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(color.opacity(0.12))
                            .clipShape(Capsule())

                        if !guide.country.isEmpty {
                            Text(guide.country)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                        }
                    }

                    Text(guide.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 4) {
                        Image(systemName: "person.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(guide.authorName.isEmpty ? "Community" : guide.authorName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("·")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(guide.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Content
                Text(guide.content)
                    .font(.body)
                    .lineSpacing(4)

                Divider()

                // Like + save action bar
                HStack(spacing: 12) {
                    Button {
                        toggleLike()
                    } label: {
                        Label(
                            isLiked
                                ? (currentGuide.likeCount > 0 ? "\(currentGuide.likeCount) Liked" : "Liked")
                                : (currentGuide.likeCount > 0 ? "\(currentGuide.likeCount) Likes" : "Like"),
                            systemImage: isLiked ? "heart.fill" : "heart"
                        )
                        .font(.subheadline)
                        .foregroundColor(isLiked ? .red : .secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isLiked ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    Button {
                        Task { await authManager.toggleSavedGuide(guide.id ?? "") }
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

                // Comments
                commentsSection
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOwner {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit Guide", systemImage: "pencil")
                        }
                        Divider()
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Guide", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AddEditGuideView(existingGuide: currentGuide) { updated in
                store.update(updated)
            }
        }
        .alert("Delete Guide", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let id = guide.id {
                    store.delete(guideId: id)
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete your guide. This can't be undone.")
        }
        .onAppear {
            loadComments()
        }
    }

    @ViewBuilder
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Discussion")
                .font(.headline)

            HStack {
                TextField("Add a comment...", text: $newCommentText)
                    .textFieldStyle(.roundedBorder)
                Button("Post") {
                    postComment()
                }
                .disabled(newCommentText.isEmpty)
                .foregroundColor(.appGreen)
                .fontWeight(.semibold)
            }

            if comments.isEmpty {
                Text("No comments yet. Start the discussion!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            } else {
                ForEach(comments) { comment in
                    VStack(alignment: .leading, spacing: 4) {
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
                            if isOwner, let guideId = guide.id, let commentId = comment.id {
                                Button {
                                    store.deleteComment(guideId: guideId, commentId: commentId)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(0.7))
                                }
                            }
                        }
                        Divider()
                    }
                }
            }
        }
    }

    private func toggleLike() {
        guard let guideId = guide.id, let userId = authManager.user?.id else { return }
        store.toggleLike(guideId: guideId, userId: userId)
    }

    private func postComment() {
        guard let guideId = guide.id, !newCommentText.isEmpty else { return }
        store.addComment(
            guideId: guideId,
            text: newCommentText,
            authorId: authManager.user?.id,
            authorName: authManager.user?.displayName
        )
        newCommentText = ""
    }

    private func loadComments() {
        guard let guideId = guide.id else { return }
        store.fetchComments(guideId: guideId) { fetchedComments in
            comments = fetchedComments
        }
    }
}
