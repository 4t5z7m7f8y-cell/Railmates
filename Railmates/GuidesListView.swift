import SwiftUI

struct GuidesListView: View {
    @StateObject private var store = GuideStore()
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showingAddSheet = false

    private let allCategories = ["All"] + Guide.categories

    var filteredGuides: [Guide] {
        var base = store.guides
        if selectedCategory != "All" {
            base = base.filter { $0.category == selectedCategory }
        }
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            $0.country.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryChips

                if store.guides.isEmpty {
                    ContentUnavailableView(
                        "No Guides Yet",
                        systemImage: "book.closed",
                        description: Text("Be the first to share a how-to for fellow rail travelers!")
                    )
                    .frame(maxHeight: .infinity)
                } else if filteredGuides.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Guides Here" : "No Results",
                        systemImage: searchText.isEmpty ? "tray" : "magnifyingglass",
                        description: Text(searchText.isEmpty ? "Try a different category" : "Try a different search term")
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredGuides) { guide in
                                NavigationLink {
                                    GuideDetailView(guide: guide, store: store)
                                } label: {
                                    GuideCard(guide: guide)
                                        .appCard()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Guides")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search guides...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.appGreen)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEditGuideView { newGuide in
                    store.add(newGuide)
                }
            }
            .onAppear {
                store.fetchAll()
            }
        }
    }

    @ViewBuilder
    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(allCategories, id: \.self) { cat in
                    Button {
                        selectedCategory = cat
                    } label: {
                        Text(cat)
                            .font(.subheadline)
                            .fontWeight(selectedCategory == cat ? .semibold : .regular)
                            .foregroundColor(selectedCategory == cat ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selectedCategory == cat ? Color.appGreen : Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Guide Card

struct GuideCard: View {
    let guide: Guide

    private var color: Color { Guide.categoryColor(guide.category) }
    private var icon: String  { Guide.categoryIcon(guide.category) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.subheadline)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(guide.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 4) {
                        Text(guide.authorName.isEmpty ? "Community" : guide.authorName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if !guide.country.isEmpty {
                            Text("·")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(guide.country)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer(minLength: 0)

                Text(guide.category)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(guide.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            HStack {
                if guide.likeCount > 0 {
                    Label("\(guide.likeCount)", systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.pink.opacity(0.8))
                }
                Spacer()
                Text(guide.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
    }
}
