// 📄 ModelVariantsView.swift

import SwiftUI

struct ModelVariantsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.m) {
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("COMPARE · IPHONE 14 · N=100")
                        .font(.system(size: 9.5, weight: .bold))
                        .textCase(.uppercase)
                        .tracking(0.08)
                        .foregroundColor(DesignSystem.Colors.ink3)
                        .padding(.bottom, 8)
                    
                    // Table Header
                    HStack {
                        Text("VARIANT").frame(maxWidth: .infinity, alignment: .leading)
                        Text("SIZE").frame(maxWidth: .infinity, alignment: .trailing)
                        Text("p50").frame(maxWidth: .infinity, alignment: .trailing)
                        Text("ACC").frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .font(.system(size: 8.5, design: .monospaced))
                    .tracking(0.05)
                    .foregroundColor(DesignSystem.Colors.ink3)
                    .padding(.vertical, 6)
                    .border(width: 1, edges: [.bottom], color: DesignSystem.Colors.line)
                    
                    // Rows
                    variantRow(name: "FP32", size: "12.8MB", p50: "14.2ms", acc: "91.4%")
                    variantRow(name: "FP16", size: "6.4MB", p50: "12.9ms", acc: "91.4%")
                    variantRow(name: "INT8-w", size: "3.2MB", p50: "13.1ms", acc: "90.8%", isHighlighted: true)
                    
                    Text("**Expect this shape of result.** INT8 cuts size 4×; latency is roughly flat because the ANE computes in FP16 and dequantizes the weights anyway. That is a **finding**, not a failure — but only if you framed it as a question.")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.ink2)
                        .padding(10)
                        .background(DesignSystem.Colors.bg)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DesignSystem.Colors.line, lineWidth: 1))
                        .padding(.top, 10)
                }
                .padding(13)
                .background(DesignSystem.Colors.surface)
                .cornerRadius(DesignSystem.Radii.medium)
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radii.medium).stroke(DesignSystem.Colors.line, lineWidth: 1))
                
                ProvenanceCard(provenance: .guidance) {
                    Text("Ship this screen **behind a developer toggle**. It's for your defence, not for a patient checking a mole.")
                        .font(.body)
                        .foregroundColor(DesignSystem.Colors.ink2)
                }
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.m)
            .padding(.top, DesignSystem.Spacing.m)
        }
        .background(DesignSystem.Colors.bg.edgesIgnoringSafeArea(.all))
        .navigationTitle("Model variants")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func variantRow(name: String, size: String, p50: String, acc: String, isHighlighted: Bool = false) -> some View {
        HStack {
            Text(name).frame(maxWidth: .infinity, alignment: .leading)
            Text(size).frame(maxWidth: .infinity, alignment: .trailing)
            Text(p50).frame(maxWidth: .infinity, alignment: .trailing)
            Text(acc).frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.system(size: 10, design: .monospaced))
        .fontWeight(isHighlighted ? .bold : .regular)
        .foregroundColor(isHighlighted ? DesignSystem.Colors.brand : DesignSystem.Colors.ink)
        .padding(.vertical, 8)
        .background(isHighlighted ? DesignSystem.Colors.brandWash : Color.clear)
        .cornerRadius(isHighlighted ? 6 : 0)
        .border(width: isHighlighted ? 0 : 1, edges: [.bottom], color: Color(hex: 0xF2F0F7))
    }
}

// Helper to draw single-edge borders in SwiftUI easily
extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat { switch edge { case .top, .bottom, .leading: return rect.minX; case .trailing: return rect.maxX - width } }
            var y: CGFloat { switch edge { case .top, .leading, .trailing: return rect.minY; case .bottom: return rect.maxY - width } }
            var w: CGFloat { switch edge { case .top, .bottom: return rect.width; case .leading, .trailing: return width } }
            var h: CGFloat { switch edge { case .top, .bottom: return width; case .leading, .trailing: return rect.height } }
            path.addRect(CGRect(x: x, y: y, width: w, height: h))
        }
        return path
    }
}

#Preview("ModelVariantsView") {
    NavigationStack {
        ModelVariantsView()
    }
}
