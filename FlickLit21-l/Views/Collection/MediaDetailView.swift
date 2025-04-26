import SwiftUI

struct MediaDetailView: View {
    let item: MediaItem
    @Binding var isPresented: Bool
    @State private var note: String = ""
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 12) {
                        AsyncImage(
                            url: URL(string: "https://image.tmdb.org/t/p/w300\(item.posterPath ?? "")")
                        ) { img in
                            img.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 180)
                                .clipped()
                                .cornerRadius(8)
                                .shadow(color: .black.opacity(0.45), radius: 6, x: 0, y: 3)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                                .frame(width: 120, height: 180)
                                .cornerRadius(8)
                                .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
                        }
                        
                     
                        ZStack(alignment: .topTrailing) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.custom("SFProDisplay-Black", size: 20))
                                    .lineLimit(2)
                                
                                Text(item.year)
                                    .font(.custom("SFProDisplay-Black", size: 15))
                                    .foregroundColor(.secondary)
                                
                                Text(typeLabel(for: item.mediaType))
                                    .font(.custom("SFProDisplay-Semibold", size: 15))
                                
                                Text("Created by: \(item.director)")
                                    .font(.custom("SFProDisplay-Semibold", size: 15))
                                
                                Text("Genre: \(item.genreNames.first ?? "—")")
                                    .font(.custom("SFProDisplay-Semibold", size: 15))
                                
                                if item.startDate != nil || item.endDate != nil {
                                    VStack(alignment: .leading, spacing: 2) {
                                        if let start = item.startDate {
                                            Text("Start Date: \(FullListRow.dateFormatter.string(from: start))")
                                        }
                                        if let end = item.endDate {
                                            Text("End Date: \(FullListRow.dateFormatter.string(from: end))")
                                        }
                                    }
                                    .font(.custom("SFProDisplay-Heavy", size: 16))
                                    .padding(.top, 6)
                                }
                            }
                            .frame(maxWidth: .infinity,
                                   alignment: .leading)
                            .padding(.trailing, 42.5)
                            
                            VStack(alignment: .trailing, spacing: 8) {
                                if let userRating = item.userRating {
                                    HStack(spacing: 6) {
                                        Text("\(userRating)")
                                            .font(.system(size: 18, weight: .bold))
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 18))
                                    }
                                    .foregroundColor(.yellow)
                                }
                                
                                HStack(spacing: 6) {
                                    Text("\(item.rating)")
                                    Image(systemName: "star.fill")
                                }
                                .font(.system(size: 14))
                                .foregroundColor(.yellow.opacity(0.5))
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(.trailing, 8)
            

              
                    Divider()

                    Text(item.overview.isEmpty ? "Описание недоступно." : item.overview)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)

                   
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.black.opacity(0.05))
                            )

                        TextEditor(text: $note)
                            .padding(16)
                            .background(Color.clear)
                            .opacity(note.isEmpty ? 0.85 : 1)

                        if note.isEmpty {
                            Text("Your note")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 18)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    
                }
                .padding()
            }
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("Delete item?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    isPresented = false // after
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this item?")
            }
        }
    }

    private func typeLabel(for type: MediaType) -> String {
        switch type {
        case .movie: return "Movie"
        case .tv: return "TV Show"
        case .book: return "Book"
        }
    }
}
