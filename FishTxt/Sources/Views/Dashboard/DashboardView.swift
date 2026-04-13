import SwiftUI

struct CardFrameKey: PreferenceKey {
    typealias Value = [UUID: CGRect]
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct DashboardView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var appColors: AppColors
    @EnvironmentObject var crossPanelDrag: CrossPanelDrag

    let projectID: UUID
    let folderID: UUID?
    @Binding var activeBlobID: UUID?
    @Binding var selectedFolderID: UUID?
    @Binding var isViewingHidden: Bool

    @State private var isRenamingFolder = false
    @State private var renameFolderID: UUID?
    @State private var renameFolderText = ""

    // MARK: - Floating island state
    @State private var hoverFolder: Bool = false
    @State private var hoverBlob: Bool   = false
    @State private var glowFolder: Bool  = false
    @State private var glowBlob: Bool    = false

    // MARK: - Drag State
    @State private var draggedItemID: UUID? = nil
    @State private var dragLocation: CGPoint = .zero
    @State private var ghostFolderIndex: Int? = nil
    @State private var ghostBlobIndex: Int? = nil
    @State private var hoveredFolderID: UUID? = nil
    @State private var confirmGlowItemID: UUID? = nil
    @State private var confirmGlowOpacity: Double = 0.0
    @State private var cardFrames: [UUID: CGRect] = [:]

    let columns = [GridItem(.adaptive(minimum: 280, maximum: 360), spacing: 12)]

    var allItems: [DashboardItem] {
        if isViewingHidden {
            return store.hiddenDashboardItems(for: projectID)
        } else {
            return store.dashboardItems(for: projectID, folderID: folderID)
        }
    }

    var folderItems: [DashboardItem] { allItems.filter { if case .folder = $0 { return true }; return false } }
    var blobItems: [DashboardItem]   { allItems.filter { if case .blob   = $0 { return true }; return false } }

    var displayFolderItems: [DashboardItem] {
        guard let draggedID = draggedItemID else { return folderItems }
        guard folderItems.contains(where: { $0.id == draggedID }) else { return folderItems }
        var items = folderItems.filter { $0.id != draggedID }
        if let idx = ghostFolderIndex {
            items.insert(.ghost, at: max(0, min(idx, items.count)))
        }
        return items
    }

    var displayBlobItems: [DashboardItem] {
        guard let draggedID = draggedItemID,
              blobItems.contains(where: { $0.id == draggedID }) else { return blobItems }
        if hoveredFolderID != nil {
            // Cursor is over a folder: keep the dragged blob in the grid (rendered invisible below)
            // so the LazyVGrid and its gesture stay in the SwiftUI hierarchy. Without this, SwiftUI
            // cancels the DragGesture when the grid disappears and clearDragState() never fires.
            return blobItems
        }
        var items = blobItems.filter { $0.id != draggedID }
        if let idx = ghostBlobIndex {
            items.insert(.ghost, at: max(0, min(idx, items.count)))
        }
        return items
    }

    var isReadOnly: Bool {
        guard let project = store.projects.first(where: { $0.id == projectID }) else { return true }
        return project.isArchived || isViewingHidden
    }

