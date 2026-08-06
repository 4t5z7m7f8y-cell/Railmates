//
//  HomeView.swift
//  Railmates
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var tipStore = LocationTipStore()
    @StateObject private var storyStore = TripStoryStore()
    @StateObject private var followingStore = TripStoryStore()
    @StateObject private var eventStore = HappeningStore()

    // Trending: most liked tips first
    var trendingTips: [LocationTip] {
        tipStore.tips
            .sorted { $0.likeCount > $1.likeCount }
            .prefix(6)
            .map { $0 }
    }

    // Trending: weighted by likes (3x) + views
    var trendingStories: [TripStory] {
        storyStore.stories
            .sorted { ($0.likeCount * 3 + $0.viewCount) > ($1.likeCount * 3 + $1.viewCount) }
            .prefix(4)
            .map { $0 }
    }

    var upcomingEvents: [Happening] { Array(eventStore.happenings.prefix(3)) }

    var followingIds: [String] { authManager.user?.following ?? [] }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // MARK: Greeting
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hello, \(authManager.user?.displayName ?? "traveler") 👋")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Discover tips, stories & events from the community")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // MARK: Following Feed
                    if !followingStore.stories.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Following", icon: "person.2.fill", color: .appGreen)
                                .padding(.horizontal)

                            VStack(spacing: 10) {
                                ForEach(followingStore.stories.prefix(3)) { story in
                                    NavigationLink {
                                        TripStoryDetailView(story: story, store: followingStore)
                                    } label: {
                                        StoryFeedCard(
                                            story: story,
                                            creatorName: followingStore.creatorNames[story.createdBy]
                                        )
                                        .appCard()
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // MARK: Trending Tips
                    if !trendingTips.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Trending Tips", icon: "mappin.circle.fill", color: .appGreen)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(trendingTips) { tip in
                                        NavigationLink {
                                            TipDetailView(tip: tip, store: tipStore)
                                        } label: {
                                            TipMiniCard(tip: tip)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // MARK: Trending Stories
                    if !trendingStories.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Trending Stories", icon: "train.side.front.car", color: .appOchre)
                                .padding(.horizontal)

                            VStack(spacing: 10) {
                                ForEach(trendingStories) { story in
                                    NavigationLink {
                                        TripStoryDetailView(story: story, store: storyStore)
                                    } label: {
                                        StoryFeedCard(
                                            story: story,
                                            creatorName: storyStore.creatorNames[story.createdBy]
                                        )
                                        .appCard()
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // MARK: Upcoming Events
                    if !upcomingEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Upcoming Events", icon: "calendar", color: .appBrown)
                                .padding(.horizontal)

                            VStack(spacing: 10) {
                                ForEach(upcomingEvents) { event in
                                    EventFeedCard(event: event)
                                        .appCard()
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }

                    if trendingTips.isEmpty && trendingStories.isEmpty && upcomingEvents.isEmpty {
                        ContentUnavailableView {
                            Label("Nothing Yet", systemImage: "globe.europe.africa")
                        } description: {
                            Text("Add tips, share stories and create events to get started!")
                        }
                        .padding(.top, 40)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.bottom)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                tipStore.fetchAll()
                storyStore.fetchPublicStories()
                eventStore.fetchUpcoming()
                if !followingIds.isEmpty {
                    followingStore.fetchStoriesByUsers(userIds: followingIds)
                }
            }
            .onChange(of: authManager.user?.following) { _, newFollowing in
                let ids = newFollowing ?? []
                if !ids.isEmpty {
                    followingStore.fetchStoriesByUsers(userIds: ids)
                }
            }
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Tip Mini Card (horizontal scroll)
struct TipMiniCard: View {
    let tip: LocationTip

    var categoryColor: Color {
        switch tip.category {
        case "Food": return .appOchre
        case "Station Tip": return .appBrown
        case "Activity": return .appGreen
        case "Sight": return .blue
        case "Hostel", "Hotel": return .indigo
        default: return .appGreen
        }
    }

    var categoryIcon: String {
        switch tip.category {
        case "Hostel": return "building.2.fill"
        case "Hotel": return "bed.double.fill"
        case "Food": return "fork.knife"
        case "Activity": return "figure.walk"
        case "Sight": return "camera.fill"
        case "Station Tip": return "train.side.front.car"
        default: return "mappin.circle.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: categoryIcon)
                    .foregroundColor(categoryColor)
                    .font(.subheadline)
            }

            Text(tip.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .frame(width: 140, alignment: .leading)

            Text(tip.locationName)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)

            if tip.ratingCount > 0 {
                Label(String(format: "%.1f", tip.averageRating), systemImage: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.appOchre)
            }
        }
        .padding(14)
        .frame(width: 160)
        .appCard()
    }
}

// MARK: - Story Feed Card
struct StoryFeedCard: View {
    let story: TripStory
    let creatorName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(story.title)
                        .font(.headline)
                        .lineLimit(2)
                    if let name = creatorName {
                        Label(name, systemImage: "person.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "train.side.front.car")
                    .foregroundColor(.appOchre)
                    .font(.title3)
            }

            if !story.visitedPlaces.isEmpty {
                Text(story.routeSummary)
                    .font(.caption)
                    .foregroundColor(.appGreen)
                    .fontWeight(.medium)
            }

            HStack(spacing: 12) {
                Label(story.duration, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Label("\(story.likeCount)", systemImage: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Label("\(story.viewCount)", systemImage: "eye")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
    }
}

// MARK: - Event Feed Card
struct EventFeedCard: View {
    let event: Happening

    var categoryColor: Color {
        switch event.category {
        case "Meetup": return .appGreen
        case "Party": return .purple
        case "Day Trip": return .appOchre
        case "Pub Crawl": return .orange
        default: return .appBrown
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 4) {
                Text(event.dateTime.formatted(.dateTime.day()))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(categoryColor)
                Text(event.dateTime.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Label(event.city, systemImage: "mappin")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(event.attendeeIds.count) going")
                    .font(.caption2)
                    .foregroundColor(categoryColor)
                    .fontWeight(.medium)
            }

            Spacer()

            Text(event.category)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(categoryColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(categoryColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(14)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthenticationManager())
}
