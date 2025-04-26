//
//  NetworkMonitor.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 26.04.2025.
//

import Foundation
import Network

final class NetworkMonitor: ObservableObject {

    @Published private(set) var isOnline: Bool = true


    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")


    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = (path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
