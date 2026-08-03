//
//  JournalsListView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import SwiftUI

struct JournalsListView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var store = JournalStore()
    @State private var showingAddSheet = false
    @State private var showMyJournalsOnly = false
    @State private var searchText = ""
    @State private var errorAlert: ErrorAlert?
    
    var filteredJournals: [Journal] {
        if searchText.isEmpty {
            return store.journals
        }
        return store.journals.filter { journal in
            journal.title.localizedCaseInsensitiveContains(searchText) ||
            journal.description.localizedCaseInsensitiveContains(searchText) ||
            journal.countries.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading && store.journals.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading journals...")
                            .foregroundColor(.secondary)
                    }
                } else if filteredJournals.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? (showMyJournalsOnly ? "No Journals Yet" : "No Public Journals") : "No Results",
                        systemImage: "book.closed.fill",
                        description: Text(searchText.isEmpty ? 
                            (showMyJournalsOnly ? "Tap + to document your first trip" : "No one has shared their journey yet") :
                            "Try a different search term")
                    )
                } else {
                    List(filteredJournals) { journal in
                        NavigationLink {
                            JournalDetailView(journal: journal, store: store)
                        } label: {
                            JournalRow(
                                journal: journal,
                                creatorName: store.creatorNames[journal.createdBy]
                            )
                        }
                    }
                    .refreshable {
                        if showMyJournalsOnly {
                            if let userId = authManager.user?.id {
                                store.fetchMyJournals(userId: userId)
                            }
                        } else {
                            store.fetchPublicJournals()
                        }
                    }
                }
            }
            .navigationTitle("Journals")
            .searchable(text: $searchText, prompt: "Search journals...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Toggle("My Journals Only", isOn: $showMyJournalsOnly)
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                
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
                if let user = authManager.user {
                    AddJournalView(userId: user.id ?? "") { newJournal in
                        store.create(newJournal)
                    }
                }
            }
            .onAppear {
                if showMyJournalsOnly {
                    if let userId = authManager.user?.id {
                        store.fetchMyJournals(userId: userId)
                    }
                } else {
                    store.fetchPublicJournals()
                }
            }
            .onChange(of: showMyJournalsOnly) { oldValue, newValue in
                if newValue {
                    if let userId = authManager.user?.id {
                        store.fetchMyJournals(userId: userId)
                    }
                } else {
                    store.fetchPublicJournals()
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

struct JournalRow: View {
    let journal: Journal
    let creatorName: String?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Cover photo or placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(journal.title)
                    .font(.headline)
                
                // Show creator name if available
                if let name = creatorName {
                    Text("by \(name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(journal.duration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !journal.countries.isEmpty {
                    Text(journal.countries.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if !journal.description.isEmpty {
                    Text(journal.description)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 6) {
                    if journal.isOngoing {
                        Text("Ongoing")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                    
                    if journal.isPublic {
                        Image(systemName: "globe")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    JournalsListView()
        .environmentObject(AuthenticationManager())
}
