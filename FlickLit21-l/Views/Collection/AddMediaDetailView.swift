//
//  AddMediaDetailView.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 28.04.2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AddMediaDetailView: View {
    let item: MediaItem
    @Binding var isPresented: Bool

    @State private var startDate: Date? = nil
    @State private var endDate: Date? = nil

    @State private var rating: Double = 5
    @State private var ratingSet = false
    @State private var showRatingSlider = false

    @State private var note: String = ""

    @State private var showStartPicker = false
    @State private var showEndPicker = false

    @FocusState private var noteFocused: Bool

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    posterAndInfo

                    descriptionSection
                    Divider()

                    datePickerSection

                    noteSection
                }
                .padding(.vertical)
                .onTapGesture {
                    noteFocused = false
                }
            }
            .background(Color("BackgroundGray"))
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveToFirestore() }
                }
            }
        }
    }

    private var posterAndInfo: some View {
        HStack(alignment: .top, spacing: 16) {
            AsyncImage(url: item.posterURL) { img in
                img.resizable()
                   .aspectRatio(contentMode: .fill)
                   .frame(width: 120, height: 180)
                   .clipped()
                   .cornerRadius(8)
                   .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
            } placeholder: {
                Color.gray.opacity(0.3)
                    .frame(width: 120, height: 180)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.title)
                        .font(.custom("SFProDisplay-Black", size: 20))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    Spacer()
                    Button {
                        withAnimation { showRatingSlider.toggle() }
                    } label: {
                        Image(systemName: ratingSet ? "star.fill" : "star")
                            .font(.system(size: 24))
                            .foregroundColor(.yellow)
                    }
                }
                if showRatingSlider {
                    HStack {
                        Text("Your rating: \(Int(rating))")
                            .foregroundColor(.white)
                        Slider(value: $rating, in: 0...10, step: 1)
                          .tint(.yellow)
                          .onChange(of: rating) {
                            ratingSet = true
                          }
                    }
                    .padding(.vertical, 4)
                }

                Text(item.year)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(typeLabel(for: item.mediaType))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(item.mediaType == .book
                     ? "Author: \(item.director)"
                     : "Director: \(item.director)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                let genres = item.genreNames.prefix(2).joined(separator: ", ")
                Text("Genre: \(genres.isEmpty ? "—" : genres)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private var descriptionSection: some View {
        Text(item.overview.isEmpty
             ? "No description available."
             : item.overview)
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
            .lineLimit(5)
            .padding(.horizontal)
    }

    private var datePickerSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                HStack {
                    Spacer()
                    Text(item.mediaType == .book ? "Start read:" : "Start watch:")
                        .foregroundColor(.white)
                    Button(startDate.map { dateFormatter.string(from: $0) } ?? "Select") {
                        if startDate == nil { startDate = Date() }
                        withAnimation { showStartPicker.toggle() }
                    }
                    .foregroundColor(.yellow)
                    Spacer()
                }
                if showStartPicker, let binding = Binding($startDate) {
                    DatePicker(
                        "",
                        selection: binding,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: 4) {
                HStack {
                    Spacer()
                    Text(item.mediaType == .book ? "End read:" : "End watch:")
                        .foregroundColor(.white)
                    Button(endDate.map { dateFormatter.string(from: $0) } ?? "Select") {
                        if endDate == nil { endDate = Date() }
                        withAnimation { showEndPicker.toggle() }
                    }
                    .foregroundColor(.yellow)
                    Spacer()
                }
                if showEndPicker, let binding = Binding($endDate) {
                    DatePicker(
                        "",
                        selection: binding,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
    }

    private var noteSection: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.05))
                )
            TextEditor(text: $note)
                .focused($noteFocused)
                .padding(12)
            if note.isEmpty {
                Text("Your note")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
        }
        .frame(height: 140)
        .padding(.horizontal)
    }

    private func saveToFirestore() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let doc = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("mediaItems")
            .document("\(item.id)")

        var data: [String: Any] = [
            "mediaId": item.id,
            "mediaType": item.mediaType.rawValue,
            "note": note
        ]
        if ratingSet { data["userRating"] = Int(rating) }
        if let d = startDate { data["watchedAtStart"] = Timestamp(date: d) }
        if let d = endDate { data["watchedAtEnd"] = Timestamp(date: d) }

        doc.setData(data, merge: true) { error in
            if let e = error {
                print("Ошибка сохранения:", e.localizedDescription)
            } else {
                isPresented = false
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
