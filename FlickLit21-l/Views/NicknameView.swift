//
//  NicknameView.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 05.03.2025.
//

import SwiftUI

struct NicknameView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var nickname: String = ""
    @State private var isValid = true

    var body: some View {
        ZStack {
            Color("BackgroundGray")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Text("Enter your nickname")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                TextField("3–16 characters", text: $nickname)
                    .padding()
                    .frame(height: 50)
                    .background(Color(.darkGray))
                    .cornerRadius(25)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(isValid ? Color.clear : Color.red, lineWidth: 1)
                    )
                    .padding(.horizontal, 30)

                Button(action: {
                    if nickname.count >= 3 && nickname.count <= 16 {
                        authViewModel.saveNickname(nickname) {
                            authViewModel.isNewUser = false
                        }
                    } else {
                        isValid = false
                    }
                }) {
                    Text("Flick it!")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(Color.yellow)
                        .cornerRadius(28)
                }
                .padding(.horizontal, 30)

                Spacer()
            }
        }
    }
}
