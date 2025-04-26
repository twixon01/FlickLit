//
//  AddMediaView.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 21.04.2025.

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddMediaView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [MediaItem] = []
    @State private var selectedId: Int?
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var rating: Double = 5.0
    @State private var selectedType: MediaType = .movie

    private let tmdb = TMDBService()

    var selectedItem: MediaItem? {
        searchResults.first { $0.id == selectedId }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Тип медиа")) {
                    Picker("Тип", selection: $selectedType) {
                        Text("Фильм").tag(MediaType.movie)
                        Text("Сериал").tag(MediaType.tv)
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Поиск")) {
                    TextField("Название", text: $searchText)
                        .onSubmit { Task { await search() } }

                    if !searchResults.isEmpty {
                        Picker("Выберите медиа", selection: $selectedId) {
                            ForEach(searchResults, id: \.id) { item in
                                Text(item.title).tag(Optional(item.id))
                            }
                        }
                    }
                }

                if selectedItem != nil {
                    Section(header: Text("Информация")) {
                        DatePicker("Дата начала", selection: $startDate, displayedComponents: .date)
                        DatePicker("Дата окончания", selection: $endDate, displayedComponents: .date)

                        HStack {
                            Text("Оценка: \(Int(rating))")
                            Slider(value: $rating, in: 0...10, step: 1)
                        }
                    }

                    Section {
                        Button("Сохранить") {
                            if let item = selectedItem {
                                saveToFirestore(item: item)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Добавить медиа")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }

    private func search() async {
        do {
            switch selectedType {
            case .movie:
                searchResults = try await tmdb.searchMovies(searchText)
            case .tv:
                searchResults = try await tmdb.searchTVShows(searchText)
            case .book:
                searchResults = [] // later
            }
        } catch {
            print("Ошибка поиска: \(error.localizedDescription)")
        }
    }

    private func saveToFirestore(item: MediaItem) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let doc = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("mediaItems")
            .document("\(item.id)")

        let data: [String: Any] = [
            "mediaId": item.id,
            "watchedAtStart": Timestamp(date: startDate),
            "watchedAtEnd": Timestamp(date: endDate),
            "userRating": rating,
            "mediaType": selectedType.rawValue
        ]

        doc.setData(data) { error in
            if let error = error {
                print("Firestore erroor: \(error.localizedDescription)")
            } else {
                print("Saved Firestore: \(item.title)")
                dismiss()
            }
        }
    }
}
