//
//  ContentView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = LocationTipStore()
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if store.tips.isEmpty {
                    ContentUnavailableView(
                        "No Tips Yet",
                        systemImage: "map",
                        description: Text("Tap + to add the first location tip")
                    )
                } else {
                    List(store.tips) { tip in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tip.title)
                                .font(.headline)
                            Text(tip.locationName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(tip.description)
                                .font(.body)
                                .lineLimit(2)
                            Text(tip.category)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Railmates")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddLocationTipView { newTip in
                    store.add(newTip)
                }
            }
            .onAppear {
                store.fetchAll()
            }
        }
    }
}

#Preview {
    ContentView()
}
