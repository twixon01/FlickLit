//
//  AchievementsService.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 09.05.2025.
//

import FirebaseFirestore

struct AchievementsService {
    private let db = Firestore.firestore()

    
    func updateForEvent(uid: String, keys: [String], delta: Int = 1) {
        let userAchRef = db
            .collection("users").document(uid)
            .collection("userAchievements").document("progress")

        db.runTransaction({ tx, errorPtr -> Any? in
            let uaSnap: DocumentSnapshot
            do {
                uaSnap = try tx.getDocument(userAchRef)
            } catch let err as NSError {
                errorPtr?.pointee = err
                return nil
            }
            let uaData = uaSnap.data() ?? [:]
            var prog = uaData["progress"] as? [String:Int] ?? [:]
            var levels = uaData["levels"] as? [String:Int] ?? [:]

            for key in keys {
                prog[key, default: 0] += delta
                if prog[key]! < 0 { prog[key] = 0 }
            }

            // пересчет уровней по delta (выше) по каждому ключу
            for key in keys {
                let achRef = db.collection("achievements").document(key)
                let achSnap: DocumentSnapshot
                do {
                    achSnap = try tx.getDocument(achRef)
                } catch let err as NSError {
                    errorPtr?.pointee = err
                    return nil
                }
                let thresholds = achSnap.get("thresholds") as? [Int] ?? []
                // уровень = число порогов, которые мы уже прошли
                let passed = thresholds.filter { prog[key, default: 0] >= $0 }.count
                levels[key] = passed
            }

            // запись обратно
            tx.setData([
                "progress": prog,
                "levels": levels,
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: userAchRef, merge: true)

            return nil

        }, completion: { _, error in
            if let error = error {
                print("Achievements error:", error.localizedDescription)
            }
        })
    }
}
