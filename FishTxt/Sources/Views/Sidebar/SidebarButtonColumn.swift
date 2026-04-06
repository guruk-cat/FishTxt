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

    var body: some View {
        VStack(spacing: 12) {
            // File navigator button
            Button(action: {
                isSidebarOpen.toggle()
            }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.shared.contentPrimary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            // New folder button
            Button(action: {
                if let projectID = selectedProjectID {
                    _ = store.createFolder(in: projectID, name: "Untitled Folder")
                }
            }) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 16))
                    .foregroundColor(selectedProjectID != nil ? AppColors.shared.contentPrimary : AppColors.shared.contentTertiary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .disabled(selectedProjectID == nil)

            // New blob button
            Button(action: {
                if let projectID = selectedProjectID {
                    _ = store.createBlob(in: projectID, folderID: selectedFolderID)
                }
            }) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 16))
                    .foregroundColor(selectedProjectID != nil ? AppColors.shared.contentPrimary : AppColors.shared.contentTertiary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .disabled(selectedProjectID == nil)

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
            Button(action: {
                isShowingSettings = true
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.shared.contentPrimary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
                    .environmentObject(AppColors.shared)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.vertical, 12)
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
