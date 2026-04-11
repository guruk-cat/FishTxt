import Foundation

/// Shared state for a blob drag that originates in the Dashboard and may land
/// on a folder row in the FileNavigator. Lives as an environment object so
/// DashboardView (source) and FileNavigatorView (target) can coordinate without
/// being directly coupled.
class CrossPanelDrag: ObservableObject {
    @Published var activeBlobID: UUID? = nil
    @Published var activeProjectID: UUID? = nil
    @Published var targetFolderID: UUID? = nil

    func clear() {
        activeBlobID = nil
        activeProjectID = nil
        targetFolderID = nil
    }
}
