import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var appColors: AppColors
    @Binding var isSidebarOpen: Bool
    @Binding var selectedProjectID: UUID?
    @Binding var selectedFolderID: UUID?
    @Binding var activeBlobID: UUID?
    @Binding var isViewingHidden: Bool

    var body: some View {
        HStack(spacing: 0) {
            SidebarButtonColumn(
                isSidebarOpen: $isSidebarOpen,
                selectedProjectID: $selectedProjectID,
                selectedFolderID: $selectedFolderID,
                activeBlobID: $activeBlobID,
                isViewingHidden: $isViewingHidden
            )
            .frame(width: 48)

            if isSidebarOpen {
                FileNavigatorView(
                    selectedProjectID: $selectedProjectID,
                    selectedFolderID: $selectedFolderID,
                    activeBlobID: $activeBlobID,
                    isViewingHidden: $isViewingHidden
                )
                .frame(width: 200)
            }
        }
        .frame(width: isSidebarOpen ? 248 : 48)
        .background(AppColors.shared.sidebarBackground)
    }
}

#Preview {
    SidebarView(
        isSidebarOpen: .constant(true),
        selectedProjectID: .constant(nil),
        selectedFolderID: .constant(nil),
        activeBlobID: .constant(nil),
        isViewingHidden: .constant(false)
    )
    .environmentObject(ProjectStore())
    .environmentObject(AppColors.shared)
}
