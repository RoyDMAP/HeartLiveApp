//
//  HeartRateStream.swift
//  HeartLiveApp
//
//  Created by Roy Dimapilis on 10/18/25.
//

import HealthKit
import Combine

final class HeartRateStream: NSObject, ObservableObject, HKLiveWorkoutBuilderDelegate {
    @Published var bpm: Int?
    @Published var state: HKWorkoutSessionState = .notStarted

    private let store: HKHealthStore
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    init(store: HKHealthStore) { self.store = store }

    func start() throws {
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .unknown

        let workoutSession = try HKWorkoutSession(healthStore: store, configuration: config)
        let workoutBuilder = workoutSession.associatedWorkoutBuilder()
        
        session = workoutSession
        builder = workoutBuilder

        workoutBuilder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
        workoutBuilder.delegate = self

        workoutSession.startActivity(with: Date())
        workoutBuilder.beginCollection(withStart: Date()) { _, _ in }
        state = .running
    }

    func pause() {
        session?.pause()
        state = .paused
    }

    func resume() {
        session?.resume()
        state = .running
    }

    func end() {
        session?.end()
        builder?.endCollection(withEnd: Date()) { _, _ in
            self.builder?.finishWorkout { _, _ in }
        }
        state = .ended
    }

    // MARK: - HKLiveWorkoutBuilderDelegate
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf types: Set<HKSampleType>) {
        guard types.contains(HKObjectType.quantityType(forIdentifier: .heartRate)!) else { return }
        let stats = workoutBuilder.statistics(for: .quantityType(forIdentifier: .heartRate)!)
        if let q = stats?.mostRecentQuantity() {
            let unit = HKUnit.count().unitDivided(by: .minute())
            let val = q.doubleValue(for: unit)
            DispatchQueue.main.async { self.bpm = Int(round(val)) }
        }
    }
}
