//
//  AchievementsView.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 05.03.2025.
//

import SwiftUI

struct AchievementsView: View {
    var body: some View {
        NavigationView {
            Text("Achievements Screen")
                .font(.title)
                .foregroundColor(.white)
                .navigationTitle("Achievements")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("BackgroundGray"))
                .ignoresSafeArea()
        }
    }
}

struct AchievementsView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementsView()
    }
}
