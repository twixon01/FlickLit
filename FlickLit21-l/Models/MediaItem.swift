//
//  MediaItem.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 26.04.2025.
//

import Foundation

enum MediaType: String, Codable {
    case movie
    case tv
    case book
}

struct MediaItem: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let year: String
    let genreNames: [String]
    let posterPath: String?
    let rating: String
    let director: String
    var startDate: Date? = nil
    var endDate: Date? = nil
    var userRating: Int? = nil
    let overview: String
    var mediaType: MediaType
    
}
