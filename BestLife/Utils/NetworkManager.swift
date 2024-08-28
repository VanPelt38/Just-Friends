//
//  NetworkManager.swift
//  BestLife
//
//  Created by Jake Gordon on 12/08/2024.
//

import Foundation
import Network

class NetworkManager {
    
    static let shared = NetworkManager()
    private var monitor: NWPathMonitor = NWPathMonitor()
    private var queue: DispatchQueue = DispatchQueue(label: "NetworkMonitor")
    var isConnected: Bool = false
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
          
            if path.status == .satisfied {
                isConnected = true
                print("connected!")
            } else {
                isConnected = false
                print("not connected!")
            }
        }
    }
    
    func startMonitoring() {
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
}
