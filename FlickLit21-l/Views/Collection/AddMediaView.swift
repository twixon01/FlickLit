//
//  AddMediaView.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 21.04.2025.

import SwiftUI

struct AddMediaView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: CollectionViewModel

    @State private var searchText = ""
    @State private var searchResults = [MediaItem]()
    @State private var selectedItem: MediaItem?
    @State private var showDetail = false

    @State private var selectedType: MediaType = .movie

    @State private var debounceTask: Task<Void, Never>?

    private let tmdb = TMDBService.shared
    private let ol = OpenLibraryService.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Picker("Media Type", selection: $selectedType) {
                    Text("Movie").tag(MediaType.movie)
                    Text("TV Show").tag(MediaType.tv)
                    Text("Book").tag(MediaType.book)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))
                    TextField("Search", text: $searchText)
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: searchText) { newValue in
                            debounceTask?.cancel()
                            debounceTask = Task {
                                try? await Task.sleep(nanoseconds: 500_000_000)
                                await performSearch(newValue)
                            }
                        }
                }
                .padding(10)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                .padding(.horizontal, 16)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults.prefix(10)) { item in
                            Button {
                                selectedItem = item
                                showDetail = true
                            } label: {
                                SearchResultRow(item: item)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Spacer()
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        Task { await vm.loadUserMediaItems() }
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showDetail) {
                if let item = selectedItem {
                    AddMediaDetailView(item: item, isPresented: $showDetail)
                        .preferredColorScheme(.dark)
                }
            }
        }
    }

    private func performSearch(_ q: String) async {
        let query = q.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        do {
            switch selectedType {
            case .movie:
                searchResults = try await tmdb.searchMovies(query)
            case .tv:
                searchResults = try await tmdb.searchTVShows(query)
            case .book:
                searchResults = try await ol.searchBooks(query)
            }
        } catch {
            print("Ошибка поиска: \(error.localizedDescription)")
            searchResults = []
        }
    }
}

struct AddMediaView_Previews: PreviewProvider {
    static var previews: some View {
        AddMediaView()
            .preferredColorScheme(.dark)
    }
}
