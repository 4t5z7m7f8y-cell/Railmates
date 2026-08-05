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
    
    var isOwner: Bool {
        authManager.user?.id == story.createdBy
    }
    
    var creatorName: String? {
        store.creatorNames[story.createdBy]
    }
    
    var isLiked: Bool {
        guard let userId = authManager.user?.id else { return false }
        return story.likedBy.contains(userId)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Text(story.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack {
                        if let name = creatorName {
                            Label(name, systemImage: "person.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !story.isPublic {
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
                            Text("\(story.tripStart.formatted(date: .abbreviated, time: .omitted)) - \(story.tripEnd.formatted(date: .abbreviated, time: .omitted))")
                                .font(.subheadline)
                            Text("•")
                            Text(story.duration)
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                        
                        if !story.visitedPlaces.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "map.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text(story.routeSummary)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if !story.countriesVisited.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "globe")
                                    .font(.caption)
                                Text(story.countriesVisited.joined(separator: ", "))
                                    .font(.subheadline)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // Engagement
                    HStack(spacing: 16) {
                        Label("\(story.viewCount)", systemImage: "eye")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label("\(story.likeCount)", systemImage: isLiked ? "heart.fill" : "heart")
                            .font(.caption)
                            .foregroundColor(isLiked ? .red : .secondary)
                        
                        if story.photos.count > 0 {
                            Label("\(story.photos.count)", systemImage: "photo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Story content
                Text(story.story)
                    .font(.body)
                    .padding(.horizontal)
                
                // Photos
                if !story.photos.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Photos")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(story.photos.sorted { $0.order < $1.order }) { photo in
                            VStack(alignment: .leading, spacing: 8) {
                                AsyncImage(url: URL(string: photo.url)) { phase in
                                    switch phase {
                                    case .empty:
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 300)
                                            .overlay {
                                                ProgressView()
                                            }
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
                HStack(spacing: 20) {
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
                        showingShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
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
        }
    }
    
    func toggleLike() {
        guard let userId = authManager.user?.id, let storyId = story.id else { return }
        store.toggleLike(storyId: storyId, userId: userId)
    }
    
    func createShareText() -> String {
        var text = "Check out this amazing trip story on Railmates!\n\n"
        text += "📖 \(story.title)\n"
        if let name = creatorName {
            text += "✍️ by \(name)\n"
        }
        text += "🗓️ \(story.duration)\n"
        if !story.countriesVisited.isEmpty {
            text += "🌍 \(story.countriesVisited.joined(separator: ", "))\n"
        }
        if !story.visitedPlaces.isEmpty {
            text += "🗺️ Route: \(story.routeSummary)\n"
        }
        text += "\n\(String(story.story.prefix(200)))..."
        if story.photos.count > 0 {
            text += "\n\n📸 \(story.photos.count) photos"
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
