// 📄 HistoryView.swift

import SwiftUI
import SwiftData
import LocalAuthentication

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScanRecord.capturedAt, order: .reverse) private var scans: [ScanRecord]

    @Binding var selectedTab: TabSelection
    @State private var viewModel: HistoryViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(selectedTab: Binding<TabSelection>, startUnlocked: Bool = false) {
        _selectedTab = selectedTab
        _viewModel = State(initialValue: HistoryViewModel(startUnlocked: startUnlocked))
    }
    @State private var searchText = ""
    @State private var signalFilter: ScreeningSignal? = nil

    private var filteredScans: [ScanRecord] {
        scans.filter { record in
            let matchesSearch = searchText.isEmpty ||
                record.bodySite.rawValue.localizedCaseInsensitiveContains(searchText) ||
                record.scanCode.localizedCaseInsensitiveContains(searchText)
            let matchesSignal = signalFilter == nil || record.signal == signalFilter
            return matchesSearch && matchesSignal
        }
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.bg.edgesIgnoringSafeArea(.all)
            
            if viewModel.isUnlocked {
                unlockedContent
                    .transition(.opacity)
            } else {
                lockedState
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isUnlocked)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                viewModel.lock()
            }
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            if oldTab == .history && newTab != .history {
                viewModel.lock()
            }
        }
    }
    
    // MARK: - Unlocked State (List or Empty)
    
    private var unlockedContent: some View {
        Group {
            if scans.isEmpty {
                emptyState
            } else {
                populatedList
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Subviews

    private var unlockButtonTitle: String {
        switch viewModel.biometryType {
        case .faceID: return "Unlock with Face ID"
        case .touchID: return "Unlock with Touch ID"
        default: return "Unlock with Passcode"
        }
    }

    private var unlockButtonIcon: String {
        switch viewModel.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.open.fill"
        }
    }

    private var lockedState: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.s) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 32))
                    .foregroundColor(DesignSystem.Colors.brand)
                    .frame(width: 64, height: 64)
                    .background(DesignSystem.Colors.brandWash)
                    .cornerRadius(16)
                
                Text("History is locked")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Unlock to view your scans. They're encrypted on this device with AES-256 and never uploaded to the internet.")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.ink2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.m)
            }
            
            VStack(spacing: DesignSystem.Spacing.s) {
                Button(action: { viewModel.authenticate() }) {
                    Label(unlockButtonTitle, systemImage: unlockButtonIcon)
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(DesignSystem.Colors.brand)
                        .foregroundColor(.white)
                        .cornerRadius(11)
                }

                Text("Your device passcode always works as a fallback.")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.ink3)

                if let authError = viewModel.authError {
                    Text(authError)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.getChecked)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.l)
            
                        Spacer()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.s) {
                Image(systemName: "clock")
                    .font(.system(size: 24))
                    .foregroundColor(DesignSystem.Colors.ink2)
                    .frame(width: 56, height: 56)
                    .background(DesignSystem.Colors.brandWash)
                    .cornerRadius(16)
                
                Text("No scans yet")
                    .font(.headline)
                
                Text("Your scans are stored on this device, encrypted, and never uploaded. Take a first scan to start tracking a spot over time.")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.ink2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.m)
            }
            
            Button(action: { selectedTab = .scan }) {
                Text("Take first scan")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(DesignSystem.Colors.brand)
                    .foregroundColor(.white)
                    .cornerRadius(11)
            }
            .padding(.horizontal, DesignSystem.Spacing.l)
            
            Text("**Why tracking matters:** change over time is a stronger warning sign than any single photo. Re-scanning the same spot is the point.")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.ink2)
                .padding(10)
                .background(DesignSystem.Colors.surface)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(DesignSystem.Colors.line, lineWidth: 1))
                .padding(.horizontal, DesignSystem.Spacing.l)
            
            Spacer()
        }
    }
    
    private var populatedList: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.s) {
                // Search Field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DesignSystem.Colors.ink3)
                        .font(.system(size: 14))
                    TextField("Body site or scan code", text: $searchText)
                        .font(.system(size: 15))
                        .foregroundColor(DesignSystem.Colors.ink)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(DesignSystem.Colors.ink3)
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(DesignSystem.Colors.surface)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(DesignSystem.Colors.line, lineWidth: 1))
                .padding(.horizontal, DesignSystem.Spacing.m)

                // Signal Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        FilterChip(label: "All", isSelected: signalFilter == nil,
                                   selectedBg: DesignSystem.Colors.brandWash,
                                   selectedFg: DesignSystem.Colors.brand) {
                            signalFilter = nil
                        }
                        FilterChip(label: "Low", isSelected: signalFilter == .lowConcern,
                                   selectedBg: DesignSystem.Colors.lowWash,
                                   selectedFg: DesignSystem.Colors.low) {
                            signalFilter = signalFilter == .lowConcern ? nil : .lowConcern
                        }
                        FilterChip(label: "Monitor", isSelected: signalFilter == .watch,
                                   selectedBg: DesignSystem.Colors.watchWash,
                                   selectedFg: DesignSystem.Colors.watch) {
                            signalFilter = signalFilter == .watch ? nil : .watch
                        }
                        FilterChip(label: "High Risk", isSelected: signalFilter == .getChecked,
                                   selectedBg: DesignSystem.Colors.getCheckedWash,
                                   selectedFg: DesignSystem.Colors.getChecked) {
                            signalFilter = signalFilter == .getChecked ? nil : .getChecked
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.m)
                }

                // Summary Stats
                HStack(spacing: 6) {
                    StatBox(value: "\(filteredScans.count)", label: "Scanned")
                    StatBox(value: "\(filteredScans.filter { $0.signal == .getChecked }.count)", label: "High Risk")
                    StatBox(value: "\(filteredScans.filter { $0.signal == .noClearSignal }.count)", label: "Monitor")
                }
                .padding(.horizontal, DesignSystem.Spacing.m)
                .padding(.bottom, 4)

                // Scan Rows
                if filteredScans.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.s) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 22))
                            .foregroundColor(DesignSystem.Colors.ink3)
                        Text("No scans match this filter.")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.ink3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, DesignSystem.Spacing.l)
                } else {
                    ForEach(filteredScans) { record in
                        NavigationLink(value: record) {
                            HistoryRow(record: record)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, DesignSystem.Spacing.m)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.m)
        }
    }
}

