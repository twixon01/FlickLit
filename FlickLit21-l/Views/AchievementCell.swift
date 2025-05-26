//
//  AchievementCell.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 09.05.2025.
//

import SwiftUI

struct AchievementCell: View {
    let achievement: Achievement
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(color(for: achievement.level))
                .opacity(achievement.level == 0 ? 0.5 : 1)

            Text(achievement.title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            HStack(spacing: 4) {
                Text(achievement.lowerText)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                ProgressView(value: achievement.progress)
                    .frame(height: 4)
                    .tint(.yellow)

                Text(achievement.upperText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture(perform: onTap)
    }

    private func color(for level: Int) -> Color {
        switch level {
        case 1: return .brown
        case 2: return .gray
        case 3: return .yellow
        default: return .white
        }
    }
}
