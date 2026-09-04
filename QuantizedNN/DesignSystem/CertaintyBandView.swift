// 📄 CertaintyBandView.swift

import SwiftUI

struct CertaintyBandView: View {
    let certainty: CertaintyBand
    let signal: ScreeningSignal
    let confidence: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Capsule()
                .fill(Color(hex: 0xE8E5F2))
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(activeColor)
                        .frame(height: 6)
                        .scaleEffect(x: confidence, anchor: .leading)
                }

            HStack {
                Text("model confidence")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.ink3)
                Spacer()
                Text("\(Int(confidence * 100))%")
                    .font(.system(.caption2, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(activeColor)
            }

            Text("Certainty is how sure the model is of its own output — not the chance this is harmless. Models can be confidently wrong.")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.ink2)
                .padding(.top, 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Model confidence: \(Int(confidence * 100))%.")
    }

    private var activeColor: Color {
        switch certainty {
        case .veryLow:  return DesignSystem.Colors.low
        case .low:      return DesignSystem.Colors.brand2
        case .moderate: return DesignSystem.Colors.watch
        case .high:     return Color(hex: 0xC0440E)
        case .veryHigh: return DesignSystem.Colors.getChecked
        }
    }
}

#Preview("Certainty Bands") {
    VStack(spacing: DesignSystem.Spacing.l) {
        CertaintyBandView(certainty: .veryHigh, signal: .lowConcern, confidence: 0.91)
        CertaintyBandView(certainty: .moderate, signal: .getChecked, confidence: 0.52)
        CertaintyBandView(certainty: .low, signal: .noClearSignal, confidence: 0.31)
    }
    .padding()
    .background(DesignSystem.Colors.surface)
}
