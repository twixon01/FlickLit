//
//  TMDBService.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 26.04.2025.
//

import Foundation

private struct TrendingResponse: Decodable {
    let results: [MediaResult]
}

private struct SearchResponse: Decodable {
    let results: [MediaResult]
}

private struct Genre: Decodable {
    let id: Int
    let name: String
}

private struct CreatedBy: Decodable {
    let name: String
}

private struct CreditsResponse: Decodable {
    let crew: [CrewMember]
}

private struct CrewMember: Decodable {
    let job: String
    let name: String
}

private struct MediaResult: Decodable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let releaseDate: String
    let voteAverage: Double
    let genreIDs: [Int]?
    let genres: [Genre]?
    let createdBy: [CreatedBy]?

    enum CodingKeys: String, CodingKey {
        case id, overview
        case posterPath = "poster_path"
        case voteAverage = "vote_average"
        case genreIDs = "genre_ids"
        case genres
        case title, name
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case createdBy = "created_by"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        overview = try c.decodeIfPresent(String.self, forKey: .overview) ?? ""
        posterPath = try c.decodeIfPresent(String.self, forKey: .posterPath)
        voteAverage = try c.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        genreIDs = try c.decodeIfPresent([Int].self, forKey: .genreIDs)
        genres = try c.decodeIfPresent([Genre].self, forKey: .genres)
        createdBy = try c.decodeIfPresent([CreatedBy].self, forKey: .createdBy)
        title = try c.decodeIfPresent(String.self, forKey: .title)
                   ?? c.decodeIfPresent(String.self, forKey: .name)
                   ?? "—"
        releaseDate = try c.decodeIfPresent(String.self, forKey: .releaseDate)
                   ?? c.decodeIfPresent(String.self, forKey: .firstAirDate)
                   ?? ""
    }
}

final class TMDBService {
    static let shared = TMDBService()
    private init() {}

    private let apiKey: String = Bundle.main
        .object(forInfoDictionaryKey: "TMDBApiKey") as? String ?? ""
    private let baseURL = URL(string: "https://api.themoviedb.org/3")!

    // локальный словарь для genre_ids
    private let genreMap: [Int: String] = [
        28: "Action", 12: "Adventure", 16: "Animation", 35: "Comedy",
        80: "Crime", 99: "Documentary", 18: "Drama", 10751: "Family",
        14: "Fantasy", 36: "History", 27: "Horror", 10402: "Music",
        9648: "Mystery", 10749: "Romance", 878: "Sci-Fi", 10770: "TV Movie",
        53: "Thriller", 10752: "War", 37: "Western"
    ]

    func fetchTrendingMovies() async throws -> [MediaItem] {
        let url = baseURL.appendingPathComponent("trending/movie/day")
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: "en-US")
        ]

        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        let resp = try JSONDecoder().decode(TrendingResponse.self, from: data)

        return try await resp.results.asyncMap { r in
            let year = String(r.releaseDate.prefix(4))
            // два жанра
            let allNames = r.genres?.map { $0.name }
                        ?? r.genreIDs?.compactMap { genreMap[$0] }
                        ?? []
            let names = Array(allNames.prefix(2))
            let director = try await fetchDirector(for: r.id)
            return MediaItem(
                id: r.id,
                title: r.title,
                year: year,
                genreNames: names,
                posterPath: r.posterPath,
                rating: String(format: "%.1f", r.voteAverage),
                director: director,
                overview: r.overview,
                mediaType: .movie
            )
        }
    }

    func searchMovies(_ query: String) async throws -> [MediaItem] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }

        let url = baseURL.appendingPathComponent("search/movie")
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: q),
            URLQueryItem(name: "language", value: "en-US")
        ]

        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        let resp = try JSONDecoder().decode(SearchResponse.self, from: data)

        return try await resp.results.asyncMap { r in
            let year = String(r.releaseDate.prefix(4))
            let allNames = r.genres?.map { $0.name }
                        ?? r.genreIDs?.compactMap { genreMap[$0] }
                        ?? []
            let names = Array(allNames.prefix(2))
            let director = try await fetchDirector(for: r.id)
            return MediaItem(
                id: r.id,
                title: r.title,
                year: year,
                genreNames: names,
                posterPath: r.posterPath,
                rating: String(format: "%.1f", r.voteAverage),
                director: director,
                overview: r.overview,
                mediaType: .movie
            )
        }
    }

    func searchTVShows(_ query: String) async throws -> [MediaItem] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }

        let url = baseURL.appendingPathComponent("search/tv")
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: q),
            URLQueryItem(name: "language", value: "en-US")
        ]

        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        let resp = try JSONDecoder().decode(SearchResponse.self, from: data)

        return try await resp.results.asyncMap { r in
            let year = String(r.releaseDate.prefix(4))
            let allNames = r.genres?.map { $0.name }
                        ?? r.genreIDs?.compactMap { genreMap[$0] }
                        ?? []
            let names = Array(allNames.prefix(2))
            let creator = r.createdBy?.map { $0.name }.joined(separator: ", ") ?? "—"
            return MediaItem(
                id: r.id,
                title: r.title,
                year: year,
                genreNames: names,
                posterPath: r.posterPath,
                rating: String(format: "%.1f", r.voteAverage),
                director: creator,
                overview: r.overview,
                mediaType: .tv
            )
        }
    }

    func fetchMovie(by id: Int) async throws -> MediaItem {
        try await fetchMedia(by: id, type: .movie)
    }
    func fetchTVShow(by id: Int) async throws -> MediaItem {
        try await fetchMedia(by: id, type: .tv)
    }

    func fetchMedia(by id: Int, type: MediaType) async throws -> MediaItem {
        let path = type == .tv ? "tv/\(id)" : "movie/\(id)"
        let url  = baseURL.appendingPathComponent(path)
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: "en-US")
        ]

        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        let r = try JSONDecoder().decode(MediaResult.self, from: data)

        let year = String(r.releaseDate.prefix(4))
        let names = r.genres?.map { $0.name } ?? []
        let two = Array(names.prefix(2))
        let director = type == .tv
            ? (r.createdBy?.map { $0.name }.joined(separator: ", ") ?? "—")
            : try await fetchDirector(for: r.id)

        return MediaItem(
            id: r.id,
            title: r.title,
            year: year,
            genreNames: two,
            posterPath: r.posterPath,
            rating: String(format: "%.1f", r.voteAverage),
            director: director,
            overview: r.overview,
            mediaType: type
        )
    }

    private func fetchDirector(for id: Int) async throws -> String {
        let url = baseURL.appendingPathComponent("movie/\(id)/credits")
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: "en-US")
        ]

        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        let resp = try JSONDecoder().decode(CreditsResponse.self, from: data)
        return resp.crew.first(where: { $0.job == "Director" })?.name ?? "—"
    }
}

private extension Array {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async throws -> [T] {
        var result: [T] = []
        result.reserveCapacity(count)
        for x in self {
            result.append(try await transform(x))
        }
        return result
    }
}
