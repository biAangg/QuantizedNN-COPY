// 📄 BodySitePickerView.swift

import SwiftUI

// UI-only grouping for the two-step picker — not stored in the model.
private enum BroadRegion: String, CaseIterable, Hashable {
    case headNeck = "Head & Neck"
    case torso    = "Torso"
    case arms     = "Arms"
    case legs     = "Legs"

    var icon: String {
        switch self {
        case .headNeck: return "brain"
        case .torso:    return "figure.stand"
        case .arms:     return "figure.arms.open"
        case .legs:     return "figure.walk"
        }
    }

    var sites: [BodySite] {
        switch self {
        case .headNeck: return [.forehead, .leftCheek, .rightCheek, .neck]
        case .torso:    return [.chest, .abdomen, .upperBack, .lowerBack]
        case .arms:     return [.leftUpperArm, .leftForearm, .rightUpperArm, .rightForearm]
        case .legs:     return [.leftThigh, .leftCalf, .rightThigh, .rightCalf]
        }
    }
}

struct BodySitePickerView: View {
    @Binding var path: NavigationPath
    let fitzpatrickType: FitzpatrickType
    @State private var selectedRegion: BroadRegion? = nil
    @State private var selectedSite: BodySite? = nil

    private let twoCol = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {

                // MARK: Header
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text("Where is this spot?")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Select the broad area, then the exact location.")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.ink3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, DesignSystem.Spacing.xs)

                // MARK: Step 1 — Broad region
                LazyVGrid(columns: twoCol, spacing: 10) {
                    ForEach(BroadRegion.allCases, id: \.self) { region in
                        regionButton(region)
                    }
                }

                // MARK: Step 2 — Specific location (slides in on selection)
                if let region = selectedRegion {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        sectionLabel("SPECIFIC LOCATION — \(region.rawValue.uppercased())")
                        LazyVGrid(columns: twoCol, spacing: 8) {
                            ForEach(region.sites, id: \.self) { site in
                                subRegionButton(site)
                            }
                        }
                    }
                    .id(region)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
                }

                Spacer(minLength: DesignSystem.Spacing.l)

                // MARK: Continue
                Button(action: {
                    if let site = selectedSite {
                        path.append(ScanRoute.analyzing(site, fitzpatrickType))
                    }
                }) {
                    Text("Continue")
                        .font(.body)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.s)
                        .background(selectedSite != nil ? DesignSystem.Colors.brand : Color(hex: 0xE8E5F2))
                        .foregroundColor(selectedSite != nil ? .white : Color(hex: 0xA8A3BE))
                        .cornerRadius(11)
                }
                .disabled(selectedSite == nil)
                .padding(.bottom, DesignSystem.Spacing.l)
            }
            .padding(.horizontal, DesignSystem.Spacing.l)
            .padding(.top, DesignSystem.Spacing.m)
        }
        .background(DesignSystem.Colors.bg.edgesIgnoringSafeArea(.all))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                ScanStepBar(step: 1, total: 3)
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Components

    private func regionButton(_ region: BroadRegion) -> some View {
        let isSelected = selectedRegion == region
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedRegion = region
                selectedSite = nil
            }
        }) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: region.icon)
                    .font(.system(size: 30, weight: .medium))
                Text(region.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(isSelected ? DesignSystem.Colors.brandWash : DesignSystem.Colors.surface)
            .foregroundColor(isSelected ? DesignSystem.Colors.brand : DesignSystem.Colors.ink)
            .cornerRadius(DesignSystem.Radii.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radii.medium)
                    .stroke(
                        isSelected ? DesignSystem.Colors.brand2 : DesignSystem.Colors.line,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
    }

    private func subRegionButton(_ site: BodySite) -> some View {
        let isSelected = selectedSite == site
        return Button(action: { selectedSite = site }) {
            Text(site.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .background(isSelected ? DesignSystem.Colors.brandWash : DesignSystem.Colors.surface)
                .foregroundColor(isSelected ? DesignSystem.Colors.brand : DesignSystem.Colors.ink)
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

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9.5, weight: .bold))
            .tracking(0.08)
            .foregroundColor(DesignSystem.Colors.ink3)
    }
}

#Preview("BodySitePickerView") {
    @Previewable @State var path = NavigationPath()
    return NavigationStack {
        BodySitePickerView(path: $path, fitzpatrickType: .III)
    }
}
