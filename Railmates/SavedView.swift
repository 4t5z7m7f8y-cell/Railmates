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
    @StateObject private var tipStore = LocationTipStore()
    @StateObject private var storyStore = TripStoryStore()
    @State private var savedTips: [LocationTip] = []
    @State private var savedStories: [TripStory] = []
    @State private var isLoadingTips = false
    @State private var isLoadingStories = false

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            Group {
                if savedTips.isEmpty && savedStories.isEmpty && !isLoadingTips && !isLoadingStories {
                    ContentUnavailableView {
                        Label("No Saved Items", systemImage: "bookmark")
                    } description: {
                        Text("Tap the bookmark icon on any tip or story to save it here.")
                    }
                } else {
                    List {
                        if isLoadingTips || isLoadingStories {
                            Section {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
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
            .onAppear {
                loadSavedItems()
            }
            .onChange(of: authManager.user?.savedTipIds) { _, _ in
                loadSavedItems()
            }
            .onChange(of: authManager.user?.savedStoryIds) { _, _ in
                loadSavedItems()
            }
        }
    }

    func loadSavedItems() {
        loadSavedTips()
        loadSavedStories()
    }

    func loadSavedTips() {
        let ids = authManager.user?.savedTipIds ?? [] as [String]
        guard !ids.isEmpty else {
            savedTips = []
            return
        }
        isLoadingTips = true
        db.collection("locationTips")
            .whereField(FieldPath.documentID(), in: ids)
            .getDocuments { snapshot, error in
                isLoadingTips = false
                if let error = error {
                    print("Error loading saved tips: \(error)")
                    return
                }
                savedTips = snapshot?.documents.compactMap { try? $0.data(as: LocationTip.self) } ?? []
                tipStore.tips = savedTips
            }
    }

    func loadSavedStories() {
        let ids = authManager.user?.savedStoryIds ?? [] as [String]
        guard !ids.isEmpty else {
            savedStories = []
            return
        }
        isLoadingStories = true
        db.collection("tripStories")
            .whereField(FieldPath.documentID(), in: ids)
            .getDocuments { snapshot, error in
                isLoadingStories = false
                if let error = error {
                    print("Error loading saved stories: \(error)")
                    return
                }
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
