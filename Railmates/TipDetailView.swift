//
//  TipDetailView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//
import SwiftUI

struct TipDetailView: View {
    let tip: LocationTip
    @ObservedObject var store: LocationTipStore

    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var selectedRating = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(tip.title)
                        .font(.title2)
                        .bold()

                    Text(tip.locationName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(tip.description)
                        .font(.body)

                    Text(tip.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(Capsule())
                    
                    // Category-specific fields
                    if let stationName = tip.stationName, !stationName.isEmpty {
                        Label(stationName, systemImage: "train.side.front.car")
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                    
                    if let hasStorage = tip.hasLuggageStorage, hasStorage {
                        Label("Luggage storage available", systemImage: "suitcase.fill")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.top, 4)
                    }
                    
                    if let info = tip.practicalInfo, !info.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Text("💡")
                                .font(.subheadline)
                            Text(info)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Rating")
                        .font(.headline)

                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(tip.averageRating.rounded()) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                        }
                        Text(String(format: "%.1f (%d)", tip.averageRating, tip.ratingCount))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text("Rate this tip")
                        .font(.subheadline)
                        .padding(.top, 4)

                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    selectedRating = star
                                    if let tipId = tip.id {
                                        store.addRating(tipId: tipId, rating: star)
                                    }
                                }
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Comments")
                        .font(.headline)

                    HStack {
                        TextField("Add a comment...", text: $newCommentText)
                            .textFieldStyle(.roundedBorder)
                        Button("Post") {
                            postComment()
                        }
                        .disabled(newCommentText.isEmpty)
                    }

                    if comments.isEmpty {
                        Text("No comments yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(comments) { comment in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(comment.text)
                                Text(comment.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Tip Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadComments()
        }
    }

    func loadComments() {
        guard let tipId = tip.id else { return }
        store.fetchComments(tipId: tipId) { fetchedComments in
            comments = fetchedComments
        }
    }

    func postComment() {
        guard let tipId = tip.id, !newCommentText.isEmpty else { return }
        store.addComment(tipId: tipId, text: newCommentText)
        newCommentText = ""
    }
}
