//
//  CollectionView.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 16.04.2025.
//

import SwiftUI

struct CollectionView: View {
    @StateObject private var vm = CollectionViewModel()
    @State private var searchText = ""

    @State private var showingAvatarMenu   = false
    @State private var showingFiltersSheet = false
    @State private var showingAddSheet     = false

    @State private var selectedCategory: Category = .all
    @State private var showFilms = true
    @State private var showSeries = true
    @State private var showBooks = true
    @State private var dateFrom = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @State private var dateTo   = Date()

    enum Category: String, CaseIterable {
        case all    = "All"
        case films  = "Movies"
        case series = "TV Shows"
        case books  = "Books"
    }

    var filteredItems: [MediaItem] {
        vm.items.filter { item in
            switch selectedCategory {
            case .all:
                return true
            case .films:
                return item.mediaType == .movie
            case .series:
                return item.mediaType == .tv
            case .books:
                return item.mediaType == .book
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundGray")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        CollectionHeaderView(
                            showingAvatarMenu: $showingAvatarMenu,
                            showingFiltersSheet: $showingFiltersSheet,
                            showingAddSheet: $showingAddSheet,
                            selectedCategory: $selectedCategory,
                            showFilms: $showFilms,
                            showSeries: $showSeries,
                            showBooks: $showBooks,
                            dateFrom: $dateFrom,
                            dateTo: $dateTo,
                            vm: vm
                        )

                        SearchBar(searchText: $searchText) {
                            Task { await vm.search(searchText) }
                        }

                        Picker("Category", selection: $selectedCategory) {
                            ForEach(Category.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)

                        LazyVStack(spacing: 8) {
                            if vm.isLoading {
                                ProgressView().padding()
                            } else if let err = vm.errorMessage {
                                Text("Error: \(err)").foregroundColor(.red).padding()
                            } else {
                                ForEach(filteredItems) { item in
                                    FullListRow(item: item)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
                .refreshable { await vm.loadUserMediaItems() }
                .onAppear  { Task { await vm.loadUserMediaItems() } }
            }
            .navigationBarHidden(true)
            .environmentObject(vm)
        }
    }
}
