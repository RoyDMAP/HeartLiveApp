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
        VStack(spacing: 12) {
            // Header
            Text("Heart Rate")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.semibold)
            
            // Main BPM Display with Label
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(vm.bpmText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.7)
                    
                    Text("BPM")
                        .font(.system(.title3, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Text(vm.status)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.2))
                    )
            }

            // Sparkline with label
            if vm.recentBPM.count > 1 {
                VStack(spacing: 2) {
                    Text("Trend")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    SparklineView(data: vm.recentBPM)
                        .frame(height: 35)
                        .padding(.horizontal, 8)
                }
            }

            // Controls
            HStack(spacing: 8) {
                if vm.status == "Not started" || vm.status == "Ended" || vm.status.contains("Ready") {
                    Button(action: { vm.start() }) {
                        Label("Start", systemImage: "play.fill")
                            .font(.system(.caption, design: .rounded))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                
                if vm.status == "Live" {
                    Button(action: { vm.pause() }) {
                        Label("Pause", systemImage: "pause.fill")
                            .font(.system(.caption, design: .rounded))
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
                
                if vm.status == "Paused" {
                    Button(action: { vm.resume() }) {
                        Label("Resume", systemImage: "play.fill")
                            .font(.system(.caption, design: .rounded))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                
                if vm.status != "Not started" && vm.status != "Ended" && !vm.status.contains("Ready") {
                    Button(action: { vm.end() }) {
                        Label("End", systemImage: "stop.fill")
                            .font(.system(.caption, design: .rounded))
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
        .padding(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Heart rate monitor")
        .accessibilityValue(vm.bpmText + " beats per minute")
        .accessibilityHint(vm.status)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && vm.status == "Paused" {
                vm.resume()
            } else if newPhase == .background && vm.status == "Live" {
                vm.pause()
            }
        }
        .onAppear {
            Task { await vm.requestAuth() }
        }
    }
    
    // Helper for status color
    private var statusColor: Color {
        switch vm.status {
        case "Live": return .green
        case "Paused": return .orange
        case "Ended": return .red
        default: return .gray
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
            .stroke(Color.red, lineWidth: 2)
        }
    }
}
