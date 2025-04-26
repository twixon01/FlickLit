//
//  LoginView.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 05.03.2025.
//

import SwiftUI
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            Color("BackgroundGray")
                .ignoresSafeArea()

            VStack {
                Spacer()

                Text("Вход в FlickLit")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)

                Spacer()

                GoogleSignInButton {
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let rootVC = windowScene.windows.first?.rootViewController else {
                        return
                    }
                    authViewModel.signInWithGoogle(presenting: rootVC)
                }
                .frame(height: 50)
                .padding()

                Spacer()
            }
        }
    }
}
