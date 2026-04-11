import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var appColors: AppColors
    @State var selectedProjectID: UUID?
    @State var selectedFolderID: UUID?
    @State var activeBlobID: UUID?
    @State var isSidebarOpen: Bool = true
    @State var isViewingHidden: Bool = false

    @AppStorage("lastProjectID") private var lastProjectIDString: String = ""
    @StateObject private var crossPanelDrag = CrossPanelDrag()

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(
                isSidebarOpen: $isSidebarOpen,
                selectedProjectID: $selectedProjectID,
                selectedFolderID: $selectedFolderID,
                activeBlobID: $activeBlobID,
                isViewingHidden: $isViewingHidden
            )

            // Main content area (fills remaining space)
            ZStack {
                AppColors.shared.backgroundSecondary
                    .ignoresSafeArea()

                if let projectID = selectedProjectID {
                    // Dashboard (hidden when EditView is active)
                    if activeBlobID == nil {
                        DashboardView(
                            projectID: projectID,
                            folderID: selectedFolderID,
                            activeBlobID: $activeBlobID,
                            selectedFolderID: $selectedFolderID,
                            isViewingHidden: $isViewingHidden
                        )
                    }

                    // EditView
                    if let blobID = activeBlobID {
                        EditView(
                            blobID: blobID,
                            projectID: projectID,
                            onClose: {
                                activeBlobID = nil
                            }
                        )
                        .id(blobID)
                    }
                } else {
                    Text("Select a project")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.shared.contentTertiary)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 480)
        .background(AppColors.shared.backgroundSecondary)
        .preferredColorScheme(appColors.isDark ? .dark : .light)
        .environmentObject(crossPanelDrag)
        .onAppear {
            if let pid = UUID(uuidString: lastProjectIDString),
               store.projects.contains(where: { $0.id == pid && !$0.isArchived }) {
                selectedProjectID = pid
            }
        }
        .onChange(of: selectedProjectID) { newID in
            lastProjectIDString = newID?.uuidString ?? ""
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ProjectStore())
        .environmentObject(AppColors.shared)
}
