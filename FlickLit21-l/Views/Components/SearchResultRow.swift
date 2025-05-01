//
//  SearchResultRow.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 01.05.2025.
//

import SwiftUI

struct SearchResultRow: View {
    let item: MediaItem

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: item.posterURL) { img in
                img
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.5)
            }
            .frame(width: 80, height: 120)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.7), radius: 6, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.custom("SFProDisplay-Black", size: 18))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                let genresText = item.genreNames.isEmpty
                    ? "—"
                    : item.genreNames.prefix(2).joined(separator: ", ")
                
                if item.mediaType != .book{
                    Text("\(item.year) • \(genresText)")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text("\(item.year)")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                }

                Text(item.overview)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            if item.rating != "—" {
                HStack(spacing: 4) {
                    Text(item.rating)
                        .font(.headline).bold()
                    Image(systemName: "star.fill")
                        .font(.headline)
                }
                .padding(.trailing, 16)
                .foregroundColor(.yellow)
            }
        }
        .padding(.leading, 2)
        .padding(.vertical, 2)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }
}
