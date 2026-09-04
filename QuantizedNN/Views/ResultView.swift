// 📄 ResultView.swift

import SwiftUI
import SwiftData

enum ResultMode {
    case capture(ScreeningOutput, BodySite, FitzpatrickType)
    case detail(ScanRecord)
}

struct ResultView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var path: NavigationPath
    let mode: ResultMode

    @State private var showExportSheet = false
    @State private var clinicalDetailExpanded = false

    // Extracted properties based on mode
    var signal: ScreeningSignal {
        switch mode {
        case .capture(let output, _, _): return output.signal
        case .detail(let record): return record.signal
        }
    }

    var certainty: CertaintyBand {
        switch mode {
        case .capture(let output, _, _): return CertaintyBand.from(confidence: output.confidence)
        case .detail(let record): return record.certainty
        }
    }

    var confidence: Double {
        switch mode {
        case .capture(let output, _, _): return output.confidence
        case .detail(let record): return record.confidence
        }
    }

    var predictedClass: LesionClass {
        switch mode {
        case .capture(let output, _, _): return output.predictedClass
        case .detail(let record): return record.predictedClass
        }
    }

    var fitzpatrickType: FitzpatrickType {
        switch mode {
        case .capture(_, _, let fitz): return fitz
        case .detail(let record): return record.fitzpatrickType
        }
    }

    /*
     var abcdAssessment: ABCDAssessment {
        switch mode {
        case .capture(_, _, _, let abcd): return abcd
        case .detail(let record): return record.abcdAssessment
        }
    }

    private var abcdFlagsLabel: String? {
        var flags: [String] = []
        if abcdAssessment.asymmetry { flags.append("Asymmetry") }
        if abcdAssessment.borderIrregularity { flags.append("Border irregularity") }
        if abcdAssessment.colorVariation { flags.append("Color variation") }
        if abcdAssessment.diameterOver6mm { flags.append("Diameter >6 mm") }
        return flags.isEmpty ? nil : flags.joined(separator: ", ")
    }
     */
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                
                // 1. Model Output Card
                ProvenanceCard(provenance: .model) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        HStack(spacing: 10) {
                            RiskGlyph(signal: signal)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Screening signal")
                                    .font(.system(size: 9, weight: .bold))
                                    .textCase(.uppercase)
                                    .tracking(0.09)
                                    .opacity(0.85)
                                Text(signal.rawValue)
                                    .font(.system(size: 16.5, weight: .bold))
                                    .tracking(-0.02)
                            }
                            Spacer()
                        }
                        .padding(11)
                        .background(signalBackground)
                        .foregroundColor(signalColor)
                        .cornerRadius(11)
                        
                    }
                }
                
                // 2. Guidance Card (Actionable Advice)
                ProvenanceCard(provenance: .guidance) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(guidanceHeader)
                            .font(.system(size: 9.5, weight: .semibold))
                            .textCase(.uppercase)
                            .tracking(0.08)
                            .foregroundColor(DesignSystem.Colors.ink3)
                        
                        Text(guidanceBody)
                            .font(.system(size: 12.5))
                            .lineSpacing(4)
                            .foregroundColor(DesignSystem.Colors.ink2)
                    }
                }
                
                // 3. Disclaimer Card (Strict rule: every value/text block wrapped)
                ProvenanceCard(provenance: .guidance) {
                    Text(disclaimerText)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(Color(hex: 0x7A1414))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DesignSystem.Colors.getCheckedWash)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: 0xF0C9C9), lineWidth: 1)
                        )
                }
                
                // Actions (Not wrapped, as they are controls, not values)
                actionButtons
                    .padding(.top, DesignSystem.Spacing.xs)

                // Subordinate clinical detail — not part of patient-facing result
                clinicalDetailSection
                    .padding(.top, DesignSystem.Spacing.xs)
            }
            .padding(.horizontal, DesignSystem.Spacing.m)
            .padding(.bottom, DesignSystem.Spacing.l)
        }
        .background(DesignSystem.Colors.bg.edgesIgnoringSafeArea(.all))
        .navigationTitle("Screening result")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExportSheet) {
            if let record = detailRecord {
                ExportSheetView(record: record)
            }
        }
    }

    private var detailRecord: ScanRecord? {
        if case .detail(let record) = mode { return record }
        return nil
    }
    
    // MARK: - Dynamic Content
    
    @ViewBuilder
    private var actionButtons: some View {
        switch mode {
        case .capture(let output, let site, _):
            if signal == .getChecked {
                primaryButton("Save & export for my doctor", color: DesignSystem.Colors.getChecked) { saveAndReset(output: output, site: site) }
                secondaryButton("Retake") { retake() }
            } else if signal == .noClearSignal {
                primaryButton("Retake in better light", color: DesignSystem.Colors.brand) { retake() }
                secondaryButton("Save & ask a dermatologist") { saveAndReset(output: output, site: site) }
            } else {
                primaryButton("Save to secure storage", color: DesignSystem.Colors.brand) { saveAndReset(output: output, site: site) }
                secondaryButton("Retake") { retake() }
            }
        case .detail:
            primaryButton("Export for your doctor", color: DesignSystem.Colors.brand) { showExportSheet = true }
        }
    }

    @ViewBuilder
    private var clinicalDetailSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) { clinicalDetailExpanded.toggle() }
            }) {
                HStack {
                    Text("For your doctor")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.ink3)
                    Spacer()
                    Image(systemName: clinicalDetailExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.ink3)
                }
                .padding(.vertical, 9)
                .padding(.horizontal, 12)
            }

            if clinicalDetailExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    clinicalRow(label: "Predicted class:", value: predictedClass.rawValue)
                    clinicalRow(label: "Fitzpatrick type:", value: "Type \(fitzpatrickType.romanNumeral) · \(fitzpatrickType.skinTone)")
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(DesignSystem.Colors.surface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(DesignSystem.Colors.line, lineWidth: 1)
        )
    }
    
    private func clinicalRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(DesignSystem.Colors.ink3)
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func primaryButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13.5, weight: .bold))
                .tracking(-0.01)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(11)
        }
    }
    
    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13.5, weight: .bold))
                .tracking(-0.01)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(DesignSystem.Colors.surface)
                .foregroundColor(DesignSystem.Colors.ink)
                .cornerRadius(11)
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(DesignSystem.Colors.line, lineWidth: 1.5))
        }
    }
    
    // MARK: - Styling & Text Properties
    
    private var signalBackground: Color {
        switch signal {
        case .lowConcern: return DesignSystem.Colors.lowWash
        case .watch: return DesignSystem.Colors.watchWash
        case .getChecked: return DesignSystem.Colors.getCheckedWash
        case .noClearSignal: return DesignSystem.Colors.noClearSignalWash
        }
    }
    
    private var signalColor: Color {
        switch signal {
        case .lowConcern: return DesignSystem.Colors.low
        case .watch: return DesignSystem.Colors.watch
        case .getChecked: return DesignSystem.Colors.getChecked
        case .noClearSignal: return DesignSystem.Colors.noClearSignal
        }
    }
    
    private var guidanceHeader: String {
        switch signal {
        case .getChecked: return "Next step"
        case .noClearSignal: return "Two options"
        default: return "What to do now"
        }
    }
    
    private var guidanceBody: LocalizedStringKey {
        switch signal {
        case .lowConcern, .watch:
            return "Keep watching this spot. Book a dermatologist if it **changes shape, colour, or size**, itches, or bleeds — regardless of what this app says."
        case .getChecked:
            return "Book a dermatologist. Most spots flagged this way turn out to be harmless — but this one should be looked at **by a person**, soon."
        case .noClearSignal:
            return "**Retake** in brighter, even light — poor images are the most common cause. If a retake gives the same result, **ask a dermatologist**. Don't treat this as reassurance."
        }
    }
    
    private var disclaimerText: String {
        "SCREENING ONLY — This result is not a medical diagnosis. It is produced by an AI model and has not been reviewed by a clinician. Always consult a dermatologist before making any health decisions."
    }
    
    // MARK: - Routing Actions
    
    private func saveAndReset(output: ScreeningOutput, site: BodySite) {
        let newRecord = ScanRecord(
            scanCode: "SCN-\(Int.random(in: 1000...9999))",
            bodySite: site,
            signal: output.signal,
            certainty: CertaintyBand.from(confidence: output.confidence),
            confidence: output.confidence,
            predictedClass: output.predictedClass,
            fitzpatrickType: fitzpatrickType,

            imageData: Data()
        )
        modelContext.insert(newRecord)
        
        // Reset NavigationStack to Root
        path = NavigationPath()
        // (In full implementation, trigger a Toast overlay here)
    }
    
    private func retake() {
        path = NavigationPath()
    }
}

#Preview("ResultView - Low Concern") {
    @Previewable @State var path = NavigationPath()
    NavigationStack {
        ResultView(path: $path, mode: .capture(
            ScreeningOutput(signal: .lowConcern, confidence: 0.88, predictedClass: .melanocyticNevi),
            .leftForearm, .III
        ))
    }
}

#Preview("ResultView - Get Checked") {
    @Previewable @State var path = NavigationPath()
    NavigationStack {
        ResultView(path: $path, mode: .capture(
            ScreeningOutput(signal: .getChecked, confidence: 0.55, predictedClass: .melanoma),
            .rightForearm, .IV
        ))
    }
}
