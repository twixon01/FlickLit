//
//  Achievement.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 09.05.2025.
//

import Foundation

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let iconName: String
    let thresholds: [Int]
}

// прогресс пользователя /userAchievements/progress
struct UserAchievement: Decodable {
    let progress: [String:Int]
    let levels:   [String:Int]
}

// отображение
struct Achievement: Identifiable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
    let progressValue: Int
    let thresholds: [Int]
    let level: Int

    var progress: Double {
        let lower = level > 0 ? thresholds[level-1] : 0
        let upper = level < thresholds.count ? thresholds[level] : thresholds.last ?? lower
        guard upper > lower else { return 1 }
        return Double(progressValue - lower) / Double(upper - lower)
    }

    var lowerText: String { "\( level>0 ? thresholds[level-1] : 0 )" }
    var upperText: String { "\( level < thresholds.count ? thresholds[level] : thresholds.last ?? 0 )" }
}
