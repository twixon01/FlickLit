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

            VStack(spacing: 24) {
                Spacer()

                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .cornerRadius(16)

                Text("Sign In")
                    .font(.custom("SFProDisplay-Black", size: 36))
                    .foregroundColor(.white)
                    .padding(.bottom, 16)

                Button(action: signInWithGoogle) {
                    HStack(spacing: 12) {
                        Image("google_logo")
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("Sign In with Google")
                            .font(.custom("SFProDisplay-Semibold", size: 18))
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 64)
                    .background(Color.yellow)
                    .cornerRadius(32)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func signInWithGoogle() {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = windowScene.windows.first?.rootViewController
        else {
            return
        }
        authViewModel.signInWithGoogle(presenting: rootVC)
    }
}
