//
//  HeartRateVM.swift
//  HeartLiveApp
//
//  Created by Roy Dimapilis on 10/18/25.
//

import Foundation
import HealthKit
import Combine
import WatchKit

@MainActor
final class HeartRateVM: ObservableObject {
    @Published var bpmText: String = "--"
    @Published var status: String = "Not started"
    @Published var authorized: Bool = false
    @Published var recentBPM: [Int] = []

    private let hk = HealthKitService()
    private var stream: HeartRateStream?
    private var cancellables: Set<AnyCancellable> = []
    private let maxHistory = 24 // 2 minutes at 5s intervals

    func requestAuth() async {
        do {
            try await hk.requestAuthorization()
            authorized = true
            status = "Authorized"
        } catch {
            authorized = false
            status = "Not authorized"
        }
    }

    func start() {
        guard authorized else { status = "Not authorized"; return }
        stream = HeartRateStream(store: hk.store)
        
        stream?.$bpm
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in
                guard let self = self else { return }
                if let bpm = v {
                    self.bpmText = String(bpm)
                    self.recentBPM.append(bpm)
                    if self.recentBPM.count > self.maxHistory {
                        self.recentBPM.removeFirst()
                    }
                } else {
                    self.bpmText = "--"
                }
            }
            .store(in: &cancellables)
        
        stream?.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] st in self?.status = vmStatusText(st) }
            .store(in: &cancellables)
        
        do {
            try stream?.start()
            WKInterfaceDevice.current().play(.start)
        } catch {
            status = "Failed to start"
        }
    }

    func pause() {
        stream?.pause()
        WKInterfaceDevice.current().play(.stop)
    }
    
    func resume() {
        stream?.resume()
        WKInterfaceDevice.current().play(.start)
    }
    
    func end() {
        stream?.end()
        cancellables.removeAll()
        WKInterfaceDevice.current().play(.success)
    }
}

private func vmStatusText(_ st: HKWorkoutSessionState) -> String {
    switch st {
    case .running: return "Live"
    case .paused: return "Paused"
    case .ended: return "Ended"
    default: return "Not started"
    }
}
