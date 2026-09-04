// 📄 ProvenanceCard.swift

import SwiftUI

struct ProvenanceCard<Content: View>: View {
    let provenance: Provenance
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            tagView
            content
        }
        .padding(13)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radii.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radii.medium)
                .stroke(DesignSystem.Colors.line, lineWidth: 1)
        )
        .overlay(
            leftRail,
            alignment: .leading
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radii.medium))
    }
    
    @ViewBuilder
    private var leftRail: some View {
        if provenance == .guidance {
            Line()
                .stroke(style: StrokeStyle(lineWidth: 3, dash: [4, 4]))
                .frame(width: 3)
                .foregroundColor(Color(hex: 0xC9C4DC))
        } else {
            Rectangle()
                .fill(indicatorColor)
                .frame(width: 3)
        }
    }
    
    @ViewBuilder
    private var tagView: some View {
        HStack(spacing: 4) {
            Text(tagIcon)
            Text(tagText)
        }
        .font(.system(.caption2, design: .monospaced).weight(.semibold))
        .textCase(.uppercase)
        .tracking(0.07)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(tagBackground)
        .foregroundColor(tagColor)
        .cornerRadius(4)
    }
    
    // MARK: - Styling Helpers
    
    private var tagIcon: String {
        switch provenance { case .model: return "◆"; case .user: return "●"; case .guidance: return "○" }
    }
    
    private var tagText: String {
        switch provenance { case .model: return "Model"; case .user: return "You"; case .guidance: return "Guide" }
    }
    
    private var tagBackground: Color {
        switch provenance {
        case .model: return DesignSystem.Colors.brandWash
        case .user: return DesignSystem.Colors.noClearSignalWash
        case .guidance: return Color(hex: 0xF2F0F7)
        }
    }
    
    private var tagColor: Color {
        switch provenance {
        case .model: return DesignSystem.Colors.brand
        case .user: return DesignSystem.Colors.noClearSignal
        case .guidance: return DesignSystem.Colors.ink3
        }
    }
    
    private var indicatorColor: Color {
        switch provenance {
        case .model: return DesignSystem.Colors.brand2
        case .user: return DesignSystem.Colors.noClearSignal
        case .guidance: return Color.clear
        }
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path
    }
}

#Preview("ProvenanceCard Variations") {
    VStack(spacing: DesignSystem.Spacing.m) {
        ProvenanceCard(provenance: .model) {
            Text("This is a model output.")
                .font(.body)
                .foregroundColor(DesignSystem.Colors.ink2)
        }
        ProvenanceCard(provenance: .user) {
            Text("This is user-provided data.")
                .font(.body)
                .foregroundColor(DesignSystem.Colors.ink2)
        }
        ProvenanceCard(provenance: .guidance) {
            Text("This is static guidance text.")
                .font(.body)
                .foregroundColor(DesignSystem.Colors.ink2)
        }
    }
    .padding()
    .background(DesignSystem.Colors.bg)
}
