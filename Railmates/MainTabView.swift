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
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "map")
                }

            TripsView()
                .tabItem {
                    Label("My Trips", systemImage: "train.side.front.car")
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
