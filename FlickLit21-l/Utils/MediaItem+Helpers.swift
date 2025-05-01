//
//  MediaItem+Helpers.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 30.04.2025.
//

import Foundation

extension MediaItem {
    var posterURL: URL? {
        switch mediaType {
        case .movie, .tv:
            guard let path = posterPath else { return nil }
            return URL(string: "https://image.tmdb.org/t/p/w185\(path)")
        case .book:
            return posterPath.flatMap(URL.init(string:))
        }
    }
}
