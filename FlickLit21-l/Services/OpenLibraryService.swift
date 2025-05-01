//
//  OpenLibraryService.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 30.04.2025.
//

import Foundation

private struct OLSearchResponse: Decodable {
    let docs: [OLDoc]
}

private struct OLDoc: Decodable {
    let key: String
    let title: String
    let author_name: [String]?
    let first_publish_year: Int?
    let cover_i: Int?
}

final class OpenLibraryService {
    static let shared = OpenLibraryService()
    private init() {}

    func searchBooks(_ query: String) async throws -> [MediaItem] {
        guard let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://openlibrary.org/search.json?q=\(q)") else {
            return []
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let resp = try JSONDecoder().decode(OLSearchResponse.self, from: data)

        return resp.docs.map { doc in
            let rawKey = doc.key
                .split(separator: "/")
                .last.map(String.init) ?? ""
            let digits = rawKey.filter { $0.isNumber }
            let id = Int(digits) ?? 0
            
            let coverURL = doc.cover_i.map {
                "https://covers.openlibrary.org/b/id/\($0)-M.jpg"
            }

            return MediaItem(
                id: id,
                title: doc.title,
                year: String(doc.first_publish_year ?? 0),
                genreNames: [],
                posterPath: coverURL,
                rating: "—",
                director: doc.author_name?.joined(separator: ", ") ?? "—",
                overview: "",
                mediaType: .book
            )
        }
    }
}
