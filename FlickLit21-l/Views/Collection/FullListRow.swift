//
//  FullListRow.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 16.04.2025.
//

import SwiftUI

struct FullListRow: View {
    @State private var showDetail = false
    @EnvironmentObject private var vm: CollectionViewModel
    let item: MediaItem

    

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack(spacing: 12) {
                AsyncImage(url: item.posterURL) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
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

                    Text("Director: \(item.director)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)

                    let genresText = item.genreNames.isEmpty
                        ? "—"
                        : item.genreNames.prefix(2).joined(separator: ", ")
                    Text("\(item.year) • \(genresText)")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.6))

                    if let start = item.startDate {
                        Text("Start Watch: \(FullListRow.dateFormatter.string(from: start))")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    if let end = item.endDate {
                        Text("End Watch: \(FullListRow.dateFormatter.string(from: end))")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    if let userRating = item.userRating {
                        HStack(spacing: 4) {
                            Text("\(userRating)")
                                .font(.headline).bold()
                            Image(systemName: "star.fill")
                                .font(.headline)
                        }
                        .foregroundColor(.yellow)
                    }

                    HStack(spacing: 4) {
                        Text("\(item.rating)")
                        Image(systemName: "star.fill")
                    }
                    .font(.subheadline)
                    .foregroundColor(.yellow.opacity(0.5))
                }
                .padding(.trailing, 16)
            }
            .padding(.leading, 2)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.2))
            .cornerRadius(8)
        }
        .sheet(isPresented: $showDetail,
               onDismiss: {
            Task { await vm.loadUserMediaItems() }
        }
        ) {
            MediaDetailView(item: item, isPresented: $showDetail)
                .preferredColorScheme(.dark)
        }
    }
}
