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
                .onTapGesture { noteFocused = false }
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
                            .onChange(of: rating) { _ in ratingSet = true }
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
        Text(item.overview.isEmpty ? "No description available." : item.overview)
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
            .lineLimit(5)
            .padding(.horizontal)
    }

    private var datePickerSection: some View {
        VStack(spacing: 16) {
            datePickerRow(
                label: item.mediaType == .book ? "Start read:" : "Start watch:",
                date: $startDate, show: $showStartPicker
            )
            datePickerRow(
                label: item.mediaType == .book ? "End read:" : "End watch:",
                date: $endDate, show: $showEndPicker
            )
        }
        .padding(.horizontal)
    }

    private func datePickerRow(label: String,
                               date: Binding<Date?>,
                               show: Binding<Bool>) -> some View {
        VStack(spacing: 4) {
            HStack {
                Spacer()
                Text(label).foregroundColor(.white)
                Button(date.wrappedValue.map { dateFormatter.string(from: $0) } ?? "Select") {
                    if date.wrappedValue == nil { date.wrappedValue = Date() }
                    withAnimation { show.wrappedValue.toggle() }
                }
                .foregroundColor(.yellow)
                Spacer()
            }
            if show.wrappedValue, let d = date.wrappedValue {
                DatePicker("", selection: Binding(
                    get: { d },
                    set: { date.wrappedValue = $0 }
                ), displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var noteSection: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.05)))
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
        let doc = Firestore.firestore().collection("users").document(uid).collection("mediaItems").document("\(item.id)")

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
                print("Save media error:", e.localizedDescription)
                return
            }

            // overview обновление
            updateStatsOnAdd(
                uid: uid,
                mediaType: item.mediaType,
                rating: ratingSet ? Int(rating) : nil,
                completedAt: endDate
            )

            // достижения
            var keys = [String]()
            switch item.mediaType {
            case .book: keys.append("readBooks")
            case .movie: keys.append("watchMovies")
            case .tv: keys.append("finishTVShows")
            }
            if ratingSet { keys.append("giveRatings") }
            keys.append("totalItems")

            AchievementsService().updateForEvent(uid: uid, keys: keys, delta: 1)
            isPresented = false
        }
    }

    private func updateStatsOnAdd(
        uid: String,
        mediaType: MediaType,
        rating: Int?,
        completedAt: Date?
    ) {
        let statsRef = Firestore.firestore()
            .collection("users").document(uid)
            .collection("stats").document("overview")

        Firestore.firestore().runTransaction({ tx, errPtr -> Any? in
            let snap: DocumentSnapshot
            do {
                snap = try tx.getDocument(statsRef)
            } catch let nsErr as NSError {
                errPtr?.pointee = nsErr
                return nil
            }

            let data = snap.data() ?? [:]
            var total = data["totalItems"] as? Int ?? 0
            var completed = data["completedItems"] as? Int ?? 0
            var avg = data["averageRating"]  as? Double ?? 0
            var byWeek = data["countsByWeek"] as? [String:Int] ?? [:]
            var byType = data["countsByType"] as? [String:Int] ?? [:]

            total += 1
            if completedAt != nil { completed += 1 }
            if let r = rating {
                let sumOld = avg * Double(total - 1)
                avg = (sumOld + Double(r)) / Double(total)
            }
            if let done = completedAt {
                let comps = Calendar.current
                    .dateComponents([.yearForWeekOfYear, .weekOfYear], from: done)
                if let y = comps.yearForWeekOfYear, let w = comps.weekOfYear {
                    let key = String(format: "%04d-W%02d", y, w)
                    byWeek[key, default: 0] += 1
                }
            }
            byType[mediaType.rawValue, default: 0] += 1

            tx.setData([
                "totalItems": total,
                "completedItems": completed,
                "averageRating": avg,
                "countsByWeek": byWeek,
                "countsByType": byType
            ], forDocument: statsRef, merge: true)

            return nil
        }, completion: { _, e in
            if let e = e {
                print("Stats tx error:", e.localizedDescription)
            }
        })
    }

    private func typeLabel(for type: MediaType) -> String {
        switch type {
        case .movie: return "Movie"
        case .tv: return "TV Show"
        case .book: return "Book"
        }
    }
}
