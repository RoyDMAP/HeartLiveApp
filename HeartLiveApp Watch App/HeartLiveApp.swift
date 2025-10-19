//
//  HeartLiveAppApp.swift
//  HeartLiveApp Watch App
//
//  Created by Roy Dimapilis on 10/18/25.
//

import SwiftUI

@main
struct HeartLiveApp: App {
    @StateObject private var vm = HeartRateVM()
    var body: some Scene {
        WindowGroup {
            HeartRateView()
                .environmentObject(vm)
        }
    }
}
