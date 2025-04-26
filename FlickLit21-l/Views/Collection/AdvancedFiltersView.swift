//
//  AdvancedFiltersView.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 20.04.2025.
//

import SwiftUI

struct AdvancedFiltersView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedCategory: CollectionView.Category
    @Binding var showFilms: Bool
    @Binding var showSeries: Bool
    @Binding var showBooks: Bool
    @Binding var dateFrom: Date
    @Binding var dateTo: Date

    var body: some View {
        NavigationView {
            Form {
                Section("Content Type") {
                    Toggle("Films", isOn: $showFilms)
                    Toggle("Series", isOn: $showSeries)
                    Toggle("Books", isOn: $showBooks)
                }
                Section("Category") {
                    Picker("", selection: $selectedCategory) {
                        ForEach(CollectionView.Category.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Date Range") {
                    DatePicker("From", selection: $dateFrom, displayedComponents: .date)
                    DatePicker("To", selection: $dateTo, displayedComponents: .date)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("FormBackgroundGray"))
            .navigationTitle("Advanced Filters")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
