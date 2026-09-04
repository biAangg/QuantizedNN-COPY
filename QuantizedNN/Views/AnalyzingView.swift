// 📄 AnalyzingView.swift

import SwiftUI

struct AnalyzingView: View {
    @Binding var path: NavigationPath
    let bodySite: BodySite
    let fitzpatrickType: FitzpatrickType
    //let abcdAssessment: ABCDAssessment
    
    @Environment(\.inferenceEngine) private var inferenceEngine
    @State private var isAnalyzing = true
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(DesignSystem.Colors.brand)
            
            Text("Analyzing scan...")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.ink)
            
            Text("This happens entirely on your device.")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.ink3)
            
            Spacer()
            
            Button("Cancel") {
                path.removeLast(3)
            }
            .font(.body.weight(.semibold))
            .foregroundColor(DesignSystem.Colors.ink2)
            .padding(.bottom, DesignSystem.Spacing.l)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.bg.edgesIgnoringSafeArea(.all))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task {
            do {
                // Mock image for prototype
                let result = try await inferenceEngine.analyze(UIImage())
                
                // Replace transition: Pop Analyzing, push Result
                if isAnalyzing {
                    var newPath = path
                    newPath.removeLast()
                    newPath.append(ScanRoute.result(result, bodySite, fitzpatrickType))
                    
                    withAnimation(.easeInOut) {
                        path = newPath
                    }
                }
            } catch {
                path.removeLast(3)
            }
        }
        .onDisappear {
            isAnalyzing = false
        }
    }
}

#Preview("AnalyzingView") {
    @Previewable @State var path = NavigationPath()
    AnalyzingView(path: $path, bodySite: .leftForearm, fitzpatrickType: .III)
}
