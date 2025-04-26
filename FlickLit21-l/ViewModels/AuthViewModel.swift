//
//  AuthViewModel.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 26.04.2025.
//

import SwiftUI
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import FirebaseFirestore
import FirebaseCore

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isNewUser: Bool = false

    private let db = Firestore.firestore()

    init() {
        self.user = Auth.auth().currentUser
        validateSession()
    }

    func signInWithGoogle(presenting: UIViewController) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { result, error in
            if let error = error {
                print("Google Sign error: \(error.localizedDescription)")
                return
            }

            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { [weak self] result, error in
                if let error = error {
                    print("Firebase sign errror: \(error.localizedDescription)")
                    return
                }

                guard let self = self, let user = result?.user else { return }
                self.user = user

                let userRef = self.db.collection("users").document(user.uid)
                userRef.getDocument { snapshot, error in
                    if snapshot?.exists == true {
                        self.isNewUser = false
                    } else {
                        self.isNewUser = true
                    }
                }
            }
        }
    }

    func saveNickname(_ nickname: String, completion: @escaping () -> Void) {
        guard let user = Auth.auth().currentUser else { return }

        let userData: [String: Any] = [
            "nickname": nickname,
            "email": user.email ?? "",
            "createdAt": FieldValue.serverTimestamp()
        ]

        let userRef = db.collection("users").document(user.uid)

        userRef.setData(userData, merge: true) { error in
            if let error = error {
                print("Error saving user: \(error.localizedDescription)")
                return
            }

            let mediaItemRef = userRef.collection("mediaItems").document("initDoc")
            mediaItemRef.setData(["initializedAt": FieldValue.serverTimestamp()]) { error in
                if let error = error {
                    print("Error creating mediaItems/initDoc: \(error.localizedDescription)")
                }
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        self.user = nil
    }

// Если us удален
    private func validateSession() {
        Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { token, error in
            if let error = error {
                print("Invalid session: \(error.localizedDescription)")
                try? Auth.auth().signOut()
                DispatchQueue.main.async {
                    self.user = nil
                }
            }
        }
    }
}
