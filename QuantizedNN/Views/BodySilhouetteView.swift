// 📄 BodySilhouetteView.swift

import SwiftUI

// Segmented step progress bar shown in the scan wizard navigation bar.
struct ScanStepBar: View {
    let step: Int
    let total: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...total, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? DesignSystem.Colors.brand : DesignSystem.Colors.line)
                    .frame(width: 24, height: 3)
            }
        }
    }
}
