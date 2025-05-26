//
//  MediaDetailViewModel.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 05.05.2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class MediaDetailViewModel: ObservableObject {
    // MARK: – Dependencies
    private let uid: String
    private let mediaType: MediaType
    private let itemRef: DocumentReference
    private let statsRef: DocumentReference
    private let achievements = AchievementsService()

    @Published var note: String
    @Published var startDate: Date?
    @Published var endDate: Date?
    @Published var userRating: Double

    private var noteTask: Task<Void, Never>?
    private var dateTask: Task<Void, Never>?
    private var ratingTask: Task<Void, Never>?

    private var originalRating: Int?
    private var originalCompleted: Date?

    init(item: MediaItem) {
        self.uid       = Auth.auth().currentUser?.uid ?? ""
        self.mediaType = item.mediaType

        let db = Firestore.firestore()
        self.itemRef  = db
          .collection("users").document(uid)
          .collection("mediaItems").document("\(item.id)")
        self.statsRef = db
          .collection("users").document(uid)
          .collection("stats").document("overview")

        self.note = item.note ?? ""
        self.startDate = item.startDate
        self.endDate = item.endDate
        self.userRating = Double(item.userRating ?? 0)

        // старые значения (с которыми зашли)
        self.originalRating   = item.userRating
        self.originalCompleted = item.endDate
    }

    func updateNote(_ new: String) {
        note = new
        noteTask?.cancel()
        noteTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await saveField(["note": new])
        }
    }

    func updateRating(_ new: Double) {
        userRating = new
        ratingTask?.cancel()
        ratingTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await saveField(["userRating": Int(new)])

            updateAverageRating(oldRating: originalRating, newRating: Int(new))

            // achievements: +1 только при первом выставлении оценки
            if originalRating == nil {
                achievements.updateForEvent(uid: uid,
                                            keys: ["giveRatings"],
                                            delta: 1)
            }
            originalRating = Int(new)
        }
    }

    private func updateAverageRating(oldRating: Int?, newRating: Int) {
        let db = Firestore.firestore()
        db.runTransaction({ tx, errPtr -> Any? in
            let snap: DocumentSnapshot
            do {
                snap = try tx.getDocument(self.statsRef)
            } catch let err as NSError {
                errPtr?.pointee = err
                return nil
            }
            let total = snap.get("totalItems") as? Int ?? 0
            let avg = snap.get("averageRating") as? Double ?? 0

            var newAvg = avg
            if let old = oldRating {
                // заменяем старый вклад
                let sumOld = avg * Double(total)
                let sumNew = sumOld - Double(old) + Double(newRating)
                newAvg = sumNew / Double(max(total,1))
            } else if total > 0 {
                // первый вклад
                newAvg = (avg * Double(total) + Double(newRating)) / Double(total)
            }

            tx.setData(["averageRating": newAvg], forDocument: self.statsRef, merge: true)
            return nil
        }, completion: { _, error in
            if let e = error {
                print("avg err:", e.localizedDescription)
            }
        })
    }

    func updateDate(_ date: Date, for field: String) {
        if field == "watchedAtStart" { startDate = date }
        else { endDate   = date }

        dateTask?.cancel()
        dateTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await saveField([field: Timestamp(date: date)])

            updateCompletion(oldDate: originalCompleted, newDate: date)

            // achievements: +1 при первом завершении
            if originalCompleted == nil {
                let key = {
                    switch mediaType {
                    case .book: return "readBooks"
                    case .movie: return "watchMovies"
                    case .tv: return "finishTVShows"
                    }
                }()
                achievements.updateForEvent(uid: uid,
                                            keys: [key],
                                            delta: 1)
            }
            originalCompleted = date
        }
    }

    private func updateCompletion(oldDate: Date?, newDate: Date) {
        let db = Firestore.firestore()
        db.runTransaction({ tx, errPtr -> Any? in
            let snap: DocumentSnapshot
            do {
                snap = try tx.getDocument(self.statsRef)
            } catch let err as NSError {
                errPtr?.pointee = err
                return nil
            }

            var completed = snap.get("completedItems") as? Int ?? 0
            var byWeek = snap.get("countsByWeek") as? [String:Int] ?? [:]
            var byType = snap.get("countsByType") as? [String:Int] ?? [:]

            if oldDate == nil {
                completed += 1
            }

            let comps = Calendar.current
                .dateComponents([.yearForWeekOfYear, .weekOfYear], from: newDate)
            if let y = comps.yearForWeekOfYear, let w = comps.weekOfYear {
                let weekKey = String(format: "%04d-W%02d", y, w)
                byWeek[weekKey, default: 0] += 1
            }

            byType[self.mediaType.rawValue, default: 0] += (oldDate == nil ? 1 : 0)

            tx.setData([
                "completedItems": completed,
                "countsByWeek": byWeek,
                "countsByType": byType
            ], forDocument: self.statsRef, merge: true)
            return nil
        }, completion: { _, error in
            if let e = error {
                print("completion error:", e.localizedDescription)
            }
        })
    }

    func deleteItem() async throws {
        // сам предмет
        try await itemRef.delete()

        // - из статистики
        runTotalItemsDelta(-1)

        // - достижения
        let typeKey: String = {
            switch mediaType {
            case .book: return "readBooks"
            case .movie: return "watchMovies"
            case .tv: return "finishTVShows"
            }
        }()

        var rollbackKeys = [ typeKey ]
        if originalRating != nil {
            rollbackKeys.append("giveRatings")
        }
        rollbackKeys.append("totalItems")

        achievements.updateForEvent(
            uid: uid,
            keys: rollbackKeys,
            delta: -1
        )
    }

    private func runTotalItemsDelta(_ delta: Int) {
        let db = Firestore.firestore()
        db.runTransaction({ (tx: Transaction, errPtr: NSErrorPointer) -> Any? in
            let snap: DocumentSnapshot
            do {
                snap = try tx.getDocument(self.statsRef)
            } catch let err as NSError {
                errPtr?.pointee = err
                return nil
            }

            let oldTotal = snap.get("totalItems") as? Int ?? 0
            var byType = snap.get("countsByType") as? [String:Int] ?? [:]

            let newTotal = max(oldTotal + delta, 0)
            byType[self.mediaType.rawValue, default: 0] += delta

            tx.setData([
                "totalItems": newTotal,
                "countsByType": byType
            ], forDocument: self.statsRef, merge: true)
            return nil
        }, completion: { _, error in
            if let e = error {
                print("totalItems err:", e.localizedDescription)
            }
        })
    }

    private func saveField(_ data: [String:Any]) async {
        do { try await itemRef.setData(data, merge: true) }
        catch { print("saveField err:", error.localizedDescription) }
    }

    private static func keysFor(mediaType: MediaType,
                                hadRating: Bool,
                                hadCompletion: Bool) -> [String]
    {
        var ks = [String]()
        if hadCompletion {
            switch mediaType {
                case .book: ks.append("readBooks")
                case .movie: ks.append("watchMovies")
                case .tv: ks.append("finishTVShows")
            }
        }
        if hadRating  { ks.append("giveRatings") }
        // totalItems меняем только при delete / initial add
        return ks
    }
}
