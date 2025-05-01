import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MediaDetailView: View {
    let item: MediaItem
    @Binding var isPresented: Bool

    @State private var note: String
    @FocusState private var noteFocused: Bool
    @State private var saveNoteTask: Task<Void, Never>?

    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var showStartPicker = false
    @State private var showEndPicker = false
    @State private var saveDateTask: Task<Void, Never>?

    @State private var userRating: Double
    @State private var showRatingSlider = false
    @State private var saveRatingTask: Task<Void, Never>?

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    init(item: MediaItem, isPresented: Binding<Bool>) {
        self.item = item
        self._isPresented = isPresented
        self._note = State(initialValue: item.note ?? "")
        self._startDate = State(initialValue: item.startDate)
        self._endDate = State(initialValue: item.endDate)
        self._userRating = State(initialValue: Double(item.userRating ?? 0))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    posterAndInfo

                    // Описание до 5 строк режется
                    Text(item.overview.isEmpty ? "Описание недоступно." : item.overview)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(5)
                        .padding(.horizontal)

                    Divider()

                    datePickersSection
                    noteSection
                }
                .padding(.vertical)
                .onTapGesture { noteFocused = false }
            }
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .destructive) { deleteItem() } label: {
                        Image(systemName: "trash").foregroundColor(.red)
                    }
                }
            }
            // debounce сохранение заметки
            .onChange(of: note) { new in
                saveNoteTask?.cancel()
                saveNoteTask = Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    await saveField(["note": new])
                }
            }
        }
    }

    private var posterAndInfo: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: item.posterURL) { img in
                img.resizable()
                   .aspectRatio(contentMode: .fill)
                   .frame(width: 120, height: 180)
                   .cornerRadius(8)
                   .shadow(color: .black.opacity(0.45), radius: 6, x: 0, y: 3)
            } placeholder: {
                Color.gray.opacity(0.3)
                  .frame(width: 120, height: 180)
                  .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                  .font(.custom("SFProDisplay-Black", size: 20))
                  .lineLimit(2)

                Text(item.year)
                  .font(.custom("SFProDisplay-Semibold", size: 15))
                  .foregroundColor(.secondary)

                Text(typeLabel(for: item.mediaType))
                  .font(.custom("SFProDisplay-Semibold", size: 15))

                Text(item.mediaType == .book
                     ? "Author: \(item.director)"
                     : "Director: \(item.director)")
                  .font(.custom("SFProDisplay-Semibold", size: 15))

                let g = item.genreNames.prefix(2).joined(separator: ", ")
                Text("Genre: \(g.isEmpty ? "—" : g)")
                  .font(.custom("SFProDisplay-Semibold", size: 15))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 6) {
                    Text("\(Int(userRating))")
                      .font(.system(size: 18, weight: .bold))
                    Image(systemName: "star.fill")
                      .font(.system(size: 18))
                }
                .foregroundColor(.yellow)
                .onTapGesture { withAnimation { showRatingSlider.toggle() } }

                if showRatingSlider {
                    HStack {
                        Text("Your rating: \(Int(userRating))")
                          .foregroundColor(.white)
                        Slider(value: $userRating, in: 0...10, step: 1)
                          .tint(.yellow)
                          .onChange(of: userRating) { new in
                              saveRatingTask?.cancel()
                              saveRatingTask = Task {
                                  try? await Task.sleep(nanoseconds: 500_000_000)
                                  await saveField(["userRating": Int(new)])
                              }
                          }
                    }
                    .padding(.vertical, 4)
                }

                HStack(spacing: 6) {
                    Text(item.rating)
                    Image(systemName: "star.fill")
                }
                .font(.system(size: 14))
                .foregroundColor(.yellow.opacity(0.5))
            }
        }
        .padding(.horizontal)
    }

    private var datePickersSection: some View {
        VStack(spacing: 16) {
            pickerRow(
              label: item.mediaType == .book ? "Start read:" : "Start watch:",
              date: $startDate,
              show: $showStartPicker,
              field: "watchedAtStart"
            )
            pickerRow(
              label: item.mediaType == .book ? "End read:" : "End watch:",
              date: $endDate,
              show: $showEndPicker,
              field: "watchedAtEnd"
            )
        }
        .padding(.horizontal)
    }

    private func pickerRow(
      label: String,
      date: Binding<Date?>,
      show: Binding<Bool>,
      field: String
    ) -> some View {
        VStack(spacing: 4) {
            HStack {
                Spacer()
                Text(label).foregroundColor(.white)
                Button(date.wrappedValue.map { formatter.string(from: $0) } ?? "Select") {
                    if date.wrappedValue == nil { date.wrappedValue = Date() }
                    withAnimation { show.wrappedValue.toggle() }
                }
                .foregroundColor(.yellow)
                Spacer()
            }
            if show.wrappedValue, let d = date.wrappedValue {
                DatePicker(
                  "",
                  selection: Binding(
                    get: { d },
                    set: {
                      date.wrappedValue = $0
                      debounceSaveDate(field: field, date: $0)
                    }
                  ),
                  displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var noteSection: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
              .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1)
              .background(
                RoundedRectangle(cornerRadius: 20)
                  .fill(Color.black.opacity(0.05))
              )
            TextEditor(text: $note)
              .focused($noteFocused)
              .padding(16)
            if note.isEmpty {
              Text("Your note")
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .padding(.horizontal)
    }

    private func debounceSaveDate(field: String, date: Date) {
        saveDateTask?.cancel()
        saveDateTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await saveField([field: Timestamp(date: date)])
        }
    }

    private func saveField(_ data: [String: Any]) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let doc = Firestore.firestore()
          .collection("users").document(uid)
          .collection("mediaItems").document("\(item.id)")
        do {
            try await doc.setData(data, merge: true)
        } catch {
            print("Save error:", error.localizedDescription)
        }
    }

    private func deleteItem() {
        Task {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let doc = Firestore.firestore()
              .collection("users").document(uid)
              .collection("mediaItems").document("\(item.id)")
            try? await doc.delete()
            isPresented = false
        }
    }

    private func typeLabel(for t: MediaType) -> String {
      switch t {
        case .movie: return "Movie"
        case .tv: return "TV Show"
        case .book: return "Book"
      }
    }
}
