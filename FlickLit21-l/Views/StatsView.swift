//
//  StatsView.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 05.03.2025.
//

import SwiftUI

struct StatsView: View {
    var body: some View {
        NavigationView {
            Text("Stats Screen")
                .font(.title)
                .foregroundColor(.white)
                .navigationTitle("Stats")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("BackgroundGray"))
                .ignoresSafeArea()
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
