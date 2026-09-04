// 📄 HistoryViewModel.swift

import SwiftUI
import LocalAuthentication

@Observable
final class HistoryViewModel {
    var isUnlocked: Bool
    var authError: String? = nil

    init(startUnlocked: Bool = false) {
        isUnlocked = startUnlocked
    }

    /// The biometry available on this device, used to label the unlock button.
    /// Only populated after canEvaluatePolicy has run on the context.
    var biometryType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        return context.biometryType
    }

    func authenticate() {
        authError = nil
        let context = LAContext()
        let reason = "Unlock your encrypted scan history."

        // .deviceOwnerAuthentication is the standard system flow: biometrics
        // first when enrolled, with the device passcode as built-in fallback.
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
            Task { @MainActor in
                if success {
                    self.isUnlocked = true
                } else if let laError = authenticationError as? LAError,
                          [.userCancel, .systemCancel, .appCancel].contains(laError.code) {
                    // The user dismissed the sheet — not an error worth surfacing
                    self.authError = nil
                } else {
                    self.authError = authenticationError?.localizedDescription ?? "Authentication failed."
                }
            }
        }
    }

    func lock() {
        isUnlocked = false
    }
}
