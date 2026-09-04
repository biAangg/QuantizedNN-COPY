// 📄 RiskGlyph.swift

import SwiftUI

struct RiskGlyph: View {
    let signal: ScreeningSignal

    var body: some View {
        ZStack {
            switch signal {
            case .lowConcern:
                Circle().fill(DesignSystem.Colors.low)
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(.white)
            case .watch:
                Triangle().fill(DesignSystem.Colors.watch)
                Text("!")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(.white)
            case .getChecked:
                Octagon().fill(DesignSystem.Colors.getChecked)
                Text("!")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(.white)
            case .noClearSignal:
                Circle()
                    .strokeBorder(Color.white, style: StrokeStyle(lineWidth: 2.5, dash: [4]))
                    .background(Circle().fill(DesignSystem.Colors.noClearSignal))
                    .overlay(Circle().stroke(DesignSystem.Colors.noClearSignal, lineWidth: 2))
                Text("?")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 34, height: 34)
        .accessibilityLabel(signal.rawValue)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.04))
        path.addLine(to: CGPoint(x: rect.maxX * 0.96, y: rect.maxY * 0.94))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.maxY * 0.94))
        path.closeSubpath()
        return path
    }
}

struct Octagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.move(to: CGPoint(x: w * 0.3, y: h * 0.02))
        path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.02))
        path.addLine(to: CGPoint(x: w * 0.98, y: h * 0.3))
        path.addLine(to: CGPoint(x: w * 0.98, y: h * 0.7))
        path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.98))
        path.addLine(to: CGPoint(x: w * 0.3, y: h * 0.98))
        path.addLine(to: CGPoint(x: w * 0.02, y: h * 0.7))
        path.addLine(to: CGPoint(x: w * 0.02, y: h * 0.3))
        path.closeSubpath()
        return path
    }
}

#Preview("RiskGlyph") {
    HStack(spacing: DesignSystem.Spacing.l) {
        RiskGlyph(signal: .lowConcern)
        RiskGlyph(signal: .watch)
        RiskGlyph(signal: .getChecked)
        RiskGlyph(signal: .noClearSignal)
    }
    .padding()
    .background(DesignSystem.Colors.bg)
}
