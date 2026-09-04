// 📄 CaptureView.swift

import SwiftUI

struct CaptureView: View {
    @Binding var path: NavigationPath
    @Environment(\.captureSource) private var captureSource

    @State private var hasCameraPermission = true // Mocked permission state
    @State private var focusOk = false
    @State private var lightOk = false
    @State private var frameOk = false
    @State private var isCapturing = false
    
    var allChecksPass: Bool {
        focusOk && lightOk && frameOk
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("New scan")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, DesignSystem.Spacing.l)
                .padding(.bottom, DesignSystem.Spacing.m)
            
            if hasCameraPermission {
                cameraInterface
            } else {
                permissionRecoveryState
            }
        }
        .padding(.top, DesignSystem.Spacing.m)
        .background(DesignSystem.Colors.bg.edgesIgnoringSafeArea(.all))
        .task {
            // Subscribe to the mock hardware stream
            for await state in captureSource.qualityChecks {
                withAnimation(.easeInOut(duration: 0.2)) {
                    switch state {
                    case .focus(let val): focusOk = val
                    case .lighting(let val): lightOk = val
                    case .framing(let val): frameOk = val
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var cameraInterface: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            // Viewfinder Mock
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radii.medium)
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [Color(hex: 0x231C3D), Color(hex: 0x120E22)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .aspectRatio(3/4, contentMode: .fit)
                
                // Guidance Box
                RoundedRectangle(cornerRadius: DesignSystem.Radii.small)
                    .stroke(allChecksPass ? Color(hex: 0x34D3A6) : Color.white.opacity(0.34),
                            style: StrokeStyle(lineWidth: 2.5, dash: allChecksPass ? [] : [6]))
                    .aspectRatio(1, contentMode: .fit)
                    .padding(40)
                
                // Hint Overlay
                VStack {
                    Spacer()
                    Text(allChecksPass ? "Ready — hold still and capture" : "Move closer and hold steady")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(allChecksPass ? DesignSystem.Colors.low.opacity(0.85) : Color.black.opacity(0.5))
                        .cornerRadius(DesignSystem.Radii.small)
                        .padding(.bottom, 16)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.l)
            
            // Diagnostic Checklist
            VStack(spacing: 8) {
                QualityCheckRow(isPassing: focusOk, passText: "Sharp focus", failText: "Too blurry — hold still")
                QualityCheckRow(isPassing: lightOk, passText: "Even lighting", failText: "Low light — find brighter light")
                QualityCheckRow(isPassing: frameOk, passText: "Inside the frame", failText: "Not centered in frame") // Failsafe, mock defaults to true
            }
            .padding(.horizontal, DesignSystem.Spacing.l)
            
            // Shutter Button
            Button(action: {
                Task { await performCapture() }
            }) {
                Circle()
                    .fill(allChecksPass ? DesignSystem.Colors.brand : Color(hex: 0xCFCADF))
                    .frame(width: 56, height: 56)
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(color: allChecksPass ? DesignSystem.Colors.brand : Color(hex: 0xCFCADF), radius: 0, x: 0, y: 0)
                    .padding(2)
                    .overlay(Circle().stroke(allChecksPass ? DesignSystem.Colors.brand : Color(hex: 0xCFCADF), lineWidth: 2))
            }
            .disabled(!allChecksPass || isCapturing)
            .padding(.top, DesignSystem.Spacing.s)
            
            Text("Photos stay on this application.")
                .font(.caption2)
                .foregroundColor(DesignSystem.Colors.ink3)
                .padding(.top, 4)
            
            Spacer()
        }
    }
    
    private var permissionRecoveryState: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            Spacer()
            Image(systemName: "camera.fill.badge.ellipsis")
                .font(.system(size: 40))
                .foregroundColor(DesignSystem.Colors.ink3)
            Text("Camera access required")
                .font(.headline)
            Text("QuantizeNN needs camera access to perform a scan. Enable it in your system settings.")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.ink2)
                .multilineTextAlignment(.center)
            
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .padding()
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radii.small)
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.Radii.small).stroke(DesignSystem.Colors.line, lineWidth: 1))
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.l)
    }
    
    private func performCapture() async {
        isCapturing = true
        do {
            let _ = try await captureSource.capture()
            // Navigate to the body site picker. (In full integration, pass the image data along.)
            path.append(ScanRoute.bodySite(.III))
        } catch {
            print("Capture failed: \(error)")
        }
        isCapturing = false
    }
}

// MARK: - Helper Views

struct QualityCheckRow: View {
    let isPassing: Bool
    let passText: String
    let failText: String
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                if isPassing {
                    Circle().fill(DesignSystem.Colors.low)
                        .frame(width: 15, height: 15)
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.white)
                } else {
                    Rectangle().fill(DesignSystem.Colors.watch)
                        .frame(width: 15, height: 15)
                    Text("!")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.white)
                }
            }
            
            Text(isPassing ? passText : failText)
                .font(.system(size: 11))
                .fontWeight(isPassing ? .regular : .semibold)
            
            Spacer()
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 9)
        .background(isPassing ? DesignSystem.Colors.surface : DesignSystem.Colors.watchWash)
        .foregroundColor(isPassing ? DesignSystem.Colors.ink2 : DesignSystem.Colors.watch)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isPassing ? DesignSystem.Colors.line : Color(hex: 0xEBD5B4), lineWidth: 1)
        )
    }
}

#Preview("CaptureView") {
    @State var path = NavigationPath()
    return NavigationStack {
        CaptureView(path: $path)
    }
}
