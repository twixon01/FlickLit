//
//  MainTabView.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 05.03.2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            CollectionView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Collection")
                }

            StatsView()
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("Stats")
                }

            AchievementsView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Achievements")
                }
        }
        .accentColor(Color("AccentYellow"))
    }
    
    
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(NetworkMonitor())
    }
}
