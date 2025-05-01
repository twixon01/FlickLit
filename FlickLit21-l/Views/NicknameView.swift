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
    @State private var showError: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    private var isValid: Bool {
        (3...16).contains(nickname.count)
    }

    var body: some View {
        ZStack {
            Color("BackgroundGray")
                .ignoresSafeArea()
                .onTapGesture { isTextFieldFocused = false }

            VStack(spacing: 24) {
                Text("Enter your nickname")
                    .font(.custom("SFProDisplay-Black", size: 36))
                    .foregroundColor(.white)

                TextField("3–16 characters", text: $nickname) {
                    isTextFieldFocused = false
                }
                .focused($isTextFieldFocused)
                .font(.custom("SFProDisplay-Semibold", size: 24))
                .padding()
                .frame(width: 280, height: 45)
                .background(Color(.darkGray))
                .cornerRadius(28)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.bottom, 16)

                Button(action: saveNickname) {
                    Text("Flick It!")
                        .font(.custom("SFProDisplay-Black", size: 30))
                        .foregroundColor(isValid ? .black : .gray)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 96)
                        .background(isValid ? Color.yellow : Color.gray.opacity(0.5))
                        .cornerRadius(32)
                }
                .disabled(!isValid)
                .padding(.horizontal, 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func saveNickname() {
        if isValid {
            authViewModel.saveNickname(nickname) {
                authViewModel.isNewUser = false
            }
        } else {
            showError = true
        }
    }
}

struct NicknameView_Previews: PreviewProvider {
    static var previews: some View {
        NicknameView()
            .environmentObject(AuthViewModel())
    }
}
