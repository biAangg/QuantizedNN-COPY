// 📄 InferenceEngine.swift

import SwiftUI

protocol InferenceEngine {
    func analyze(_ image: UIImage) async throws -> ScreeningOutput
}

class MockInferenceEngine: InferenceEngine {
    var forcedOutput: ScreeningOutput = ScreeningOutput(signal: .lowConcern, confidence: 0.85, predictedClass: .melanocyticNevi)
    
    func analyze(_ image: UIImage) async throws -> ScreeningOutput {
        let delay = UInt64.random(in: 1_500_000_000...2_500_000_000)
        try await Task.sleep(nanoseconds: delay)
        return forcedOutput
    }
}

struct InferenceEngineKey: EnvironmentKey {
    static let defaultValue: any InferenceEngine = MockInferenceEngine()
}

extension EnvironmentValues {
    var inferenceEngine: any InferenceEngine {
        get { self[InferenceEngineKey.self] }
        set { self[InferenceEngineKey.self] = newValue }
    }
}
