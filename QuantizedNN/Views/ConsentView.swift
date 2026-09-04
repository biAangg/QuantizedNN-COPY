// 📄 ConsentView.swift

import SwiftUI

struct ConsentView: View {
    @AppStorage("consentAccepted") private var consentAccepted: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text("Before you start")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, DesignSystem.Spacing.s)
            
            // Replaced banned terminology with strictly operational phrasing
            ProvenanceCard(provenance: .guidance) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This is not a clinical decision")
                        .font(.system(.caption, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.ink3)
                        .textCase(.uppercase)
                        .tracking(0.05)
                    
                    Text("QuantizeNN is a research prototype. It cannot tell you whether you have skin cancer. It gives a signal, and it is sometimes wrong in both directions.")
                        .font(.body)
                        .foregroundColor(DesignSystem.Colors.ink2)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radii.medium)
                    .stroke(DesignSystem.Colors.getChecked, lineWidth: 1) // Highlighting the specific limit
            )
            .overlay(
                Rectangle()
                    .fill(DesignSystem.Colors.getChecked)
                    .frame(width: 3),
                alignment: .leading
            )
            
            ProvenanceCard(provenance: .guidance) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("It can miss things")
                        .font(.system(.caption, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.ink3)
                        .textCase(.uppercase)
                        .tracking(0.05)
                    
                    Text("A **low concern** result does not mean a spot is safe. If something worries you, see a doctor — whatever this app said.")
                        .font(.body)
                        .foregroundColor(DesignSystem.Colors.ink2)
                }
            }
            
            ProvenanceCard(provenance: .guidance) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your photos stay here")
                        .font(.system(.caption, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.ink3)
                        .textCase(.uppercase)
                        .tracking(0.05)
                    
                    Text("Scans are encrypted with AES-256 on this device. Nothing is uploaded. There is no account and no server.")
                        .font(.body)
                        .foregroundColor(DesignSystem.Colors.ink2)
                }
            }
            
            Spacer()
            
            Button(action: {
                consentAccepted = true
            }) {
                Text("I understand — continue")
                    .font(.body)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.s)
                    .background(DesignSystem.Colors.brand)
                    .foregroundColor(.white)
                    .cornerRadius(DesignSystem.Radii.small)
            }
            .padding(.bottom, DesignSystem.Spacing.l)
        }
        .padding(.horizontal, DesignSystem.Spacing.l)
        .padding(.top, DesignSystem.Spacing.l)
        .background(DesignSystem.Colors.bg.edgesIgnoringSafeArea(.all))
    }
}

#Preview("ConsentView") {
    ConsentView()
}
