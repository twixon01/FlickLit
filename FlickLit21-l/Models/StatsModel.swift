//
//  StatsModel.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 07.05.2025.
//

import Foundation

struct StatsModel: Codable {
    let totalItems: Int
    let completedItems: Int
    let averageRating: Double
    let countsByWeek: [String: Int]  // 2025-W10
    let countsByType: [String: Int]
}
