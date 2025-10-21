//
//  HeartRateVM.swift
//  HeartLiveApp
//
//  Created by Roy Dimapilis on 10/18/25.
//

import Foundation
import Combine
import WatchKit

@MainActor
final class HeartRateVM: ObservableObject {
    @Published var bpmText: String = "--"
    @Published var status: String = "Not started"
    @Published var authorized: Bool = true  // Always authorized for mock mode
    @Published var recentBPM: [Int] = []

    private var cancellables: Set<AnyCancellable> = []
    private let maxHistory = 24 // 2 minutes at 5s intervals
    
    // Mock data
    private var mockTimer: Timer?
    private var currentBPM = 72

    func requestAuth() async {
        // Mock authorization - always succeeds
        authorized = true
        status = "Ready (Mock Mode)"
    }

    func start() {
        status = "Live"
        mockTimer?.invalidate()
        
        // Generate initial realistic heart rate
        currentBPM = Int.random(in: 65...85)
        
        mockTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // Simulate realistic heart rate variation
                let change = Int.random(in: -3...3)
                self.currentBPM = max(55, min(120, self.currentBPM + change))
                
                self.bpmText = String(self.currentBPM)
                self.recentBPM.append(self.currentBPM)
                if self.recentBPM.count > self.maxHistory {
                    self.recentBPM.removeFirst()
                }
            }
        }
        
        // Fire immediately for first reading
        bpmText = String(currentBPM)
        recentBPM.append(currentBPM)
        
        WKInterfaceDevice.current().play(.start)
    }

    func pause() {
        mockTimer?.invalidate()
        status = "Paused"
        WKInterfaceDevice.current().play(.stop)
    }
    
    func resume() {
        status = "Live"
        mockTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                let change = Int.random(in: -3...3)
                self.currentBPM = max(55, min(120, self.currentBPM + change))
                
                self.bpmText = String(self.currentBPM)
                self.recentBPM.append(self.currentBPM)
                if self.recentBPM.count > self.maxHistory {
                    self.recentBPM.removeFirst()
                }
            }
        }
        WKInterfaceDevice.current().play(.start)
    }
    
    func end() {
        mockTimer?.invalidate()
        mockTimer = nil
        status = "Ended"
        WKInterfaceDevice.current().play(.success)
    }
    
    func reset() {
        mockTimer?.invalidate()
        mockTimer = nil
        bpmText = "--"
        status = "Not started"
        recentBPM.removeAll()
        currentBPM = 72
        WKInterfaceDevice.current().play(.click)
    }
}
