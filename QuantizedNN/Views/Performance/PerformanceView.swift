// 📄 PerformanceView.swift

import SwiftUI

struct PerformanceView: View {
    @State private var viewModel = PerformanceViewModel()
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.m) {
                    latencyCard
                    footprintCard
                    residencyCard
                    thermalCard
                    batteryCard

                }
                .padding(.horizontal, DesignSystem.Spacing.m)
                .padding(.vertical, DesignSystem.Spacing.m)
            }
            .background(DesignSystem.Colors.bg.edgesIgnoringSafeArea(.all))
            .navigationTitle("Performance")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Subviews
    
    private var latencyCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("INFERENCE LATENCY · WARM · N=100")
                .font(.system(size: 9.5, weight: .bold))
                .textCase(.uppercase)
                .tracking(0.08)
                .foregroundColor(DesignSystem.Colors.ink3)
                .padding(.bottom, 8)
            
            // Stacked Bar Chart
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Color(hex: 0xA65B00).frame(width: geo.size.width * 0.31)
                        .overlay(Text("pre").font(.system(size: 8.5, design: .monospaced).weight(.bold)).foregroundColor(.white))
                    Color(hex: 0x7C3AED).frame(width: geo.size.width * 0.52)
                        .overlay(Text("inference").font(.system(size: 8.5, design: .monospaced).weight(.bold)).foregroundColor(.white))
                    Color(hex: 0x475569).frame(width: geo.size.width * 0.17)
                        .overlay(Text("post").font(.system(size: 8.5, design: .monospaced).weight(.bold)).foregroundColor(.white))
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .frame(height: 22)
            .padding(.bottom, 12)
            
            metricRow(label: "Preprocess", value: String(format: "%.1f", viewModel.preprocessTime), unit: "ms")
            metricRow(label: "Model inference", value: String(format: "%.1f", viewModel.inferenceTime), unit: "ms")
            metricRow(label: "Postprocess", value: String(format: "%.1f", viewModel.postprocessTime), unit: "ms")
            
            Divider().background(Color(hex: 0xF2F0F7)).padding(.vertical, 4)
            
            metricRow(label: "End-to-end p50", value: String(format: "%.1f", viewModel.p50Time), unit: "ms", isBold: true)
            metricRow(label: "End-to-end p95", value: String(format: "%.1f", viewModel.p95Time), unit: "ms")
            metricRow(label: "First (cold) run", value: String(format: "%.0f", viewModel.coldRunTime), unit: "ms")
        }
        .padding(13)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radii.medium)
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radii.medium).stroke(DesignSystem.Colors.line, lineWidth: 1))
    }
    
    private var footprintCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MODEL FOOTPRINT")
                .font(.system(size: 9.5, weight: .bold))
                .textCase(.uppercase)
                .tracking(0.08)
                .foregroundColor(DesignSystem.Colors.ink3)
                .padding(.bottom, 8)
            
            metricRow(label: "On-disk size", value: String(format: "%.1f", viewModel.modelSizeMB), unit: "MB")
            metricRow(label: "Peak memory", value: "\(viewModel.peakMemoryMB)", unit: "MB")
            metricRow(label: "Precision", value: viewModel.precision, unit: " weights", isBold: true)
        }
        .padding(13)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radii.medium)
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radii.medium).stroke(DesignSystem.Colors.line, lineWidth: 1))
    }
    
    private var residencyCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("WHERE EACH LAYER RAN")
                .font(.system(size: 9.5, weight: .bold))
                .textCase(.uppercase)
                .tracking(0.08)
                .foregroundColor(DesignSystem.Colors.ink3)
                .padding(.bottom, 8)
            
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Color(hex: 0x7C3AED).frame(width: geo.size.width * 0.87)
                        .overlay(Text("ANE 87%").font(.system(size: 8.5, design: .monospaced).weight(.bold)).foregroundColor(.white))
                    Color(hex: 0xA65B00).frame(width: geo.size.width * 0.13)
                        .overlay(
                            VStack(spacing: -2) {
                                Text("CPU").font(.system(size: 7.5, design: .monospaced).weight(.bold))
                                Text("13%").font(.system(size: 8.5, design: .monospaced).weight(.bold))
                            }.foregroundColor(.white)
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .frame(height: 22)
            .padding(.bottom, 12)
            
            ForEach(viewModel.layerBreakdown, id: \.name) { layer in
                HStack(spacing: 6) {
                    Text(layer.name)
                        .font(.system(size: 10, design: .monospaced))
                        .frame(width: 52, alignment: .leading)
                        .foregroundColor(layer.isFallback ? DesignSystem.Colors.watch : DesignSystem.Colors.ink)
                        .fontWeight(layer.isFallback ? .bold : .regular)
                    
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: 0xEEECF4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(layer.isFallback ? DesignSystem.Colors.watch : DesignSystem.Colors.brand2)
                                    .frame(width: geo.size.width, alignment: .leading)
                            )
                    }
                    .frame(height: 8)
                    
                    Text(layer.processor)
                        .font(.system(size: 9, design: .monospaced))
                        .frame(width: 38, alignment: .trailing)
                        .foregroundColor(layer.isFallback ? DesignSystem.Colors.watch : DesignSystem.Colors.ink3)
                }
                .padding(.vertical, 4)
            }
            

        }
        .padding(13)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radii.medium)
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radii.medium).stroke(DesignSystem.Colors.line, lineWidth: 1))
    }
    
    private var thermalCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("THERMAL STATE · PROCESSINFO")
                .font(.system(size: 9.5, weight: .bold))
                .textCase(.uppercase)
                .tracking(0.08)
                .foregroundColor(DesignSystem.Colors.ink3)
            
            HStack(spacing: 3) {
                thermalIndicator(label: "NOMINAL", isActive: viewModel.currentThermalState == .nominal || viewModel.currentThermalState == .fair) // Mocking active state
                thermalIndicator(label: "FAIR", isActive: false)
                thermalIndicator(label: "SERIOUS", isActive: false)
                thermalIndicator(label: "CRITICAL", isActive: false)
            }
            

        }
        .padding(13)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radii.medium)
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radii.medium).stroke(DesignSystem.Colors.line, lineWidth: 1))
    }
    
    private var batteryCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("BATTERY · ΔDRAIN · WARM · N=100")
                .font(.system(size: 9.5, weight: .bold))
                .textCase(.uppercase)
                .tracking(0.08)
                .foregroundColor(DesignSystem.Colors.ink3)
                .padding(.bottom, 8)

            let levelValue = viewModel.batteryLevelAtStart
            let levelString = levelValue < 0 ? "N/A" : "\(Int(levelValue * 100))"
            let levelUnit = levelValue < 0 ? "" : "%"
            metricRow(label: "Current level", value: levelString, unit: levelUnit)
            metricRow(label: "Charging state", value: viewModel.batteryStateString, unit: "")
            metricRow(label: "Δ drain (N=100 warm)", value: String(format: "%.2f", viewModel.batteryDrainPercent), unit: " pp", isBold: true)
        }
        .padding(13)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radii.medium)
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radii.medium).stroke(DesignSystem.Colors.line, lineWidth: 1))
    }

    private func metricRow(label: String, value: String, unit: String, isBold: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 12))
                .fontWeight(isBold ? .bold : .regular)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(value)
                    .font(.system(size: 12.5, design: .monospaced))
                    .fontWeight(.semibold)
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundColor(DesignSystem.Colors.ink3)
            }
        }
        .padding(.vertical, 5)
    }
    
    private func thermalIndicator(label: String, isActive: Bool) -> some View {
        Text(label)
            .font(.system(size: 8, design: .monospaced).weight(.bold))
            .tracking(0.03)
            .frame(maxWidth: .infinity)
            .frame(height: 24)
            .background(isActive ? DesignSystem.Colors.low : Color(hex: 0xEEECF4))
            .foregroundColor(isActive ? .white : DesignSystem.Colors.ink3)
            .cornerRadius(5)
    }
}

#Preview("PerformanceView") {
    PerformanceView()
}
