//
//  SearchBar.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 06.03.2025.
//

import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    var onSubmit: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.7))
            TextField("Search", text: $searchText)
                .foregroundColor(.white)
                .onSubmit { onSubmit() }
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
        .padding(.horizontal, 16)
    }
}