    var currentFolderName: String? {
        guard let folderID else { return nil }
        return store.projects
            .first(where: { $0.id == projectID })?
            .folders.first(where: { $0.id == folderID })?
            .name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hidden ESC handler — cancels active drag
            Button("") {
                if draggedItemID != nil { clearDragState() }
            }
            .keyboardShortcut(.escape, modifiers: [])
            .frame(width: 0, height: 0)
            .hidden()

            // Hidden items back button
            if isViewingHidden {
                HStack(spacing: 12) {
                    Button(action: { isViewingHidden = false }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(AppColors.shared.contentSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppColors.shared.backgroundPrimary)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)

                    Text("Hidden Items")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.shared.contentPrimary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)
            }

            // Folder breadcrumb header
            if let name = currentFolderName {
                HStack(spacing: 12) {
                    Button(action: { selectedFolderID = nil }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(AppColors.shared.contentSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppColors.shared.backgroundPrimary)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)

                    Text(name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.shared.contentPrimary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Folders section
                    if !displayFolderItems.isEmpty {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(displayFolderItems) { item in
                                CardView(
                                    item: item,
                                    projectID: projectID,
                                    folderID: folderID,
                                    isReadOnly: isReadOnly,
                                    height: 80,
                                    onBlobTap: { _ in },
                                    onFolderTap: { id in selectedFolderID = id },
                                    isDropPreview: hoveredFolderID == item.id,
                                    isDropConfirm: confirmGlowItemID == item.id,
                                    dropConfirmOpacity: confirmGlowItemID == item.id ? confirmGlowOpacity : 0.0
                                )
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .preference(
                                                key: CardFrameKey.self,
                                                value: [item.id: geo.frame(in: .named("dashboard"))]
                                            )
                                    }
                                )
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 8, coordinateSpace: .named("dashboard"))
                                        .onChanged { value in
                                            guard item != .ghost else { return }
                                            if draggedItemID == nil { draggedItemID = item.id }
                                            guard draggedItemID == item.id else { return }
                                            dragLocation = value.location
                                            let baseItems = folderItems.filter { $0.id != item.id }
                                            ghostFolderIndex = ghostIndex(for: value.location, among: baseItems)
                                            ghostBlobIndex = nil
                                            hoveredFolderID = nil
                                        }
                                        .onEnded { value in
                                            guard item != .ghost, draggedItemID == item.id else { return }
                                            defer { clearDragState() }
                                            guard let ghostIdx = ghostFolderIndex else { return }
                                            let allDashItems = store.dashboardItems(for: projectID, folderID: folderID)
                                            guard let fromIndex = allDashItems.firstIndex(where: { $0.id == item.id }) else { return }
                                            let toIndex = folderGhostIndexToAllItemsIndex(ghostIdx: ghostIdx)
                                            guard toIndex != fromIndex else { return }
                                            store.moveItem(in: projectID, fromIndex: fromIndex, toIndex: toIndex, context: folderID)
                                            triggerConfirmGlow(for: item.id)
                                        },
                                    including: isReadOnly ? .subviews : .all
                                )
                                .contextMenu { contextMenuContent(for: item) }
                            }
                        }
                        .animation(.spring(response: 0.30, dampingFraction: 0.80), value: displayFolderItems.map(\.id))
                        .padding(.bottom, displayBlobItems.isEmpty ? 0 : 16)
                    }

                    // Blobs section
                    if !displayBlobItems.isEmpty {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(displayBlobItems) { item in
                                CardView(
                                    item: item,
                                    projectID: projectID,
                                    folderID: folderID,
                                    isReadOnly: isReadOnly,
                                    height: 200,
                                    onBlobTap: { blobID in
                                        if !isReadOnly { activeBlobID = blobID }
                                    },
                                    onFolderTap: { _ in },
                                    isDropPreview: false,
                                    isDropConfirm: confirmGlowItemID == item.id,
                                    dropConfirmOpacity: confirmGlowItemID == item.id ? confirmGlowOpacity : 0.0
                                )
                                // When hovering over a folder, the dragged blob stays in displayBlobItems
                                // (invisible) so the LazyVGrid and this gesture remain in the hierarchy.
                                .opacity(draggedItemID == item.id ? 0.0 : 1.0)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .preference(
                                                key: CardFrameKey.self,
                                                value: [item.id: geo.frame(in: .named("dashboard"))]
                                            )
                                    }
                                )
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 8, coordinateSpace: .named("dashboard"))
                                        .onChanged { value in
                                            guard item != .ghost else { return }
                                            if draggedItemID == nil { draggedItemID = item.id }
                                            guard draggedItemID == item.id else { return }
                                            dragLocation = value.location
                                            // Publish to navigator so folder rows can react via onHover
                                            if case .blob(let blob) = item {
                                                crossPanelDrag.activeBlobID = blob.id
                                                crossPanelDrag.activeProjectID = projectID
                                            }
                                            // Check if cursor is over a folder card
                                            var overFolder: UUID? = nil
                                            for folderItem in folderItems {
                                                if let frame = cardFrames[folderItem.id],
                                                   frame.contains(value.location),
                                                   case .folder(let f) = folderItem {
                                                    overFolder = f.id
                                                    break
                                                }
                                            }
                                            hoveredFolderID = overFolder
                                            if overFolder != nil {
                                                ghostBlobIndex = nil
                                            } else {
                                                let baseItems = blobItems.filter { $0.id != item.id }
                                                ghostBlobIndex = ghostIndex(for: value.location, among: baseItems)
                                            }
                                        }
                                        .onEnded { value in
                                            guard item != .ghost, draggedItemID == item.id else { return }
                                            defer { clearDragState() }
                                            // Case 0: blob dropped onto a navigator folder (cross-panel)
                                            if let navFolderID = crossPanelDrag.targetFolderID,
                                               case .blob(let blob) = item {
                                                store.moveBlobToFolder(blob.id, to: navFolderID, in: projectID)
                                                return
                                            }
                                            // Case 1: blob dropped onto a dashboard folder
                                            if let targetFolderID = hoveredFolderID {
                                                if case .blob(let blob) = item {
                                                    store.moveBlobToFolder(blob.id, to: targetFolderID, in: projectID)
                                                    triggerConfirmGlow(for: targetFolderID)
                                                }
                                                return
                                            }
                                            // Case 2: blob reorder
                                            guard let ghostIdx = ghostBlobIndex else { return }
                                            let allDashItems = store.dashboardItems(for: projectID, folderID: folderID)
                                            guard let fromIndex = allDashItems.firstIndex(where: { $0.id == item.id }) else { return }
                                            let toIndex = blobGhostIndexToAllItemsIndex(ghostIdx: ghostIdx)
                                            guard toIndex != fromIndex else { return }
                                            store.moveItem(in: projectID, fromIndex: fromIndex, toIndex: toIndex, context: folderID)
                                            triggerConfirmGlow(for: item.id)
                                        },
                                    including: isReadOnly ? .subviews : .all
                                )
                                .contextMenu { contextMenuContent(for: item) }
                            }
                        }
                        .animation(.spring(response: 0.30, dampingFraction: 0.80), value: displayBlobItems.map(\.id))
                    }
                }
                .padding(16)
            } // ScrollView
        } // outer VStack
        .coordinateSpace(name: "dashboard")
        .onPreferenceChange(CardFrameKey.self) { frames in
            cardFrames = frames
        }
        .overlay(
            Group {
                if let draggedID = draggedItemID,
                   let draggedItem = allItems.first(where: { $0.id == draggedID })
                {
                    let cardHeight: CGFloat = {
                        switch draggedItem {
                        case .folder: return 80
                        case .blob:   return 200
                        case .ghost:  return 0
                        }
                    }()
                    CardView(
                        item: draggedItem,
                        projectID: projectID,
                        folderID: folderID,
                        isReadOnly: true,
                        height: cardHeight,
                        onBlobTap: { _ in },
                        onFolderTap: { _ in },
                        isDropPreview: false,
                        isDropConfirm: false,
                        dropConfirmOpacity: 0.0
                    )
                    .frame(width: 300)
                    .opacity(0.7)
                    .position(x: dragLocation.x, y: dragLocation.y)
                    .allowsHitTesting(false)
                }
            }
        )
        .overlay(alignment: .bottomTrailing) {
            if !isReadOnly {
                HStack(spacing: 4) {
                    // New folder button
                    Button(action: {
                        _ = store.createFolder(in: projectID, name: "Untitled Folder")
                        triggerIslandGlow(isFolder: true)
                    }) {
                        Image(systemName: glowFolder ? "folder.fill" : "folder")
                            .font(.system(size: 15))
                            .foregroundColor(folderIslandColor)
                            .frame(width: 32, height: 32)
                            .animation(.easeInOut(duration: 0.12), value: glowFolder)
                            .animation(.easeInOut(duration: 0.12), value: hoverFolder)
                    }
                    .buttonStyle(.plain)
                    .disabled(folderID != nil)
                    .onHover { hoverFolder = $0 }

                    // New blob button
                    Button(action: {
                        _ = store.createBlob(in: projectID, folderID: folderID)
                        triggerIslandGlow(isFolder: false)
                    }) {
                        Image(systemName: glowBlob ? "text.document.fill" : "text.document")
                            .font(.system(size: 15))
                            .foregroundColor(blobIslandColor)
                            .frame(width: 32, height: 32)
                            .animation(.easeInOut(duration: 0.12), value: glowBlob)
                            .animation(.easeInOut(duration: 0.12), value: hoverBlob)
                    }
                    .buttonStyle(.plain)
                    .onHover { hoverBlob = $0 }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppColors.shared.backgroundPrimary)
                        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 3)
                )
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
        .alert("Rename Folder", isPresented: $isRenamingFolder) {
            TextField("Folder name", text: $renameFolderText)
            Button("Rename") {
                if let folderID = renameFolderID {
                    store.renameFolder(folderID, in: projectID, to: renameFolderText)
                }
                isRenamingFolder = false
            }
            Button("Cancel", role: .cancel) {
                isRenamingFolder = false
            }
        }
    }

    // MARK: - Drag Helpers

    private func ghostIndex(for cursorPos: CGPoint, among items: [DashboardItem]) -> Int {
        guard !items.isEmpty else { return 0 }
        let framed: [(index: Int, frame: CGRect)] = items.enumerated().compactMap { i, item in
            guard let frame = cardFrames[item.id] else { return nil }
            return (index: i, frame: frame)
        }
        guard !framed.isEmpty else { return 0 }

        var bestIndex = 0
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for entry in framed {
            let center = CGPoint(x: entry.frame.midX, y: entry.frame.midY)
            let dist = hypot(cursorPos.x - center.x, cursorPos.y - center.y)
            if dist < bestDistance {
                bestDistance = dist
                bestIndex = entry.index
            }
        }

        guard let bestFrame = framed.first(where: { $0.index == bestIndex })?.frame else {
            return bestIndex
        }
        if cursorPos.y > bestFrame.midY {
            return bestIndex + 1
        } else if cursorPos.y < bestFrame.minY {
            return bestIndex
        } else {
            return cursorPos.x > bestFrame.midX ? bestIndex + 1 : bestIndex
        }
    }

    // Maps ghost index (position in the reduced folder list) to toIndex for moveItem.
    // New moveItem root-folder branch: fromIndex/toIndex are both 0-based within the folders array.
    // Ghost is at position ghostIdx in the reduced list (folders minus dragged), which equals
    // the desired final position in the full folders array — no offset needed.
    private func folderGhostIndexToAllItemsIndex(ghostIdx: Int) -> Int {
        return min(max(ghostIdx, 0), max(folderItems.count - 1, 0))
    }

    // Maps ghost index (position in the reduced blob list) to toIndex for moveItem.
    // New moveItem root-blob branch: expects toIndex in allDashItems space (offset by folderCount).
    // New moveItem folder branch: expects toIndex 0-based within the folder's blob array.
    private func blobGhostIndexToAllItemsIndex(ghostIdx: Int) -> Int {
        if folderID == nil {
            // Root: shift into allDashItems space (folders occupy indices 0..<folderCount)
            return min(max(ghostIdx + folderItems.count, 0), max(allItems.count - 1, 0))
        } else {
            // Folder context: ghost index IS the target blob index directly
            return min(max(ghostIdx, 0), max(blobItems.count - 1, 0))
        }
    }

    private func clearDragState() {
        draggedItemID = nil
        dragLocation = .zero
        ghostFolderIndex = nil
        ghostBlobIndex = nil
        hoveredFolderID = nil
        crossPanelDrag.clear()
    }

    private func triggerConfirmGlow(for itemID: UUID) {
        confirmGlowItemID = itemID
        confirmGlowOpacity = 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                confirmGlowOpacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                confirmGlowItemID = nil
            }
        }
    }

    // MARK: - Floating island helpers

    private var folderIslandColor: Color {
        guard folderID == nil else { return AppColors.shared.contentTertiary }
        if glowFolder  { return AppColors.shared.confirmation }
        if hoverFolder { return AppColors.shared.contentPrimary }
        return AppColors.shared.contentTertiary
    }

    private var blobIslandColor: Color {
        if glowBlob  { return AppColors.shared.confirmation }
        if hoverBlob { return AppColors.shared.contentPrimary }
        return AppColors.shared.contentTertiary
    }

    private func triggerIslandGlow(isFolder: Bool) {
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

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenuContent(for item: DashboardItem) -> some View {
        switch item {
        case .folder(let folder):
            if folderID == nil {
                if isViewingHidden {
                    Button(action: {
                        store.unhideFolder(folder.id, in: projectID)
                    }) {
                        Label("Restore Folder", systemImage: "eye")
                    }
                    Divider()
                    Button(role: .destructive, action: {
                        store.deleteFolder(folder.id, in: projectID)
                    }) {
                        Label("Delete Folder", systemImage: "trash")
                            .foregroundColor(AppColors.shared.destructive)
                    }
                } else if !isReadOnly {
                    Button(action: {
                        renameFolderID = folder.id
                        renameFolderText = folder.name
                        isRenamingFolder = true
                    }) {
                        Label("Rename Folder", systemImage: "pencil")
                    }
                    Button(action: {
                        store.hideFolder(folder.id, in: projectID)
                    }) {
                        Label("Hide Folder", systemImage: "eye.slash")
                    }
                    Divider()
                    Button(role: .destructive, action: {
                        store.deleteFolder(folder.id, in: projectID)
                    }) {
                        Label("Delete Folder", systemImage: "trash")
                            .foregroundColor(AppColors.shared.destructive)
                    }
                }
            }

        case .blob(let blob):
            if isViewingHidden {
                Button(action: {
                    store.unhideBlob(blob.id, in: projectID)
                }) {
                    Label("Restore Blob", systemImage: "eye")
                }
                Divider()
                Button(role: .destructive, action: {
                    store.deleteBlob(blob.id, in: projectID)
                }) {
                    Label("Delete Blob", systemImage: "trash")
                        .foregroundColor(AppColors.shared.destructive)
                }
            } else if !isReadOnly {
                Button(action: {
                    print("Copy blob \(blob.id)")
                }) {
                    Label("Copy Blob", systemImage: "doc.on.doc")
                }
                Button(action: {
                    store.printBlob(blobID: blob.id, in: projectID)
                }) {
                    Label("Print...", systemImage: "printer")
                }
                if folderID != nil {
                    Button(action: {
                        store.moveBlobToRoot(blob.id, in: projectID)
                    }) {
                        Label("Send Back to Root", systemImage: "arrow.up")
                    }
                }
                Button(action: {
                    store.hideBlob(blob.id, in: projectID)
                }) {
                    Label("Hide Blob", systemImage: "eye.slash")
                }
                Divider()
                Button(role: .destructive, action: {
                    store.deleteBlob(blob.id, in: projectID)
                }) {
                    Label("Delete Blob", systemImage: "trash")
                        .foregroundColor(AppColors.shared.destructive)
                }
            }

        case .ghost:
            EmptyView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ProjectStore())
}
