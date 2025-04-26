//
//  RootView.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 05.03.2025.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if networkMonitor.isOnline {
                if authViewModel.user == nil {
                    LoginView()
                        .environmentObject(authViewModel)
                } else if authViewModel.isNewUser {
                    NicknameView()
                        .environmentObject(authViewModel)
                } else {
                    MainTabView()
                        .environmentObject(authViewModel)
                }
            } else {
                OfflineView()
            }
        }
        .animation(.default, value: networkMonitor.isOnline)
    }
}


struct OfflineView: View {
    var body: some View {
        ZStack {
            Color("BackgroundGray")
                .ignoresSafeArea()

            Text("Нет соединения с интернетом")
                .font(.title2)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}
