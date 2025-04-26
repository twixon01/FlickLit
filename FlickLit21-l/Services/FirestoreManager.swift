//
//  FirestoreManager.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 26.04.2025.
//

import FirebaseAuth
import FirebaseFirestore

final class FirestoreManager {
    static let shared = FirestoreManager()

    private init() {}

    func fetchUserMediaIDs(completion: @escaping ([Int]) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("mediaItems")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Firestore error: \(error.localizedDescription)")
                    completion([])
                    return
                }

                let ids = snapshot?.documents.compactMap {
                    $0.data()["mediaId"] as? Int
                } ?? []

                completion(ids)
            }
    }
    
    func fetchUserMediaDocuments(completion: @escaping ([[String: Any]]) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("mediaItems")
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    let result = docs.map { $0.data() }
                    completion(result)
                } else {
                    completion([])
                }
            }
    }
}
