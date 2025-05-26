//
//  AchievementsView.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 05.03.2025.
//

import SwiftUI

struct AchievementsView: View {
    @StateObject private var vm = AchievementsViewModel()
    @State private var selected: Achievement?

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 16),
        count: 3
    )

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(vm.nickname)'S")
                    .font(.custom("SFProDisplay-Black", size: 40))
                Text("ACHIEVEMENTS")
                    .font(.custom("SFProDisplay-Black", size: 40))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
            .background(Color("BackgroundGray"))

            // достижения
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(vm.items) { ach in
                        AchievementCell(achievement: ach) {
                            selected = ach
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
        .navigationBarHidden(true)
        .background(Color("BackgroundGray").ignoresSafeArea())
        .sheet(item: $selected) { ach in
            // icon из выбранного достижения
            TooltipView(
                iconName: ach.icon,
                title: ach.title,
                subtitle: ach.subtitle,
                level: ach.level
            )
        }
    }
}


// при тапе на карточку
struct TooltipView: View {
    let iconName: String
    let title: String
    let subtitle: String
    let level: Int

    var body: some View {
        ZStack {
            Color("BackgroundGray")
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(levelColor())

                Text(title)
                    .font(.title2).bold()
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(24)
            .cornerRadius(16)
            .padding(.horizontal, 32)
        }
    }

    private func levelColor() -> Color {
        switch level {
        case 1: return .brown
        case 2: return .gray
        case 3: return .yellow
        default: return .white.opacity(0.5)
        }
    }
}
