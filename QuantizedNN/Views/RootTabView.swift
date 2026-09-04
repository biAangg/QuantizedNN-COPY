// 📄 RootTabView.swift

import SwiftUI
import SwiftData

enum TabSelection {
    case scan, history, performance
}

enum ScanRoute: Hashable {
    case capture
    case bodySite(FitzpatrickType)
    case analyzing(BodySite, FitzpatrickType)
    case result(ScreeningOutput, BodySite, FitzpatrickType)
}

struct RootTabView: View {
    @AppStorage("consentAccepted") private var consentAccepted: Bool = false
    @State private var selectedTab: TabSelection = .scan
    @State private var scanPath = NavigationPath()
    @State private var historyPath = NavigationPath()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // SCAN TAB
            NavigationStack(path: $scanPath) {
                CaptureView(path: $scanPath) // Assumes CaptureView is updated to take a Binding<NavigationPath>
                    .navigationDestination(for: ScanRoute.self) { route in
                        switch route {
                        case .capture:
                            CaptureView(path: $scanPath)
                        case .bodySite(let fitzpatrick):
                            BodySitePickerView(path: $scanPath, fitzpatrickType: fitzpatrick)
                        case .analyzing(let site, let fitzpatrick):
                            AnalyzingView(path: $scanPath, bodySite: site, fitzpatrickType: fitzpatrick)
                        case .result(let output, let site, let fitzpatrick):
                            ResultView(path: $scanPath, mode: .capture(output, site, fitzpatrick))
                        }
                    }
            }
            .tabItem { Label("Scan", systemImage: "record.circle") }
            .tag(TabSelection.scan)
            
            // HISTORY TAB
            NavigationStack(path: $historyPath) {
                HistoryView(selectedTab: $selectedTab)
                    .navigationDestination(for: ScanRecord.self) { record in
                        ResultView(path: .constant(NavigationPath()), mode: .detail(record))
                    }
            }
            .tabItem { Label("History", systemImage: "clock") }
            .tag(TabSelection.history)
            
            // PERFORMANCE TAB
            // PerformanceView manages its own NavigationStack internally
            PerformanceView()
                .tabItem { Label("Performance", systemImage: "text.justify") }
                .tag(TabSelection.performance)
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            if oldTab == .history && newTab != .history {
                historyPath = NavigationPath()
            }
        }
        .fullScreenCover(isPresented: .init(get: { !consentAccepted }, set: { _ in })) {
            ConsentView()
        }
    }
}

#Preview("RootTabView") {
    RootTabView()
        .modelContainer(for: ScanRecord.self, inMemory: true)
}
