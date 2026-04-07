import SwiftUI

struct SidebarButtonColumn: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var appColors: AppColors
    @State private var isShowingSettings: Bool = false

    @Binding var isSidebarOpen: Bool
    @Binding var selectedProjectID: UUID?
    @Binding var selectedFolderID: UUID?
    @Binding var activeBlobID: UUID?
    @Binding var isViewingHidden: Bool

    // Hover state
    @State private var hoverSidebar: Bool  = false
    @State private var hoverFolder: Bool   = false
    @State private var hoverBlob: Bool     = false
    @State private var hoverSettings: Bool = false

    // Confirmation glow state
    @State private var glowFolder: Bool = false
    @State private var glowBlob: Bool   = false

    var body: some View {
        VStack(spacing: 12) {
            // File navigator toggle
            Button(action: { isSidebarOpen.toggle() }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 16))
                    .foregroundColor(isSidebarOpen || hoverSidebar
                        ? AppColors.shared.contentPrimary
                        : AppColors.shared.contentTertiary)
                    .frame(width: 32, height: 32)
                    .animation(.easeInOut(duration: 0.12), value: isSidebarOpen)
                    .animation(.easeInOut(duration: 0.12), value: hoverSidebar)
            }
            .buttonStyle(.plain)
            .onHover { hoverSidebar = $0 }

            // New folder button
            Button(action: {
                guard let projectID = selectedProjectID else { return }
                _ = store.createFolder(in: projectID, name: "Untitled Folder")
                triggerGlow(isFolder: true)
            }) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 16))
                    .foregroundColor(folderButtonColor)
                    .frame(width: 32, height: 32)
                    .animation(.easeInOut(duration: 0.12), value: glowFolder)
                    .animation(.easeInOut(duration: 0.12), value: hoverFolder)
            }
            .buttonStyle(.plain)
            .disabled(selectedProjectID == nil)
            .onHover { hoverFolder = $0 }

            // New blob button
            Button(action: {
                guard let projectID = selectedProjectID else { return }
                _ = store.createBlob(in: projectID, folderID: selectedFolderID)
                triggerGlow(isFolder: false)
            }) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 16))
                    .foregroundColor(blobButtonColor)
                    .frame(width: 32, height: 32)
                    .animation(.easeInOut(duration: 0.12), value: glowBlob)
                    .animation(.easeInOut(duration: 0.12), value: hoverBlob)
            }
            .buttonStyle(.plain)
            .disabled(selectedProjectID == nil)
            .onHover { hoverBlob = $0 }

            // Git button (coming soon)
            Button(action: {}) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.shared.contentTertiary)
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
                    .foregroundColor(isShowingSettings || hoverSettings
                        ? AppColors.shared.contentPrimary
                        : AppColors.shared.contentTertiary)
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

    // MARK: - Color helpers

    private var folderButtonColor: Color {
        guard selectedProjectID != nil else { return AppColors.shared.contentTertiary }
        if glowFolder  { return AppColors.shared.confirmation }
        if hoverFolder { return AppColors.shared.contentPrimary }
        return AppColors.shared.contentTertiary
    }

    private var blobButtonColor: Color {
        guard selectedProjectID != nil else { return AppColors.shared.contentTertiary }
        if glowBlob  { return AppColors.shared.confirmation }
        if hoverBlob { return AppColors.shared.contentPrimary }
        return AppColors.shared.contentTertiary
    }

    // MARK: - Glow animation

    private func triggerGlow(isFolder: Bool) {
        if isFolder {
            withAnimation(.easeIn(duration: 0.08)) { glowFolder = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.easeOut(duration: 0.25)) { glowFolder = false }
            }
        } else {
            withAnimation(.easeIn(duration: 0.08)) { glowBlob = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.easeOut(duration: 0.25)) { glowBlob = false }
            }
        }
    }
}

#Preview {
    SidebarButtonColumn(
        isSidebarOpen: .constant(false),
        selectedProjectID: .constant(nil),
        selectedFolderID: .constant(nil),
        activeBlobID: .constant(nil),
        isViewingHidden: .constant(false)
    )
    .environmentObject(ProjectStore())
    .environmentObject(AppColors.shared)
    .frame(width: 48)
}
