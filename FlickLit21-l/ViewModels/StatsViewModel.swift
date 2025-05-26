//
//  StatsViewModel.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 07.05.2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var stats: StatsModel?
    @Published var isLoading = false
    @Published var error: String?
    @Published var nickname: String = "USER"

    private let docRef: DocumentReference
    private var listeners: [ListenerRegistration] = []

    init() {
        let uid = Auth.auth().currentUser?.uid ?? ""
        let db  = Firestore.firestore()
        self.docRef = db
            .collection("users")
            .document(uid)
            .collection("stats")
            .document("overview")

        subscribeNickname()
    }

    deinit {
        listeners.forEach { $0.remove() }
    }

    private func subscribeNickname() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userDoc = Firestore.firestore().collection("users").document(uid)
        let listener = userDoc.addSnapshotListener { [weak self] snap, _ in
            if let nick = snap?.data()?["nickname"] as? String {
                self?.nickname = nick.uppercased()
            }
        }
        listeners.append(listener)
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let snap = try await docRef.getDocument()
            let data = snap.data() ?? [:]

            let total = data["totalItems"] as? Int ?? 0
            let completed = data["completedItems"]  as? Int ?? 0
            let average = data["averageRating"] as? Double ?? 0

            let byWeek = data["countsByWeek"] as? [String:Int] ?? [:]
            let byType = data["countsByType"] as? [String:Int] ?? [:]

            self.stats = StatsModel(
                totalItems: total,
                completedItems: completed,
                averageRating: average,
                countsByWeek: byWeek,
                countsByType: byType
            )
        } catch {
            self.error = error.localizedDescription
        }
    }
}
