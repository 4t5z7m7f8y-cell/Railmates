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
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            ContentView()
                .tabItem {
                    Label("Tips", systemImage: "mappin.and.ellipse")
                }

            TripsView()
                .tabItem {
                    Label("Trips", systemImage: "train.side.front.car")
                }

            HappeningsListView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }

            ProfileView()
                .tabItem {
                    Label("Me", systemImage: "person.fill")
                }
        }
        .tint(.appGreen)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
}
