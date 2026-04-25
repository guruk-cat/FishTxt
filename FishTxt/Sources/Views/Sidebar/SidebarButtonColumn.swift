import SwiftUI

struct SidebarButtonColumn: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var appColors: AppColors
    @State private var isShowingSettings: Bool = false

    @Binding var isSidebarOpen: Bool
    @Binding var activePanel: SidebarPanel

    // Hover state
    @State private var hoverNavigator: Bool = false
    @State private var hoverMerge: Bool    = false
    @State private var hoverOutline: Bool  = false
    @State private var hoverSettings: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            // File navigator toggle
            Button(action: { togglePanel(.navigator) }) {
                Image(systemName: "tray.full")
                    .font(.system(size: 16))
                    .foregroundColor(navigatorButtonColor)
                    .frame(width: 32, height: 32)
                    .animation(.easeInOut(duration: 0.12), value: isSidebarOpen)
                    .animation(.easeInOut(duration: 0.12), value: activePanel == .navigator)
                    .animation(.easeInOut(duration: 0.12), value: hoverNavigator)
            }
            .buttonStyle(.plain)
            .onHover { hoverNavigator = $0 }
            
            // Blob outline toggle
            Button(action: { togglePanel(.blobOutline) }) {
                Image(systemName: "list.dash.header.rectangle")
                    .font(.system(size: 16))
                    .foregroundColor(outlineButtonColor)
                    .frame(width: 32, height: 32)
                    .animation(.easeInOut(duration: 0.12), value: isSidebarOpen)
                    .animation(.easeInOut(duration: 0.12), value: activePanel == .blobOutline)
                    .animation(.easeInOut(duration: 0.12), value: hoverOutline)
            }
            .buttonStyle(.plain)
            .onHover { hoverOutline = $0 }
            
            // Blob merge toggle
            Button(action: { togglePanel(.blobMerge) }) {
                Image(systemName: "plus.rectangle.on.rectangle")
                    .font(.system(size: 16))
                    .foregroundColor(mergeButtonColor)
                    .frame(width: 32, height: 32)
                    .animation(.easeInOut(duration: 0.12), value: isSidebarOpen)
                    .animation(.easeInOut(duration: 0.12), value: activePanel == .blobMerge)
                    .animation(.easeInOut(duration: 0.12), value: hoverMerge)
            }
            .buttonStyle(.plain)
            .onHover { hoverMerge = $0 }

            // Git button (coming soon)
            Button(action: {}) {
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.shared.textMuted)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .disabled(true)
            .help("Coming soon")

            Spacer()

            // Settings button
            Button(action: { isShowingSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundColor(isShowingSettings ? AppColors.shared.accent
                        : hoverSettings ? AppColors.shared.textBody
                        : AppColors.shared.textMuted)
                    .frame(width: 32, height: 32)
                    .animation(.easeInOut(duration: 0.12), value: isShowingSettings)
                    .animation(.easeInOut(duration: 0.12), value: hoverSettings)
            }
            .buttonStyle(.plain)
            .onHover { hoverSettings = $0 }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
                    .environmentObject(AppColors.shared)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.vertical, 12)
    }

    // MARK: - Panel toggle

    private func togglePanel(_ panel: SidebarPanel) {
        if isSidebarOpen && activePanel == panel {
            isSidebarOpen = false
        } else {
            activePanel = panel
            isSidebarOpen = true
        }
    }

    // MARK: - Color helpers

    private var navigatorButtonColor: Color {
        let isActive = isSidebarOpen && activePanel == .navigator
        if isActive { return AppColors.shared.accent }
        else if hoverNavigator { return AppColors.shared.textBody }
        return AppColors.shared.textMuted
    }

    private var mergeButtonColor: Color {
        let isActive = isSidebarOpen && activePanel == .blobMerge
        if isActive { return AppColors.shared.accent }
        else if hoverMerge { return AppColors.shared.textBody }
        return AppColors.shared.textMuted
    }

    private var outlineButtonColor: Color {
        let isActive = isSidebarOpen && activePanel == .blobOutline
        if isActive { return AppColors.shared.accent }
        else if hoverOutline { return AppColors.shared.textBody }
        return AppColors.shared.textMuted
    }

}

#Preview {
    SidebarButtonColumn(
        isSidebarOpen: .constant(false),
        activePanel: .constant(.navigator)
    )
    .environmentObject(ProjectStore())
    .environmentObject(AppColors.shared)
    .frame(width: 48)
}
