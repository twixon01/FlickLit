//
//  MainTabView.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 05.03.2025.
//

//  MainTabView.swift
import SwiftUI

struct MainTabView: View {
    // выбранный таб
    @State private var selectedTab: Tab = .collection

    enum Tab {
      case collection, stats, achievements
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            CollectionView()
                .tag(Tab.collection)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Collection")
                }

            StatsView()
                .tag(Tab.stats)
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("Stats")
                }

            AchievementsView()
                .tag(Tab.achievements)
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
