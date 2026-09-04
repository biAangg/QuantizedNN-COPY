// 📄 CaptureSource.swift

import SwiftUI

protocol CaptureSource {
    var qualityChecks: AsyncStream<CaptureQuality> { get }
    func capture() async throws -> UIImage
}

class MockCaptureSource: CaptureSource {
    var qualityChecks: AsyncStream<CaptureQuality> {
        AsyncStream { continuation in
            continuation.yield(.framing(true))
            continuation.yield(.focus(false))
            continuation.yield(.lighting(false))
            
            Task {
                try await Task.sleep(nanoseconds: 1_500_000_000)
                continuation.yield(.focus(true))
                continuation.yield(.lighting(true))
            }
        }
    }
    
    func capture() async throws -> UIImage {
        return UIImage()
    }
}

struct CaptureSourceKey: EnvironmentKey {
    static let defaultValue: any CaptureSource = MockCaptureSource()
}

extension EnvironmentValues {
    var captureSource: any CaptureSource {
        get { self[CaptureSourceKey.self] }
        set { self[CaptureSourceKey.self] = newValue }
    }
}
