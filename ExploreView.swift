import SwiftUI
import MapKit
import CoreLocation

enum ContentFilter: String, CaseIterable {
    case all    = "All"
    case tips   = "Tips"
    case guides = "Guides"
}

struct ExploreView: View {
    @StateObject private var tipStore   = LocationTipStore()
    @StateObject private var guideStore = GuideStore()
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject private var authManager: AuthenticationManager

    @State private var searchText          = ""
    @State private var contentFilter: ContentFilter = .all
    @State private var isMapMode           = false
    @State private var showingActionSheet  = false
    @State private var showingAddTip       = false
    @State private var showingAddGuide     = false

    var filteredTips: [LocationTip] {
        guard contentFilter != .guides else { return [] }
        let base = searchText.isEmpty ? tipStore.tips : tipStore.tips.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.locationName.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
        return base
    }

    var filteredGuides: [Guide] {
        guard contentFilter != .tips else { return [] }
        let base = searchText.isEmpty ? guideStore.guides : guideStore.guides.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            $0.country.localizedCaseInsensitiveContains(searchText)
        }
        return base
    }

    private enum MergedItem: Identifiable {
        case tip(LocationTip)
        case guide(Guide)
        var id: String {
            switch self {
            case .tip(let t):   return "tip-\(t.id ?? UUID().uuidString)"
            case .guide(let g): return "guide-\(g.id ?? UUID().uuidString)"
            }
        }
        var date: Date {
            switch self {
            case .tip(let t):   return t.createdAt
            case .guide(let g): return g.createdAt
            }
        }
    }

    private var mergedItems: [MergedItem] {
        (filteredTips.map(MergedItem.tip) + filteredGuides.map(MergedItem.guide))
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                if isMapMode {
                    ExploreMapView(tips: filteredTips, guides: filteredGuides)
                } else {
                    listContent
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search tips, guides, cities...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingActionSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.appGreen)
                    }
                }
            }
            .confirmationDialog("Add to Explore", isPresented: $showingActionSheet) {
                Button("Share a Tip")   { showingAddTip   = true }
                Button("Write a Guide") { showingAddGuide = true }
            }
            .sheet(isPresented: $showingAddTip) {
                AddLocationTipView(userId: authManager.user?.id) { tipStore.add($0) }
            }
            .sheet(isPresented: $showingAddGuide) {
                AddEditGuideView { guideStore.add($0) }
            }
            .onAppear {
                tipStore.fetchAll()
                guideStore.fetchAll()
                locationManager.requestPermission()
            }
        }
    }

    // MARK: - Filter Bar
    @ViewBuilder
    var filterBar: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ContentFilter.allCases, id: \.self) { filter in
                        FilterChip(label: filter.rawValue, isSelected: contentFilter == filter) {
                            contentFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }

            Divider().frame(height: 28).padding(.horizontal, 4)

            HStack(spacing: 4) {
                Button {
                    isMapMode = false
                } label: {
                    Image(systemName: "list.bullet")
                        .padding(7)
                        .background(isMapMode ? Color.clear : Color.appGreen)
                        .foregroundColor(isMapMode ? .secondary : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
                Button {
                    isMapMode = true
                } label: {
                    Image(systemName: "map")
                        .padding(7)
                        .background(isMapMode ? Color.appGreen : Color.clear)
                        .foregroundColor(isMapMode ? .white : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
            }
            .padding(.trailing, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - List Content
    @ViewBuilder
    var listContent: some View {
        if mergedItems.isEmpty {
            ContentUnavailableView(
                searchText.isEmpty ? "Nothing Here Yet" : "No Results",
                systemImage: searchText.isEmpty ? "map" : "magnifyingglass",
                description: Text(searchText.isEmpty
                    ? "Be the first to share a tip or guide!"
                    : "Try a different search term.")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(mergedItems) { item in
                        switch item {
                        case .tip(let tip):
                            NavigationLink {
                                TipDetailView(tip: tip, store: tipStore)
                            } label: {
                                TipCard(
                                    tip: tip,
                                    distanceText: locationManager.currentLocation.map {
                                        formattedDistance(tip.distance(from: $0))
                                    }
                                )
                                .appCard()
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if tip.createdBy == authManager.user?.id, let id = tip.id {
                                    Button(role: .destructive) {
                                        tipStore.delete(tipId: id)
                                    } label: {
                                        Label("Delete Tip", systemImage: "trash")
                                    }
                                }
                            }

                        case .guide(let guide):
                            NavigationLink {
                                GuideDetailView(guide: guide, store: guideStore)
                            } label: {
                                GuideCard(guide: guide)
                                    .appCard()
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if guide.createdBy == authManager.user?.id, let id = guide.id {
                                    Button(role: .destructive) {
                                        guideStore.delete(guideId: id)
                                    } label: {
                                        Label("Delete Guide", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    private func formattedDistance(_ meters: CLLocationDistance) -> String {
        meters < 1000
            ? "\(Int(meters)) m away"
            : String(format: "%.1f km away", meters / 1000)
    }
}

// MARK: - Tip Card (moved from ContentView)
struct TipCard: View {
    let tip: LocationTip
    let distanceText: String?

    var categoryIcon: String {
        switch tip.category {
        case "Hostel":      return "building.2.fill"
        case "Hotel":       return "bed.double.fill"
        case "Food":        return "fork.knife"
        case "Activity":    return "figure.walk"
        case "Sight":       return "camera.fill"
        case "Station Tip": return "train.side.front.car"
        default:            return "mappin.circle.fill"
        }
    }

    var categoryColor: Color {
        switch tip.category {
        case "Food":        return .appOchre
        case "Station Tip": return .appBrown
        case "Activity":    return .appGreen
        case "Sight":       return Color(red: 0.20, green: 0.40, blue: 0.80)
        case "Hostel":      return .indigo
        case "Hotel":       return .purple
        default:            return .appGreen
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: categoryIcon)
                        .foregroundColor(categoryColor)
                        .font(.subheadline)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(tip.title).font(.headline)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin").font(.caption2).foregroundColor(.secondary)
                        Text(tip.locationName).font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text(tip.category)
                    .font(.caption2).fontWeight(.medium)
                    .foregroundColor(categoryColor)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(categoryColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            Text(tip.description)
                .font(.subheadline).foregroundColor(.secondary).lineLimit(2)
            HStack(spacing: 12) {
                if tip.ratingCount > 0 {
                    Label(String(format: "%.1f", tip.averageRating), systemImage: "star.fill")
                        .font(.caption).foregroundColor(.appOchre)
                }
                if tip.likeCount > 0 {
                    Label("\(tip.likeCount)", systemImage: "heart.fill")
                        .font(.caption).foregroundColor(.pink.opacity(0.8))
                }
                Spacer()
                if let distanceText {
                    Text(distanceText).font(.caption).foregroundColor(categoryColor).fontWeight(.medium)
                }
            }
        }
        .padding(16)
    }
}

typealias TipRow = TipCard

// MARK: - Guide Card
struct GuideCard: View {
    let guide: Guide

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Guide.categoryColor(guide.category).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: Guide.categoryIcon(guide.category))
                        .foregroundColor(Guide.categoryColor(guide.category))
                        .font(.subheadline)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(guide.title).font(.headline)
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle").font(.caption2).foregroundColor(.secondary)
                        Text(guide.authorName.isEmpty ? "Community" : guide.authorName)
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text(guide.category)
                    .font(.caption2).fontWeight(.medium)
                    .foregroundColor(Guide.categoryColor(guide.category))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Guide.categoryColor(guide.category).opacity(0.12))
                    .clipShape(Capsule())
            }
            Text(guide.content)
                .font(.subheadline).foregroundColor(.secondary).lineLimit(2)
            HStack(spacing: 12) {
                if !guide.country.isEmpty {
                    Label(guide.country, systemImage: "globe")
                        .font(.caption).foregroundColor(.secondary)
                }
                if guide.likeCount > 0 {
                    Label("\(guide.likeCount)", systemImage: "heart.fill")
                        .font(.caption).foregroundColor(.pink.opacity(0.8))
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Explore Map View
struct ExploreMapView: View {
    let tips: [LocationTip]
    let guides: [Guide]

    @State private var selectedTip: LocationTip?
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.0, longitude: 10.0),
        span: MKCoordinateSpan(latitudeDelta: 28, longitudeDelta: 28)
    ))

    private var guidesOnMap: [Guide] {
        guides.filter { $0.latitude != nil && $0.longitude != nil }
    }

    var body: some View {
        Map(position: $cameraPosition, selection: $selectedTip) {
            UserAnnotation()

            ForEach(tips) { tip in
                Marker(tip.title, systemImage: "mappin.circle.fill",
                       coordinate: CLLocationCoordinate2D(latitude: tip.latitude, longitude: tip.longitude))
                    .tint(Color.appGreen)
                    .tag(tip)
            }

            ForEach(guidesOnMap) { guide in
                Marker(guide.title, systemImage: "book.fill",
                       coordinate: CLLocationCoordinate2D(latitude: guide.latitude!, longitude: guide.longitude!))
                    .tint(.blue)
            }
        }
        .sheet(item: $selectedTip) { tip in
            TipDetailSheet(tip: tip)
                .presentationDetents([.height(280)])
        }
    }
}

