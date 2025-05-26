import SwiftUI

struct MediaDetailView: View {
    let item: MediaItem
    @Binding var isPresented: Bool

    @StateObject private var vm: MediaDetailViewModel
    @FocusState private var noteFocused: Bool

    @State private var showStartPicker = false
    @State private var showEndPicker = false
    @State private var showRatingSlider = false
    @State private var showDeleteAlert = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    init(item: MediaItem, isPresented: Binding<Bool>) {
        self.item = item
        self._isPresented = isPresented
        self._vm = StateObject(wrappedValue: MediaDetailViewModel(item: item))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    posterAndInfo

                    Text(item.overview.isEmpty ? "Описание недоступно." : item.overview)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(5)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)

                    Divider()

                    datePickerSection
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
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("Are you sure you want to delete this item?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    Task {
                        try? await vm.deleteItem()
                        isPresented = false
                    }
                }
                Button("Cancel", role: .cancel) {}
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

                let genres = item.genreNames.prefix(2).joined(separator: ", ")
                Text("Genre: \(genres.isEmpty ? "—" : genres)")
                    .font(.custom("SFProDisplay-Semibold", size: 15))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 6) {
                    Text("\(Int(vm.userRating))")
                        .font(.system(size: 18, weight: .bold))
                    Image(systemName: "star.fill")
                        .font(.system(size: 18))
                }
                .foregroundColor(.yellow)
                .onTapGesture { withAnimation { showRatingSlider.toggle() } }

                if showRatingSlider {
                    HStack {
                        Text("Your rating: \(Int(vm.userRating))")
                            .foregroundColor(.white)
                        Slider(value: $vm.userRating, in: 0...10, step: 1)
                            .tint(.yellow)
                            .onChange(of: vm.userRating) { vm.updateRating($0) }
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

    private var datePickerSection: some View {
        VStack(spacing: 16) {
            pickerRow(
                label: item.mediaType == .book ? "Start read:" : "Start watch:",
                date: $vm.startDate,
                show: $showStartPicker,
                field: "watchedAtStart"
            )
            pickerRow(
                label: item.mediaType == .book ? "End read:" : "End watch:",
                date: $vm.endDate,
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
                Button(date.wrappedValue.map { dateFormatter.string(from: $0) } ?? "Select") {
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
                        vm.updateDate($0, for: field)
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
                .background(RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.05)))
            TextEditor(text: $vm.note)
                .focused($noteFocused)
                .padding(16)
                .onChange(of: vm.note) { vm.updateNote($0) }
            if vm.note.isEmpty {
                Text("Your note")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
            }
        }
        .frame(height: 160)
        .padding(.horizontal)
    }

    private func typeLabel(for t: MediaType) -> String {
      switch t {
        case .movie: return "Movie"
        case .tv: return "TV Show"
        case .book: return "Book"
      }
    }
}
