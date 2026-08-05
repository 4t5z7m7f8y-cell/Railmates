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
                    VStack(spacing: 20) {
                        ContentUnavailableView {
                            Label(
                                searchText.isEmpty ? (showMyJournalsOnly ? "No Journals Yet" : "No Public Journals") : "No Results",
                                systemImage: searchText.isEmpty ? "book.closed.fill" : "magnifyingglass"
                            )
                        } description: {
                            Text(searchText.isEmpty ? 
                                (showMyJournalsOnly ? "Start documenting your adventures!" : "No one has shared their journey yet") :
                                "Try a different search term")
                        }
                        
                        // Action button for empty state
                        if searchText.isEmpty && showMyJournalsOnly {
                            Button {
                                showingAddSheet = true
                            } label: {
                                Label("Create Your First Journal", systemImage: "plus.circle.fill")
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
            // Cover photo or placeholder with gradient
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Title and badges row
                HStack(alignment: .top) {
                    Text(journal.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Spacer(minLength: 4)
                    
                    // Status badges
                    HStack(spacing: 4) {
                        if journal.isOngoing {
                            Image(systemName: "circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        
                        if !journal.isPublic {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                // Creator name with loading state
                if let name = creatorName {
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle")
                            .font(.caption2)
                        Text(name)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                } else {
                    // Skeleton loader
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle")
                            .font(.caption2)
                        Text("Loading...")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary.opacity(0.5))
                    .redacted(reason: .placeholder)
                }
                
                // Duration and countries in one line
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
                
                // Description (if exists)
                if !journal.description.isEmpty {
                    Text(journal.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    JournalsListView()
        .environmentObject(AuthenticationManager())
}
