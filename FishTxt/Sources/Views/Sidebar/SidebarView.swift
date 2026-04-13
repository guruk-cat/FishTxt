import SwiftUI

enum SidebarPanel: Equatable {
    case navigator
    case blobMerge
}

struct SidebarView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var appColors: AppColors
    @Binding var isSidebarOpen: Bool
    @Binding var selectedProjectID: UUID?
    @Binding var selectedFolderID: UUID?
    @Binding var activeBlobID: UUID?
    @Binding var isViewingHidden: Bool

    @State private var activePanel: SidebarPanel = .navigator

    var body: some View {
        HStack(spacing: 0) {
            SidebarButtonColumn(
                isSidebarOpen: $isSidebarOpen,
                activePanel: $activePanel
            )
            .frame(width: 48)

            if isSidebarOpen && activePanel == .navigator {
                FileNavigatorView(
                    selectedProjectID: $selectedProjectID,
                    selectedFolderID: $selectedFolderID,
                    activeBlobID: $activeBlobID,
                    isViewingHidden: $isViewingHidden
                )
                .frame(width: 220)
            } else if isSidebarOpen && activePanel == .blobMerge {
                BlobMergeView(
                    selectedProjectID: $selectedProjectID,
                    selectedFolderID: $selectedFolderID,
                    activeBlobID: $activeBlobID
                )
                .frame(width: 220)
            }
        }
        .frame(width: isSidebarOpen ? 268 : 48)
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
