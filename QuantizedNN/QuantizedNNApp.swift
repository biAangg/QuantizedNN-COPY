// 📄 QuantizeNNApp.swift

import SwiftUI
import SwiftData

@main
struct QuantizeNNApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .modelContainer(for: ScanRecord.self, inMemory: true) // Using inMemory for prototype
                .environment(\.inferenceEngine, MockInferenceEngine())
                .environment(\.captureSource, MockCaptureSource())
        }
    }
}
