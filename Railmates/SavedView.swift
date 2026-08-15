//
//  SavedView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-06.
//

import SwiftUI
import FirebaseFirestore

struct SavedView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var tipStore   = LocationTipStore()
    @StateObject private var guideStore = GuideStore()
    @StateObject private var storyStore = TripStoryStore()

    @State private var savedTips:    [LocationTip] = []
    @State private var savedGuides:  [Guide]       = []
    @State private var savedStories: [TripStory]   = []
    @State private var isLoading = false

    private let db = Firestore.firestore()

    var isEmpty: Bool {
        savedTips.isEmpty && savedGuides.isEmpty && savedStories.isEmpty && !isLoading
    }

    var body: some View {
        NavigationStack {
            Group {
                if isEmpty {
                    ContentUnavailableView {
                        Label("No Saved Items", systemImage: "bookmark")
                    } description: {
                        Text("Tap the bookmark icon on any tip or guide to save it here.")
                    }
                } else {
                    List {
                        if isLoading {
                            Section {
                                HStack { Spacer(); ProgressView(); Spacer() }
                            }
                        }

                        if !savedTips.isEmpty {
                            Section("Saved Tips") {
                                ForEach(savedTips) { tip in
                                    NavigationLink {
                                        TipDetailView(tip: tip, store: tipStore)
                                    } label: {
                                        TipRow(tip: tip, distanceText: nil)
                                    }
                                }
                            }
                        }

                        if !savedGuides.isEmpty {
                            Section("Saved Guides") {
                                ForEach(savedGuides) { guide in
                                    NavigationLink {
                                        GuideDetailView(guide: guide, store: guideStore)
                                    } label: {
                                        GuideCard(guide: guide)
                                    }
                                }
                            }
                        }

                        if !savedStories.isEmpty {
                            Section("Saved Stories") {
                                ForEach(savedStories) { story in
                                    NavigationLink {
                                        TripStoryDetailView(story: story, store: storyStore)
                                    } label: {
                                        TripStoryRow(
                                            story: story,
                                            creatorName: storyStore.creatorNames[story.createdBy]
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Saved")
            .onAppear { loadAll() }
            .onChange(of: authManager.user?.savedTipIds)   { _, _ in loadAll() }
            .onChange(of: authManager.user?.savedGuideIds) { _, _ in loadAll() }
            .onChange(of: authManager.user?.savedStoryIds) { _, _ in loadAll() }
        }
    }

    private func loadAll() {
        loadSavedTips()
        loadSavedGuides()
        loadSavedStories()
    }

    private func loadSavedTips() {
        let ids = authManager.user?.savedTipIds ?? []
        guard !ids.isEmpty else { savedTips = []; return }
        isLoading = true
        db.collection("locationTips")
            .whereField(FieldPath.documentID(), in: ids)
            .getDocuments { snapshot, _ in
                isLoading = false
                savedTips = snapshot?.documents.compactMap { try? $0.data(as: LocationTip.self) } ?? []
                tipStore.tips = savedTips
            }
    }

    private func loadSavedGuides() {
        let ids = authManager.user?.savedGuideIds ?? []
        guard !ids.isEmpty else { savedGuides = []; return }
        isLoading = true
        db.collection("guides")
            .whereField(FieldPath.documentID(), in: ids)
            .getDocuments { snapshot, _ in
                isLoading = false
                savedGuides = snapshot?.documents.compactMap { try? $0.data(as: Guide.self) } ?? []
                guideStore.guides = savedGuides
            }
    }

    private func loadSavedStories() {
        let ids = authManager.user?.savedStoryIds ?? []
        guard !ids.isEmpty else { savedStories = []; return }
        isLoading = true
        db.collection("tripStories")
            .whereField(FieldPath.documentID(), in: ids)
            .getDocuments { snapshot, _ in
                isLoading = false
                savedStories = snapshot?.documents.compactMap { try? $0.data(as: TripStory.self) } ?? []
                storyStore.stories = savedStories
                Task { await storyStore.fetchAllCreatorNames() }
            }
    }
}

#Preview {
    SavedView()
        .environmentObject(AuthenticationManager())
}
