// 📄 PerformanceViewModel.swift

import SwiftUI
import Foundation
import UIKit

@Observable
final class PerformanceViewModel {
    // Mocked Latency Data (representing warm n=100 runs)
    let preprocessTime: Double = 4.1
    let inferenceTime: Double = 6.8
    let postprocessTime: Double = 2.2
    
    var p50Time: Double { preprocessTime + inferenceTime + postprocessTime }
    let p95Time: Double = 21.6
    let coldRunTime: Double = 204.0
    
    // Mocked Footprint Data
    let modelSizeMB: Double = 3.2
    let peakMemoryMB: Int = 41
    let precision: String = "INT8"
    
    // Mocked Residency Data
    let anePercentage: Int = 87
    let cpuPercentage: Int = 13
    
    struct LayerCompute {
        let name: String
        let processor: String
        let isFallback: Bool
    }
    
    let layerBreakdown: [LayerCompute] = [
        LayerCompute(name: "conv1–14", processor: "ANE", isFallback: false),
        LayerCompute(name: "dwconv15", processor: "ANE", isFallback: false),
        LayerCompute(name: "reduce16", processor: "CPU", isFallback: true),
        LayerCompute(name: "fc17", processor: "ANE", isFallback: false),
        LayerCompute(name: "softmax", processor: "CPU", isFallback: true)
    ]
    
    // Real iOS thermal states mapped to our UI
    let currentThermalState: ProcessInfo.ThermalState = ProcessInfo.processInfo.thermalState

    // Real battery telemetry via UIKit.
    // Phase 2: capture batteryLevelAtStart before inference and batteryLevelAfterInference
    // after N=100 repeated real inferences to get a meaningful drain signal.
    let batteryLevelAtStart: Float
    let batteryLevelAfterInference: Float

    var batteryDrainPercent: Float {
        max(0, (batteryLevelAtStart - batteryLevelAfterInference) * 100)
    }

    var batteryStateString: String {
        switch UIDevice.current.batteryState {
        case .charging:  return "Charging"
        case .unplugged: return "Unplugged"
        case .full:      return "Full"
        default:         return "Unknown"
        }
    }

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        batteryLevelAtStart = level
        batteryLevelAfterInference = level
    }
}
