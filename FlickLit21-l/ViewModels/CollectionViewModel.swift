import SwiftUI
import FirebaseAuth
import FirebaseFirestore

final class CollectionViewModel: ObservableObject {
    @Published var items: [MediaItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let tmdb = TMDBService()
    private var allUserItems: [MediaItem] = []

    func loadTrending() async {
        isLoading = true
        do {
            items = try await tmdb.fetchTrendingMovies()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadUserMediaItems() async {
        isLoading = true
        errorMessage = nil

        FirestoreManager.shared.fetchUserMediaDocuments { [weak self] documents in
            Task {
                guard let self = self else { return }

                var result: [MediaItem] = []

                for doc in documents {
                    guard let mediaId = doc["mediaId"] as? Int else { continue }

                    let startDate = (doc["watchedAtStart"] as? Timestamp)?.dateValue()
                    let endDate = (doc["watchedAtEnd"] as? Timestamp)?.dateValue()
                    let userRating = doc["userRating"] as? Int
                    let mediaTypeRaw = doc["mediaType"] as? String
                    guard let mediaType = MediaType(rawValue: mediaTypeRaw ?? "") else { continue }

                    do {
                        var item = try await self.tmdb.fetchMedia(by: mediaId, type: mediaType)
                        item.startDate = startDate
                        item.endDate = endDate
                        item.userRating = userRating
                        result.append(item)
                    } catch {
                        print("Failed load media \(mediaId): \(error.localizedDescription)")
                    }
                }

                DispatchQueue.main.async {
                    self.allUserItems = result
                    self.items = result
                    self.isLoading = false
                }
            }
        }
    }

    func search(_ query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            items = allUserItems
        } else {
            items = allUserItems.filter {
                $0.title.lowercased().contains(trimmed.lowercased())
            }
        }
    }
}
