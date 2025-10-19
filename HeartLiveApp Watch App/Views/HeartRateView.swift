//
//  HeartRateView.swift
//  HeartLiveApp
//
//  Created by Roy Dimapilis on 10/18/25.
//

import SwiftUI

struct HeartRateView: View {
    @EnvironmentObject var vm: HeartRateVM
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 10) {
            Text("Heart")
                .font(.system(.caption, design: .rounded))
                .opacity(0.8)

            Text(vm.bpmText)
                .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)

            Text(vm.status)
                .font(.system(.footnote, design: .rounded))
                .opacity(0.7)

            if vm.recentBPM.count > 1 {
                SparklineView(data: vm.recentBPM)
                    .padding(.horizontal, 8)
            }

            if !vm.authorized {
                Button("Allow Health Access") { Task { await vm.requestAuth() } }
                    .buttonStyle(.borderedProminent)
            } else {
                HStack(spacing: 6) {
                    if vm.status == "Not started" || vm.status == "Ended" {
                        Button("Start") { vm.start() }
                    }
                    if vm.status == "Live" {
                        Button("Pause") { vm.pause() }
                    }
                    if vm.status == "Paused" {
                        Button("Resume") { vm.resume() }
                    }
                    if vm.status != "Not started" && vm.status != "Ended" {
                        Button("End") { vm.end() }
                    }
                }
                .buttonStyle(.bordered)
                .font(.system(.footnote, design: .rounded))
            }
        }
        .padding(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Heart rate")
        .accessibilityValue(vm.bpmText + " beats per minute")
        .accessibilityHint(vm.status)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && vm.status == "Paused" {
                vm.resume()
            } else if newPhase == .background && vm.status == "Live" {
                vm.pause()
            }
        }
    }
}

struct SparklineView: View {
    let data: [Int]
    
    var body: some View {
        GeometryReader { geo in
            Path { path in
                guard data.count > 1 else { return }
                let maxBPM = data.max() ?? 100
                let minBPM = data.min() ?? 60
                let range = max(maxBPM - minBPM, 1)
                let stepX = geo.size.width / CGFloat(data.count - 1)
                
                path.move(to: CGPoint(
                    x: 0,
                    y: geo.size.height * (1 - CGFloat(data[0] - minBPM) / CGFloat(range))
                ))
                
                for (i, bpm) in data.enumerated().dropFirst() {
                    let y = geo.size.height * (1 - CGFloat(bpm - minBPM) / CGFloat(range))
                    path.addLine(to: CGPoint(x: CGFloat(i) * stepX, y: y))
                }
            }
            .stroke(Color.red, lineWidth: 1.5)
        }
        .frame(height: 30)
    }
}
