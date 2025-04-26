//
//  CategorySortPickers.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 17.03.2025.
//

import SwiftUI

struct CategorySortPickers: View {
    @Binding var selectedCategory: CollectionView.Category
   
    var body: some View {
        VStack(spacing: 8) {
            Picker("", selection: $selectedCategory) {
                ForEach(CollectionView.Category.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
        }
    }
}
