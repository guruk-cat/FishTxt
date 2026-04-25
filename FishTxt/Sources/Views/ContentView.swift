import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var appColors: AppColors
    @State var selectedProjectID: UUID?
    @State var selectedFolderID: UUID?
    @State var activeBlobID: UUID?
    @State var isSidebarOpen: Bool = true

    @AppStorage("lastProjectID") private var lastProjectIDString: String = ""
    @StateObject private var crossPanelDrag = CrossPanelDrag()

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(
                isSidebarOpen: $isSidebarOpen,
                selectedProjectID: $selectedProjectID,
                selectedFolderID: $selectedFolderID,
                activeBlobID: $activeBlobID
            )

            // Main content area (fills remaining space)
            ZStack {
                AppColors.shared.surfaceSunken
                    .ignoresSafeArea()

                if let projectID = selectedProjectID {
                    // Dashboard (hidden when EditView is active)
                    if activeBlobID == nil {
                        DashboardView(
                            projectID: projectID,
                            folderID: selectedFolderID,
                            activeBlobID: $activeBlobID,
                            selectedFolderID: $selectedFolderID
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
                        .foregroundColor(AppColors.shared.textMuted)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 480)
        .background(AppColors.shared.surfaceSunken)
        .preferredColorScheme(appColors.isDark ? .dark : .light)
        .toolbarBackground(appColors.chromeToolbar, for: .windowToolbar)
        .toolbarBackground(.visible, for: .windowToolbar)
        .environmentObject(crossPanelDrag)
        .onAppear {
            if let pid = UUID(uuidString: lastProjectIDString),
               store.projects.contains(where: { $0.id == pid }) {
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
