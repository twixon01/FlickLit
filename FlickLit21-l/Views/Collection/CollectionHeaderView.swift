//
//  CollectionHeaderView.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 16.04.2025.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CollectionHeaderView: View {
    @Binding var showingAvatarMenu: Bool
    @Binding var showingFiltersSheet: Bool
    @Binding var showingAddSheet: Bool

    @Binding var selectedCategory: CollectionView.Category
    @Binding var showFilms: Bool
    @Binding var showSeries: Bool
    @Binding var showBooks: Bool
    @Binding var dateFrom: Date
    @Binding var dateTo: Date

    let vm: CollectionViewModel
    
    @State private var nickname: String = ""

    var body: some View {
        HStack {
            Button { showingAvatarMenu = true } label: {
                Circle()
                    .stroke(Color.yellow, lineWidth: 1)
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(nickname.isEmpty ? "?" : String(nickname.prefix(1)))
                            .font(.title3)
                            .foregroundColor(.white)
                    )
            }
            .confirmationDialog("Profile", isPresented: $showingAvatarMenu) {
                Button("Change Avatar") {}
                Button("Settings") {}
                Button("Cancel", role: .cancel) {}
            }

            Text(nickname.isEmpty ? "..." : nickname)
                .font(.custom("SFProDisplay-Black", size: 20))
                .foregroundColor(.white)
                .padding(.leading, 8)

            Spacer()

            HStack(spacing: 24) {
                Button { showingFiltersSheet = true } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(.yellow)
                }
                .sheet(isPresented: $showingFiltersSheet) {
                    AdvancedFiltersView(
                        selectedCategory: $selectedCategory,
                        showFilms: $showFilms,
                        showSeries: $showSeries,
                        showBooks: $showBooks,
                        dateFrom: $dateFrom,
                        dateTo: $dateTo
                    )
                    .preferredColorScheme(.dark)
                }

                Button { showingAddSheet = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                }
                .sheet(
                  isPresented: $showingAddSheet,
                  onDismiss: {
                    Task { await vm.loadUserMediaItems() }
                  }
                ) {
                  AddMediaView()
                    .preferredColorScheme(.dark)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .onAppear(perform: loadNickname)
    }

    private func loadNickname() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let docRef = Firestore.firestore().collection("users").document(uid)
        docRef.getDocument { snapshot, error in
            if let data = snapshot?.data(), let name = data["nickname"] as? String {
                self.nickname = name
            } else {
                print("Failed load nickname: \(error?.localizedDescription ?? "something error")")
            }
        }
    }
}
