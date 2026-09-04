// 📄 ExportSheetView.swift

import SwiftUI
import LocalAuthentication
import UIKit

struct ExportSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let record: ScanRecord

    @State private var isAuthorized = false
    @State private var authError: String? = nil
    @State private var shareURL: URL? = nil
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.m) {
                    contentsCard
                    sensitivityWarning

                    if isAuthorized {
                        exportButton
                    } else {
                        authButton
                    }

                    if let error = authError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.getChecked)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignSystem.Spacing.xs)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.m)
                .padding(.top, DesignSystem.Spacing.m)
                .padding(.bottom, DesignSystem.Spacing.l)
            }
            .background(DesignSystem.Colors.bg.edgesIgnoringSafeArea(.all))
            .navigationTitle("Export for your doctor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ActivityView(items: [url], onComplete: { dismiss() })
                }
            }
        }
    }

    // MARK: - Subviews

    private var contentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("THIS DOCUMENT WILL CONTAIN")
                .font(.system(size: 9.5, weight: .bold))
                .textCase(.uppercase)
                .tracking(0.08)
                .foregroundColor(DesignSystem.Colors.ink3)

            VStack(alignment: .leading, spacing: 0) {
                contentRow("Scan reference", value: record.scanCode)
                contentRow("Date", value: formatDate(record.capturedAt))
                contentRow("Body site", value: record.bodySite.rawValue)
                contentRow("Screening signal", value: record.signal.rawValue)
                contentRow("Predicted class", value: record.predictedClass.rawValue)
                contentRow("Fitzpatrick type", value: "Type \(record.fitzpatrickType.romanNumeral) · \(record.fitzpatrickType.skinTone)")
                if let flags = abcdFlagsLabel {
                    contentRow("ABCD flags", value: flags)
                }
                contentRow("Model certainty", value: certaintyLabel)
                contentRow("Model confidence", value: confidenceLabel)
                contentRow("Capture image", value: "Original photo from scan")
                if !record.userNotes.isEmpty {
                    contentRow("Your notes", value: record.userNotes)
                }
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radii.medium)
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radii.medium).stroke(DesignSystem.Colors.line, lineWidth: 1))
    }

    private var sensitivityWarning: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SENSITIVE & CONFIDENTIAL")
                .font(.system(size: 9.5, weight: .bold))
                .textCase(.uppercase)
                .tracking(0.08)
                .foregroundColor(Color(hex: 0x7A1414))

            Text("Face ID or passcode is required to generate this PDF. Once shared, the exported file is not encrypted — you are responsible for who can access it and where it is stored. This app does not control what happens to the file after export.")
                .font(.system(size: 12.5))
                .foregroundColor(Color(hex: 0x7A1414))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.getCheckedWash)
        .cornerRadius(DesignSystem.Radii.medium)
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radii.medium).stroke(Color(hex: 0xF0C9C9), lineWidth: 1))
    }

    private var authButton: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Button(action: { requestAuth() }) {
                Label(authButtonTitle, systemImage: authButtonIcon)
                    .font(.system(size: 13.5, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(DesignSystem.Colors.brand)
                    .foregroundColor(.white)
                    .cornerRadius(11)
            }

            Text("Authentication is required before sharing sensitive data.")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.ink3)
                .multilineTextAlignment(.center)
        }
    }

    private var exportButton: some View {
        Button(action: { exportPDF() }) {
            Text("Share PDF")
                .font(.system(size: 13.5, weight: .bold))
                .tracking(-0.01)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(DesignSystem.Colors.brand)
                .foregroundColor(.white)
                .cornerRadius(11)
        }
    }

    // MARK: - Auth

    private var biometryType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        return context.biometryType
    }

    private var authButtonTitle: String {
        switch biometryType {
        case .faceID: return "Authenticate with Face ID"
        case .touchID: return "Authenticate with Touch ID"
        default: return "Authenticate with Passcode"
        }
    }

    private var authButtonIcon: String {
        switch biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.open.fill"
        }
    }

    private func requestAuth() {
        authError = nil
        let context = LAContext()
        let reason = "Confirm your identity before exporting sensitive scan data."
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
            Task { @MainActor in
                if success {
                    isAuthorized = true
                } else if let laError = error as? LAError,
                          [.userCancel, .systemCancel, .appCancel].contains(laError.code) {
                    authError = nil
                } else {
                    authError = error?.localizedDescription ?? "Authentication failed."
                }
            }
        }
    }

    // MARK: - PDF Export

    private func exportPDF() {
        guard let url = generatePDF() else { return }
        shareURL = url
        showShareSheet = true
    }

    private func generatePDF() -> URL? {
        let pageW: CGFloat = 612
        let pageH: CGFloat = 792
        let margin: CGFloat = 40
        let labelW: CGFloat = 140
        let valueX = margin + labelW + 8
        let rowH: CGFloat = 26

        var rows: [(String, String)] = [
            ("Scan reference", record.scanCode),
            ("Date", formatDate(record.capturedAt)),
            ("Body site", record.bodySite.rawValue),
            ("Screening signal", record.signal.rawValue),
            ("Predicted class", record.predictedClass.rawValue),
            ("Fitzpatrick type", "Type \(record.fitzpatrickType.romanNumeral) · \(record.fitzpatrickType.skinTone)"),
            ("Model certainty", certaintyLabel),
            ("Model confidence", confidenceLabel),
            ("Capture image", "Original photo from scan"),
        ]
        if let flags = abcdFlagsLabel {
            rows.insert(("ABCD flags", flags), at: 6)
        }
        if !record.userNotes.isEmpty {
            rows.append(("Your notes", record.userNotes))
        }

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.black,
        ]
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor(white: 0.45, alpha: 1),
        ]
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor(white: 0.45, alpha: 1),
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.black,
        ]
        let disclaimerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor(white: 0.55, alpha: 1),
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH))
        let data = renderer.pdfData { ctx in
            ctx.beginPage()

            var y: CGFloat = margin

            NSAttributedString(string: "QuantizedNN Scan Report", attributes: titleAttrs)
                .draw(in: CGRect(x: margin, y: y, width: pageW - 2 * margin, height: 26))
            y += 28

            NSAttributedString(string: "Generated by QuantizedNN · Research prototype", attributes: subtitleAttrs)
                .draw(in: CGRect(x: margin, y: y, width: pageW - 2 * margin, height: 18))
            y += 22

            let headerLine = UIBezierPath()
            headerLine.move(to: CGPoint(x: margin, y: y))
            headerLine.addLine(to: CGPoint(x: pageW - margin, y: y))
            headerLine.lineWidth = 0.5
            UIColor(white: 0.75, alpha: 1).setStroke()
            headerLine.stroke()
            y += 14

            for (label, value) in rows {
                NSAttributedString(string: label, attributes: labelAttrs)
                    .draw(in: CGRect(x: margin, y: y, width: labelW, height: rowH))
                NSAttributedString(string: value, attributes: valueAttrs)
                    .draw(in: CGRect(x: valueX, y: y, width: pageW - valueX - margin, height: rowH))
                y += rowH
            }

            let footerY = pageH - margin - 22
            let footerLine = UIBezierPath()
            footerLine.move(to: CGPoint(x: margin, y: footerY))
            footerLine.addLine(to: CGPoint(x: pageW - margin, y: footerY))
            footerLine.lineWidth = 0.5
            UIColor(white: 0.75, alpha: 1).setStroke()
            footerLine.stroke()

            NSAttributedString(
                string: "Screening tool output only — not a medical diagnosis. Consult a qualified dermatologist.",
                attributes: disclaimerAttrs
            ).draw(in: CGRect(x: margin, y: footerY + 6, width: pageW - 2 * margin, height: 18))
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(record.scanCode)_scan_report.pdf")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Helpers

    private func contentRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.ink3)
                    .frame(width: 108, alignment: .leading)
                Text(value)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 7)

            Rectangle()
                .fill(DesignSystem.Colors.line)
                .frame(height: 0.5)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .long
        return f.string(from: date)
    }

    private var certaintyLabel: String {
        switch record.certainty {
        case .veryLow: return "Very low"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .veryHigh: return "Very high"
        }
    }

    private var confidenceLabel: String {
        "\(Int(record.confidence * 100))%"
    }

    private var abcdFlagsLabel: String? {
        var flags: [String] = []
        if record.abcdAssessment.asymmetry { flags.append("Asymmetry") }
        if record.abcdAssessment.borderIrregularity { flags.append("Border irregularity") }
        if record.abcdAssessment.colorVariation { flags.append("Color variation") }
        if record.abcdAssessment.diameterOver6mm { flags.append("Diameter >6 mm") }
        return flags.isEmpty ? nil : flags.joined(separator: ", ")
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.completionWithItemsHandler = { _, completed, _, _ in
            if completed { onComplete?() }
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview("ExportSheetView") {
    let record = ScanRecord(
        scanCode: "SCN-0052",
        bodySite: .leftForearm,
        signal: .getChecked,
        certainty: .moderate,
        confidence: 0.52,
        predictedClass: .melanoma,
        fitzpatrickType: .IV,
        abcdAssessment: ABCDAssessment(asymmetry: true, borderIrregularity: true, colorVariation: true, diameterOver6mm: false),
        imageData: Data()
    )
    ExportSheetView(record: record)
}
