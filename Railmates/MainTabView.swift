//
//  MainTabView.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Tips", systemImage: "map.fill")
                }
            
            HappeningsListView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
            
            TripStoriesListView()
                .tabItem {
                    Label("Stories", systemImage: "book.pages.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
}
