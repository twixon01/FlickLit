//
//  AchievementsViewModel.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 09.05.2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AchievementsViewModel: ObservableObject {
    @Published var items: [Achievement] = []
    @Published var nickname: String = "USER"

    private var defs: [String: AchievementDefinition] = [:]
    private var userAch = UserAchievement(progress: [:], levels: [:])
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []

    init() {
        subscribeDefinitions()
        subscribeUserProgress()
        subscribeUserProfile()
    }

    deinit {
        listeners.forEach { $0.remove() }
    }

    private func subscribeDefinitions() {
        let col = db.collection("achievements")
        listeners.append(col.addSnapshotListener { snap, _ in
            guard let docs = snap?.documents else { return }
            for d in docs {
                let data = d.data()
                let def = AchievementDefinition(
                    id: d.documentID,
                    title: data["title"] as? String ?? "",
                    subtitle: data["subtitle"] as? String ?? "",
                    iconName: data["iconName"] as? String ?? "",
                    thresholds: data["thresholds"]as? [Int] ?? []
                )
                self.defs[def.id] = def
            }
            self.rebuildItems()
        })
    }

    private func subscribeUserProgress() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let doc = db
            .collection("users").document(uid)
            .collection("userAchievements").document("progress")

        listeners.append(doc.addSnapshotListener { snap, _ in
            guard let data = snap?.data() else { return }
            self.userAch = UserAchievement(
                progress: data["progress"] as? [String:Int] ?? [:],
                levels: data["levels"] as? [String:Int] ?? [:]
            )
            self.rebuildItems()
        })
    }

    // ник
    private func subscribeUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let doc = db.collection("users").document(uid)
        listeners.append(doc.addSnapshotListener { snap, _ in
            guard let data = snap?.data() else { return }
            self.nickname = (data["nickname"] as? String ?? "USER").uppercased()
        })
    }

    // список для юи
    private func rebuildItems() {
        var out: [Achievement] = []
        for (id, def) in defs {
            let progVal = userAch.progress[id] ?? 0
            let lvlVal = userAch.levels[id]   ?? 0
            out.append(.init(
                id: id,
                icon: def.iconName,
                title: def.title,
                subtitle: def.subtitle,
                progressValue: progVal,
                thresholds: def.thresholds,
                level: lvlVal
            ))
        }
        self.items = out.sorted { $0.title < $1.title }
    }
}
