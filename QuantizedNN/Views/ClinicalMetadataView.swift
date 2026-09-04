// 📄 ClinicalMetadataView.swift

import SwiftUI

struct ClinicalMetadataView: View {
    @Binding var path: NavigationPath
    let bodySite: BodySite

    @State private var selectedFitzpatrick: FitzpatrickType? = nil
    @State private var abcd = ABCDAssessment()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {

                // MARK: Header
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text("Clinical details")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("These help contextualise the model output for a clinician.")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.ink3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, DesignSystem.Spacing.xs)

                // MARK: Fitzpatrick Picker
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                    sectionLabel("SKIN TYPE (FITZPATRICK SCALE)")

                    if let selected = selectedFitzpatrick {
                        fitzpatrickSummary(selected)
                    } else {
                        VStack(spacing: 7) {
                            ForEach(FitzpatrickType.allCases, id: \.self) { type in
                                fitzpatrickRow(type)
                            }
                        }
                    }
                }

                // MARK: ABCD Section — slides in after skin type is chosen
                if selectedFitzpatrick != nil {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        sectionLabel("ABCD FEATURES")

                        VStack(spacing: 0) {
                            abcdRow(
                                label: "Asymmetry",
                                hint: "One half of the spot doesn't match the other.",
                                isOn: $abcd.asymmetry
                            )
                            rowDivider()
                            abcdRow(
                                label: "Border irregularity",
                                hint: "Edges are ragged, notched, or blurred.",
                                isOn: $abcd.borderIrregularity
                            )
                            rowDivider()
                            abcdRow(
                                label: "Color variation",
                                hint: "Multiple shades of brown, black, red, white, or blue.",
                                isOn: $abcd.colorVariation
                            )
                            rowDivider()
                            abcdRow(
                                label: "Diameter > 6 mm",
                                hint: "Larger than a pencil eraser (~6 mm).",
                                isOn: $abcd.diameterOver6mm
                            )
                        }
                        .padding(.horizontal, 13)
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(DesignSystem.Radii.medium)
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radii.medium).stroke(DesignSystem.Colors.line, lineWidth: 1))
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer(minLength: DesignSystem.Spacing.l)

                // MARK: Continue
                Button(action: {
                    if let fitz = selectedFitzpatrick {
                        path.append(ScanRoute.analyzing(bodySite, fitz))
                    }
                }) {
                    Text("Continue")
                        .font(.body)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.s)
                        .background(selectedFitzpatrick != nil ? DesignSystem.Colors.brand : Color(hex: 0xE8E5F2))
                        .foregroundColor(selectedFitzpatrick != nil ? .white : Color(hex: 0xA8A3BE))
                        .cornerRadius(11)
                }
                .disabled(selectedFitzpatrick == nil)
                .padding(.bottom, DesignSystem.Spacing.l)
            }
            .padding(.horizontal, DesignSystem.Spacing.l)
            .padding(.top, DesignSystem.Spacing.m)
        }
        .background(DesignSystem.Colors.bg.edgesIgnoringSafeArea(.all))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                ScanStepBar(step: 2, total: 3)
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Subviews

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9.5, weight: .bold))
            .textCase(.uppercase)
            .tracking(0.08)
            .foregroundColor(DesignSystem.Colors.ink3)
    }

    private func fitzpatrickSummary(_ type: FitzpatrickType) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) { selectedFitzpatrick = nil }
        }) {
            HStack(spacing: 10) {
                Text("Type \(type.romanNumeral)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.brand)

                VStack(alignment: .leading, spacing: 1) {
                    Text(type.skinTone)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.brand)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(DesignSystem.Colors.brand)

                Text("Change")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.brand)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(DesignSystem.Colors.brandWash)
            .cornerRadius(11)
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(DesignSystem.Colors.brand2, lineWidth: 2))
        }
    }

    private func fitzpatrickRow(_ type: FitzpatrickType) -> some View {
        let isSelected = selectedFitzpatrick == type
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) { selectedFitzpatrick = type }
        }) {
            HStack(alignment: .top, spacing: 10) {
                // Badge — left-anchored
                Text("Type \(type.romanNumeral)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .frame(width: 50, alignment: .leading)
                    .foregroundColor(isSelected ? DesignSystem.Colors.brand : DesignSystem.Colors.ink3)
                    .padding(.top, 1)

                // Two-line description — leading layout
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.skinTone)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isSelected ? DesignSystem.Colors.brand : DesignSystem.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(type.reaction)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(isSelected ? DesignSystem.Colors.brand.opacity(0.7) : .secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Checkmark — aligned to top (beside primary text)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.brand)
                        .padding(.top, 2)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(isSelected ? DesignSystem.Colors.brandWash : DesignSystem.Colors.surface)
            .cornerRadius(11)
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .stroke(
                        isSelected ? DesignSystem.Colors.brand2 : DesignSystem.Colors.line,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
    }

    private func abcdRow(label: String, hint: String, isOn: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Toggle(isOn: isOn) {
                Text(label)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.ink)
            }
            .tint(DesignSystem.Colors.brand)

            Text(hint)
                .font(.system(size: 11.5))
                .foregroundColor(DesignSystem.Colors.ink3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
    }

    private func rowDivider() -> some View {
        Rectangle()
            .fill(DesignSystem.Colors.line)
            .frame(height: 0.5)
    }
}

#Preview("ClinicalMetadataView") {
    @Previewable @State var path = NavigationPath()
    NavigationStack {
        ClinicalMetadataView(path: $path, bodySite: .leftForearm)
    }
}
