//
//  HealthKitService.swift
//  HeartLiveApp
//
//  Created by Roy Dimapilis on 10/18/25.
//

import HealthKit

enum HKError: Error { case notAvailable, notAuthorized }

final class HealthKitService: NSObject {
    let store = HKHealthStore()
    private let heartType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { throw HKError.notAvailable }
        try await store.requestAuthorization(toShare: [], read: [heartType])
        let status = store.authorizationStatus(for: heartType)
        guard status == .sharingAuthorized else { throw HKError.notAuthorized }
    }
}
