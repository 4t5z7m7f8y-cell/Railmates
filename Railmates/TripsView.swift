//
//  TripsView.swift
//  Railmates
//

import SwiftUI

enum DurationFilter: String, CaseIterable {
    case all = "All"
    case short = "≤7 days"
    case medium = "8–14 days"
    case long = "15+ days"
}

struct TripsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var storyStore = TripStoryStore()
    @StateObject private var journalStore = JournalStore()

    @State private var selectedSegment = 0
    @State private var showingCreateStory = false
    @State private var showingCreateJournal = false
    @State private var showMyContentOnly = false
    @State private var searchText = ""
    @State private var selectedCountry: String? = nil
    @State private var selectedDuration: DurationFilter = .all

    var availableCountries: [String] {
        Array(Set(storyStore.stories.flatMap { $0.countriesVisited })).sorted()
    }

    var filteredStories: [TripStory] {
        var base = storyStore.stories

        if !searchText.isEmpty {
            base = base.filter { story in
                story.title.localizedCaseInsensitiveContains(searchText) ||
                story.story.localizedCaseInsensitiveContains(searchText) ||
                story.visitedPlaces.contains {
                    ($0.city?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                    $0.country.localizedCaseInsensitiveContains(searchText)
                }
            }
        }

        if let country = selectedCountry {
            base = base.filter { $0.countriesVisited.contains(country) }
        }

        switch selectedDuration {
        case .short:  base = base.filter { tripDays($0) <= 7 }
        case .medium: base = base.filter { tripDays($0) > 7 && tripDays($0) <= 14 }
        case .long:   base = base.filter { tripDays($0) > 14 }
        case .all: break
        }

        return base
    }

    func tripDays(_ story: TripStory) -> Int {
        Calendar.current.dateComponents([.day], from: story.tripStart, to: story.tripEnd).day ?? 0
    }

    var filteredJournals: [Journal] {
        let base = journalStore.journals
        if searchText.isEmpty { return base }
        return base.filter { j in
            j.title.localizedCaseInsensitiveContains(searchText) ||
            j.description.localizedCaseInsensitiveContains(searchText) ||
            j.countries.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented picker
                Picker("", selection: $selectedSegment) {
                    Text("Stories").tag(0)
                    Text("Journals").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemGroupedBackground))

                if selectedSegment == 0 {
                    storyFilterBar
                    storiesContent
                } else {
                    journalsContent
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Trips")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: selectedSegment == 0 ? "Search stories..." : "Search journals...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Toggle("My Content Only", isOn: $showMyContentOnly)
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.appGreen)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if selectedSegment == 0 { showingCreateStory = true }
                        else { showingCreateJournal = true }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.appGreen)
                    }
                }
            }
            .sheet(isPresented: $showingCreateStory) {
                if let user = authManager.user {
                    CreateTripStoryView(userId: user.id ?? "") { newStory in
                        storyStore.create(newStory)
                    }
                }
            }
            .sheet(isPresented: $showingCreateJournal) {
                if let user = authManager.user {
                    AddJournalView(userId: user.id ?? "") { newJournal in
                        journalStore.create(newJournal)
                    }
                }
            }
            .onAppear { loadContent() }
            .onChange(of: showMyContentOnly) { _, _ in loadContent() }
        }
    }

    // MARK: Filter Bar
    @ViewBuilder
    var storyFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Duration chips
                ForEach(DurationFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        label: filter.rawValue,
                        isSelected: selectedDuration == filter
                    ) {
                        selectedDuration = filter
                    }
                }

                Divider().frame(height: 24)

                // Country chips
                if !availableCountries.isEmpty {
                    FilterChip(
                        label: selectedCountry ?? "Country",
                        isSelected: selectedCountry != nil,
                        icon: "globe"
                    ) {
                        selectedCountry = nil
                    }
                    ForEach(availableCountries, id: \.self) { country in
                        FilterChip(
                            label: country,
                            isSelected: selectedCountry == country
                        ) {
                            selectedCountry = selectedCountry == country ? nil : country
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: Stories List
    @ViewBuilder
    var storiesContent: some View {
        if storyStore.isLoading && storyStore.stories.isEmpty {
            loadingView(text: "Loading stories...")
        } else if filteredStories.isEmpty {
            emptyView(
                title: searchText.isEmpty ? "No Stories Yet" : "No Results",
                icon: searchText.isEmpty ? "book.closed.fill" : "magnifyingglass",
                message: searchText.isEmpty ? "Be the first to share your interrail adventure!" : "Try a different search term"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredStories) { story in
                        NavigationLink {
                            TripStoryDetailView(story: story, store: storyStore)
                        } label: {
                            TripStoryCardView(
                                story: story,
                                creatorName: storyStore.creatorNames[story.createdBy]
                            )
                            .appCard()
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if story.createdBy == authManager.user?.id, let id = story.id {
                                Button(role: .destructive) {
                                    storyStore.delete(storyId: id)
                                } label: {
                                    Label("Delete Story", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    // MARK: Journals List
    @ViewBuilder
    var journalsContent: some View {
        if journalStore.isLoading && journalStore.journals.isEmpty {
            loadingView(text: "Loading journals...")
        } else if filteredJournals.isEmpty {
            emptyView(
                title: searchText.isEmpty ? "No Journals Yet" : "No Results",
                icon: searchText.isEmpty ? "book.fill" : "magnifyingglass",
                message: searchText.isEmpty ? "Start documenting your adventures!" : "Try a different search term"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredJournals) { journal in
                        NavigationLink {
                            JournalDetailView(journal: journal, store: journalStore)
                        } label: {
                            JournalCardView(
                                journal: journal,
                                creatorName: journalStore.creatorNames[journal.createdBy]
                            )
                            .appCard()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    func loadingView(text: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView().scaleEffect(1.3)
            Text(text).foregroundColor(.secondary).font(.subheadline)
            Spacer()
        }
    }

    @ViewBuilder
    func emptyView(title: String, icon: String, message: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(message)
        }
    }

    func loadContent() {
        if showMyContentOnly, let userId = authManager.user?.id {
            storyStore.fetchMyStories(userId: userId)
            journalStore.fetchMyJournals(userId: userId)
        } else {
            storyStore.fetchPublicStories()
            journalStore.fetchPublicJournals()
        }
    }
}

// MARK: - Story Card
struct TripStoryCardView: View {
    let story: TripStory
    let creatorName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title row
            HStack(alignment: .top) {
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
                if !story.isPublic {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.appOchre)
                }
            }

            // Route
            if !story.visitedPlaces.isEmpty {
                Label(story.routeSummary, systemImage: "arrow.right")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.appGreen)
                    .lineLimit(1)
            }

            // Countries + duration
            HStack(spacing: 8) {
                Label(story.duration, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if !story.countriesVisited.isEmpty {
                    Text("•").foregroundColor(.secondary).font(.caption)
                    Text(story.countriesVisited.prefix(3).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            // Story preview
            Text(story.story)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)

            // Photos preview
            if !story.photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(story.photos.prefix(4)) { photo in
                            AsyncImage(url: URL(string: photo.url)) { phase in
                                switch phase {
                                case .success(let img):
                                    img.resizable().scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                default:
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemFill))
                                        .frame(width: 56, height: 56)
                                }
                            }
                        }
                    }
                }
            }

            // Engagement
            HStack(spacing: 14) {
                Label("\(story.viewCount)", systemImage: "eye")
                Label("\(story.likeCount)", systemImage: "heart.fill")
                    .foregroundColor(story.likeCount > 0 ? .red.opacity(0.7) : .secondary)
                if let budget = story.budget, budget > 0 {
                    Spacer()
                    Label("€\(budget)", systemImage: "eurosign.circle")
                        .foregroundColor(.appOchre)
                }
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding(16)
    }
}

// MARK: - Journal Card
struct JournalCardView: View {
    let journal: Journal
    let creatorName: String?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon
            ZStack {
                LinearGradient(
                    colors: [Color.appGreen.opacity(0.25), Color.appOchre.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                Image(systemName: "book.fill")
                    .font(.title3)
                    .foregroundColor(.appGreen)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(journal.title)
                        .font(.headline)
                        .lineLimit(2)
                    Spacer(minLength: 4)
                    HStack(spacing: 4) {
                        if journal.isOngoing {
                            Circle()
                                .fill(Color.appGreen)
                                .frame(width: 6, height: 6)
                        }
                        if !journal.isPublic {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundColor(.appOchre)
                        }
                    }
                }

                if let name = creatorName {
                    Label(name, systemImage: "person.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    Label(journal.duration, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if !journal.countries.isEmpty {
                        Label(journal.countries.prefix(2).joined(separator: ", "), systemImage: "globe")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                if !journal.description.isEmpty {
                    Text(journal.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(14)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundColor(isSelected ? .white : .primary)
            .background(isSelected ? Color.appGreen : Color(.systemFill))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TripsView().environmentObject(AuthenticationManager())
}
