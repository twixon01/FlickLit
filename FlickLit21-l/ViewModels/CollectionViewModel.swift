import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class CollectionViewModel: ObservableObject {
    @Published var items: [MediaItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let tmdb = TMDBService.shared
    private let ol = OpenLibraryService.shared
    private var allUserItems: [MediaItem] = []
    
    func loadUserMediaItems() async {
        isLoading = true
        errorMessage = nil

        FirestoreManager.shared.fetchUserMediaDocuments { [weak self] documents in
            Task { @MainActor in
                guard let self = self else { return }
                var result: [MediaItem] = []

                for doc in documents {
                    guard
                        let mediaId = doc["mediaId"] as? Int,
                        let rawType = doc["mediaType"] as? String,
                        let mediaType = MediaType(rawValue: rawType)
                    else { continue }

                    let startDate = (doc["watchedAtStart"] as? Timestamp)?.dateValue()
                    let endDate = (doc["watchedAtEnd"] as? Timestamp)?.dateValue()
                    let userRating = doc["userRating"] as? Int
                    let note = doc["note"] as? String

                    do {
                        var item: MediaItem
                        if mediaType == .book {
                            let books = try await self.ol.searchBooks(String(mediaId))
                            guard let found = books.first(where: { $0.id == mediaId }) else {
                                continue
                            }
                            item = found
                        } else {
                            item = try await self.tmdb.fetchMedia(by: mediaId, type: mediaType)
                        }

                        // user fields
                        item.startDate = startDate
                        item.endDate = endDate
                        item.userRating = userRating
                        item.note = note

                        result.append(item)
                    } catch {
                        print("Failed load media \(mediaId): \(error.localizedDescription)")
                    }
                }

                self.allUserItems = result
                self.items = result
                self.isLoading = false
            }
        }
    }

    func search(_ query: String) async {
        let t = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if t.isEmpty {
            items = allUserItems
        } else {
            items = allUserItems.filter {
                $0.title.lowercased().contains(t)
            }
        }
    }
}
