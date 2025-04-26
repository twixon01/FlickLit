//
//  FlickLit21_lApp.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 05.03.2025.
//

import SwiftUI


@main
struct FlickLit21_IApp: App {
    @StateObject private var networkMonitor = NetworkMonitor()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(networkMonitor)
        }
    }
}