// MARK: - Row Components

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let selectedBg: Color
    let selectedFg: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? selectedBg : DesignSystem.Colors.surface)
                .foregroundColor(isSelected ? selectedFg : DesignSystem.Colors.ink3)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? selectedFg.opacity(0.4) : DesignSystem.Colors.line, lineWidth: 1)
                )
        }
    }
}

struct StatBox: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .heavy))
            Text(label)
                .font(.system(size: 8.5, weight: .bold))
                .textCase(.uppercase)
                .tracking(0.05)
                .foregroundColor(DesignSystem.Colors.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DesignSystem.Colors.line, lineWidth: 1))
    }
}

struct HistoryRow: View {
    let record: ScanRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // Metadata
            VStack(alignment: .leading, spacing: 2) {
                Text(record.bodySite.rawValue)
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.ink)
                Text("\(formatDate(record.capturedAt)) · \(record.scanCode)")
                    .font(.system(size: 10))
                    .foregroundColor(DesignSystem.Colors.ink3)
            }
            
            Spacer()
            
            // Risk Pill
            HStack(spacing: 3) {
                riskIcon
                Text(riskWord)
            }
            .font(.system(size: 8.5, weight: .bold))
            .tracking(0.03)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(riskBackground)
            .foregroundColor(riskColor)
            .cornerRadius(5)
        }
        .padding(11)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(11)
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(DesignSystem.Colors.line, lineWidth: 1))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
    
    // Extracted risk pill properties to survive greyscale
    private var riskIcon: Image {
        switch record.signal {
        case .lowConcern: return Image(systemName: "circle.fill")
        case .watch: return Image(systemName: "eye.fill")
        case .getChecked: return Image(systemName: "exclamationmark.triangle.fill")
        case .noClearSignal: return Image(systemName: "questionmark")
        }
    }
    
    private var riskWord: String {
        switch record.signal {
        case .lowConcern: return "Low"
        case .watch: return "Monitor"
        case .getChecked: return "High Risk"
        case .noClearSignal: return "Unclear"
        }
    }
    
    private var riskBackground: Color {
        switch record.signal {
        case .lowConcern: return DesignSystem.Colors.lowWash
        case .watch: return DesignSystem.Colors.watchWash
        case .getChecked: return DesignSystem.Colors.getCheckedWash
        case .noClearSignal: return DesignSystem.Colors.noClearSignalWash
        }
    }
    
    private var riskColor: Color {
        switch record.signal {
        case .lowConcern: return DesignSystem.Colors.low
        case .watch: return DesignSystem.Colors.watch
        case .getChecked: return DesignSystem.Colors.getChecked
        case .noClearSignal: return DesignSystem.Colors.noClearSignal
        }
    }
}

// MARK: - Previews

#Preview("History Locked") {
    HistoryView(selectedTab: .constant(.history))
        .modelContainer(for: ScanRecord.self, inMemory: true)
}

#Preview("History Populated") {
    let container = try! ModelContainer(for: ScanRecord.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    SeedData.shared.insertSeedData(into: container.mainContext)

    return NavigationStack {
        HistoryView(selectedTab: .constant(.history), startUnlocked: true)
            .navigationDestination(for: ScanRecord.self) { record in
                ResultView(path: .constant(NavigationPath()), mode: .detail(record))
            }
    }
    .modelContainer(container)
}
