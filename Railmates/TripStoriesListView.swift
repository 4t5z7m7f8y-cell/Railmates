//
//  TripStoriesListView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-03.
//

import SwiftUI

struct TripStoriesListView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var store = TripStoryStore()
    @State private var showingCreateSheet = false
    @State private var showMyStoriesOnly = false
    @State private var searchText = ""
    @State private var errorAlert: ErrorAlert?
    
    var filteredStories: [TripStory] {
        if searchText.isEmpty {
            return store.stories
        }
        return store.stories.filter { story in
            story.title.localizedCaseInsensitiveContains(searchText) ||
            story.story.localizedCaseInsensitiveContains(searchText) ||
            story.visitedPlaces.contains { place in
                place.city?.localizedCaseInsensitiveContains(searchText) ?? false ||
                place.country.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading && store.stories.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading trip stories...")
                            .foregroundColor(.secondary)
                    }
                } else if filteredStories.isEmpty {
                    VStack(spacing: 20) {
                        ContentUnavailableView {
                            Label(
                                searchText.isEmpty ? (showMyStoriesOnly ? "No Stories Yet" : "No Trip Stories") : "No Results",
                                systemImage: searchText.isEmpty ? "book.closed.fill" : "magnifyingglass"
                            )
                        } description: {
                            Text(searchText.isEmpty ?
                                (showMyStoriesOnly ? "Share your first adventure!" : "Be the first to share your journey") :
                                "Try searching for a different city or country")
                        }
                        
                        // Action button for empty state
                        if searchText.isEmpty && showMyStoriesOnly {
                            Button {
                                showingCreateSheet = true
                            } label: {
                                Label("Share Your Trip Story", systemImage: "plus.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                } else {
                    List(filteredStories) { story in
                        NavigationLink {
                            TripStoryDetailView(story: story, store: store)
                        } label: {
                            TripStoryRow(
                                story: story,
                                creatorName: store.creatorNames[story.createdBy]
                            )
                        }
                    }
                    .refreshable {
                        if showMyStoriesOnly {
                            if let userId = authManager.user?.id {
                                store.fetchMyStories(userId: userId)
                            }
                        } else {
                            store.fetchPublicStories()
                        }
                    }
                }
            }
            .navigationTitle("Trip Stories")
            .searchable(text: $searchText, prompt: "Search cities, countries, or stories...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Toggle("My Stories Only", isOn: $showMyStoriesOnly)
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                if let user = authManager.user {
                    CreateTripStoryView(userId: user.id ?? "") { newStory in
                        store.create(newStory)
                    }
                }
            }
            .onAppear {
                if showMyStoriesOnly {
                    if let userId = authManager.user?.id {
                        store.fetchMyStories(userId: userId)
                    }
                } else {
                    store.fetchPublicStories()
                }
            }
            .onChange(of: showMyStoriesOnly) { oldValue, newValue in
                if newValue {
                    if let userId = authManager.user?.id {
                        store.fetchMyStories(userId: userId)
                    }
                } else {
                    store.fetchPublicStories()
                }
            }
            .errorAlert($errorAlert)
            .onChange(of: store.errorMessage) { oldValue, newValue in
                if let error = newValue {
                    errorAlert = ErrorAlert(title: "Error", message: error)
                }
            }
        }
    }
}

struct TripStoryRow: View {
    let story: TripStory
    let creatorName: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(story.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    // Creator name with skeleton loader
                    if let name = creatorName {
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle")
                                .font(.caption2)
                            Text(name)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle")
                                .font(.caption2)
                            Text("Loading...")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary.opacity(0.5))
                        .redacted(reason: .placeholder)
                    }
                }
                
                Spacer()
                
                // Privacy indicator
                if !story.isPublic {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // Trip info
            HStack(spacing: 8) {
                Label(story.duration, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !story.countriesVisited.isEmpty {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(story.countriesVisited.prefix(2).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // Route
            if !story.visitedPlaces.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "map.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text(story.routeSummary)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
            }
            
            // Story preview
            Text(story.story)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Photo preview
            if !story.photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(story.photos.prefix(4)) { photo in
                            AsyncImage(url: URL(string: photo.url)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                default:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        
                        if story.photos.count > 4 {
                            ZStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Text("+\(story.photos.count - 4)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            // Engagement
            HStack(spacing: 12) {
                Label("\(story.viewCount)", systemImage: "eye")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Label("\(story.likeCount)", systemImage: "heart")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if story.photos.count > 0 {
                    Label("\(story.photos.count)", systemImage: "photo")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    TripStoriesListView()
        .environmentObject(AuthenticationManager())
}
