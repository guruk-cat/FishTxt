import SwiftUI

struct FileNavigatorView: View {
    
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var appColors: AppColors
    @EnvironmentObject var crossPanelDrag: CrossPanelDrag
    @Binding var selectedProjectID: UUID?
    @Binding var selectedFolderID: UUID?
    @Binding var activeBlobID: UUID?

    // Rename state
    @State private var isRenamingProject = false
    @State private var renameProjectID: UUID?
    @State private var renameProjectText = ""
    @State private var isRenamingFolder = false
    @State private var renameFolderID: UUID?
    @State private var renameFolderProjectID: UUID?
    @State private var renameFolderText = ""

    // -------------------------------------------------------------------------
    // Drag state — detailed mode only
    //
    // Key invariant: the dragged item is NEVER removed from its source display
    // list while a drag is active. Removing it destroys the view that owns the
    // DragGesture, which prevents .onEnded from firing, leaving clearDragState()
    // uncalled and the overlay stuck. Instead we keep it at height 0 / opacity 0.
    // -------------------------------------------------------------------------
    @State private var draggedItemID: UUID? = nil 
    @State private var draggedProjectID: UUID? = nil
    // nil  → dragging a folder or root-level blob
    // UUID → dragging a blob that lives inside that folder
    @State private var dragSourceFolderID: UUID? = nil
    @State private var dragLocation: CGPoint = .zero
    @State private var itemFrames: [UUID: CGRect] = [:]
    @State private var ghostFolderIndex: Int? = nil         // target position among folders
    @State private var ghostRootBlobIndex: Int? = nil       // target position among root blobs
    @State private var ghostFolderBlobIndex: Int? = nil     // target position within a folder
    @State private var hoveredFolderID: UUID? = nil         // folder highlighted for blob→folder drop
    @State private var confirmGlowItemID: UUID? = nil
    @State private var confirmGlowOpacity: Double = 0.0

    // Hover state for navigator rows
    @State private var hoveredRowID: UUID? = nil
    @State private var headerRowHovered: Bool = false
    @State private var backButtonHovered: Bool = false
    @State private var plusButtonHovered: Bool = false
    @State private var folderBackButtonHovered: Bool = false

    static let rowHeight: CGFloat = 26

    // MARK: - Convenience

    var allProjects: [Project] {
        store.projects.sorted { $0.createdAt < $1.createdAt }
    }

    // MARK: - Body

    var body: some View {
        if let id = selectedProjectID,
           let project = store.projects.first(where: { $0.id == id }) {
            level2ProjectView(project)
        } else {
            level1ProjectPicker
        }
    }

    // MARK: - Level 1: Project Picker

    private var level1ProjectPicker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // PROJECTS header
                HStack {
                    Text("PROJECTS")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(AppColors.shared.contentSecondary)
                    Spacer()
                    Button {
                        let p = store.createProject(name: "Untitled Project")
                        selectedProjectID = p.id
                        selectedFolderID = nil
                        activeBlobID = nil
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(plusButtonHovered ? AppColors.shared.contentSecondary : AppColors.shared.contentTertiary)
                    }
                    .buttonStyle(.plain)
                    .onHover { plusButtonHovered = $0 }
                }
                .padding(.horizontal, 8)
                .padding(.top, 12)
                .padding(.bottom, 4)

                ForEach(allProjects) { project in
                    level1ProjectRow(project)
                }
            }
            .padding(.bottom, 12)
        }
        .alert("Rename Project", isPresented: $isRenamingProject) {
            TextField("Project name", text: $renameProjectText)
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                if let id = renameProjectID { store.renameProject(id, to: renameProjectText) }
            }
        }
    }

    // MARK: - Level 1: Project Row

    @ViewBuilder
    private func level1ProjectRow(_ project: Project) -> some View {
        let isRowHovered = hoveredRowID == project.id

        HStack(spacing: 6) {
            Text(project.name)
                .font(.system(size: 13))
                .foregroundColor(isRowHovered ? AppColors.shared.contentPrimary : AppColors.shared.contentTertiary)
            Spacer()
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .contentShape(Rectangle())
        .onHover { h in
            hoveredRowID = h ? project.id : (hoveredRowID == project.id ? nil : hoveredRowID)
        }
        .onTapGesture {
            selectedProjectID = project.id
            selectedFolderID = nil
            activeBlobID = nil
        }
        .contextMenu { projectContextMenu(project) }
    }

    // MARK: - Level 2: Project Contents

    @ViewBuilder
    private func level2ProjectView(_ project: Project) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header with project name and back button
                HStack(spacing: 8) {
                    Text(project.name.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(AppColors.shared.contentSecondary)
                        .onTapGesture { selectProject(project) }
                    Spacer()
                    Button {
                        selectedProjectID = nil
                        selectedFolderID = nil
                        activeBlobID = nil
                    } label: {
                        Image(systemName: "arrow.uturn.left")
                            .font(.system(size: 11))
                            .foregroundColor(backButtonHovered ? AppColors.shared.contentSecondary : AppColors.shared.contentTertiary)
                    }
                    .buttonStyle(.plain)
                    .onHover { backButtonHovered = $0 }
                    .opacity(headerRowHovered ? 1 : 0)
                }
                .padding(.horizontal, 8)
                .padding(.top, 12)
                .padding(.bottom, 4)
                .contentShape(Rectangle())
                .onHover { headerRowHovered = $0 }

                // Folders and root blobs
                let folders = displayFolders(for: project)
                let rootBlobs = displayRootBlobs(for: project)

                VStack(alignment: .leading, spacing: 0) {
                    // Folders
                    ForEach(folders) { item in
                        if case .ghost = item {
                            treeGhost()
                                .padding(.leading, 22)
                                .padding(.vertical, 1)
                        } else if case .folder(let folder) = item {
                            let isDragged = draggedItemID == folder.id
                            detailedFolderRow(folder, in: project)
                                .frame(height: isDragged ? 0 : nil)
                                .clipped()
                                .opacity(isDragged ? 0 : 1)
                        }
                    }
                    .animation(.spring(response: 0.25, dampingFraction: 0.82),
                               value: folders.map(\.id))

                    // Root blobs
                    ForEach(rootBlobs) { item in
                        if case .ghost = item {
                            treeGhost()
                                .padding(.leading, 22)
                                .padding(.vertical, 1)
                        } else if case .blob(let blob) = item {
                            let isDragged = draggedItemID == blob.id
                            let isInvisible = isDragged && hoveredFolderID != nil
                            BlobTreeRow(
                                blob: blob, projectID: project.id,
                                isActive: activeBlobID == blob.id,
                                isGlowing: confirmGlowItemID == blob.id,
                                glowOpacity: confirmGlowItemID == blob.id ? confirmGlowOpacity : 0,
                                indent: 22
                            )
                            .frame(height: Self.rowHeight)
                            .frame(height: isInvisible ? 0 : nil)
                            .clipped()
                            .opacity(isInvisible ? 0 : 1)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedProjectID = project.id
                                selectedFolderID = nil
                                activeBlobID = blob.id
                            }
                            .background(frameTracker(.blob(blob)))
                            .simultaneousGesture(
                                rootBlobDrag(blob: blob, project: project),
                                including: .all
                            )
                            .contextMenu { blobContextMenu(blob, project: project, isInFolder: false) }
                        }
                    }
                    .animation(.spring(response: 0.25, dampingFraction: 0.82),
                               value: rootBlobs.map(\.id))
                }
            }
        }
        .coordinateSpace(name: "sidebarNav")
        .onPreferenceChange(CardFrameKey.self) { itemFrames = $0 }
        .overlay(dragOverlay)
        .alert("Rename Folder", isPresented: $isRenamingFolder) {
            TextField("Folder name", text: $renameFolderText)
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                if let fid = renameFolderID, let pid = renameFolderProjectID {
                    store.renameFolder(fid, in: pid, to: renameFolderText)
                }
            }
        }
    }

    // MARK: - Expansion helpers (derived from selection — no manual state)

    private func isFolderExpanded(_ folder: BlobFolder, in project: Project) -> Bool {
        if selectedFolderID == folder.id { return true }
        if let blobID = activeBlobID,
           let blob = project.blobs.first(where: { $0.id == blobID }),
           blob.folderID == folder.id { return true }
        return false
    }

    // MARK: - Detailed folder row

    @ViewBuilder
    private func detailedFolderRow(_ folder: BlobFolder, in project: Project) -> some View {
        let isFolderExpanded = isFolderExpanded(folder, in: project)
        let hasBlobs  = project.blobs.contains { $0.folderID == folder.id }
        let isDragHovered = hoveredFolderID == folder.id
            || (crossPanelDrag.activeProjectID == project.id && crossPanelDrag.targetFolderID == folder.id)
        let isGlowing = confirmGlowItemID == folder.id
        let blobs     = displayFolderBlobs(folder: folder, project: project)

        VStack(alignment: .leading, spacing: 0) {
            // Folder header
            let isFolderSelected = selectedProjectID == project.id
                && selectedFolderID == folder.id
                && activeBlobID == nil
            let isRowHovered = hoveredRowID == folder.id
            HStack(spacing: 4) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 11))
                    .foregroundColor(
                        isFolderSelected ? AppColors.shared.contentSecondary :
                        isDragHovered    ? AppColors.shared.accent :
                        isRowHovered     ? AppColors.shared.contentPrimary :
                                           AppColors.shared.contentTertiary)
                Text(folder.name)
                    .font(.system(size: 12))
                    .foregroundColor(
                        isFolderSelected ? AppColors.shared.contentSecondary :
                        isDragHovered    ? AppColors.shared.accent :
                        isRowHovered     ? AppColors.shared.contentPrimary :
                                           AppColors.shared.contentTertiary)
                    .lineLimit(1)
                Spacer()
                if isFolderSelected {
                    Button {
                        selectProject(project)
                    } label: {
                        Image(systemName: "arrow.uturn.left")
                            .font(.system(size: 11))
                            .foregroundColor(folderBackButtonHovered ? AppColors.shared.contentSecondary : AppColors.shared.contentTertiary)
                    }
                    .buttonStyle(.plain)
                    .onHover { folderBackButtonHovered = $0 }
                    .opacity(isRowHovered ? 1 : 0)
                }
            }
            .padding(.leading, 22).padding(.trailing, 8).padding(.vertical, 4)
            // Chevron sits inside the 22px leading space without pushing folder icon right
            .overlay(alignment: .leading) {
                Image(systemName: isFolderExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(hasBlobs
                        ? (isFolderSelected ? AppColors.shared.contentSecondary :
                           isRowHovered     ? AppColors.shared.contentPrimary :
                                              AppColors.shared.contentTertiary)
                        : Color.clear)
                    .frame(width: 14)
                    .padding(.leading, 6)
            }
            .frame(height: Self.rowHeight)
            .background(
                isDragHovered
                    ? AppColors.shared.accent.opacity(0.12)
                    : (isFolderSelected
                        ? AppColors.shared.backgroundHighlight.opacity(0.2)
                        : Color.clear)
            )
            .overlay(
                isFolderSelected
                    ? Rectangle().frame(width: 2).foregroundColor(AppColors.shared.contentSecondary)
                    : nil,
                alignment: .leading
            )
            .overlay(
                isGlowing
                    ? RoundedRectangle(cornerRadius: 4)
                        .stroke(AppColors.shared.confirmation.opacity(confirmGlowOpacity), lineWidth: 1)
                    : nil
            )
            .contentShape(Rectangle())
            .onHover { h in
                hoveredRowID = h ? folder.id : (hoveredRowID == folder.id ? nil : hoveredRowID)
                if crossPanelDrag.activeBlobID != nil && crossPanelDrag.activeProjectID == project.id {
                    crossPanelDrag.targetFolderID = h ? folder.id : (crossPanelDrag.targetFolderID == folder.id ? nil : crossPanelDrag.targetFolderID)
                }
            }
            .onTapGesture {
                selectedProjectID = project.id; selectedFolderID = folder.id; activeBlobID = nil
            }
            .background(frameTracker(.folder(folder)))
            .simultaneousGesture(folderDrag(folder: folder, project: project))
            .contextMenu {
                Button {
                    renameFolderID = folder.id; renameFolderProjectID = project.id
                    renameFolderText = folder.name; isRenamingFolder = true
                } label: { Label("Rename Folder", systemImage: "pencil") }
                Divider()
                Button(role: .destructive) {
                    store.deleteFolder(folder.id, in: project.id)
                } label: { Label("Delete Folder", systemImage: "trash") }
            }

            // Blobs inside folder (when expanded)
            if isFolderExpanded {
                ForEach(blobs) { item in
                    if case .ghost = item {
                        treeGhost()
                            .padding(.leading, 38)
                            .padding(.vertical, 1)
                    } else if case .blob(let blob) = item {
                        let isDragged = draggedItemID == blob.id
                        // Collapse to 0 when the blob is leaving for another folder or root,
                        // but keep in hierarchy so the gesture continues to fire.
                        let isLeaving = isDragged && (hoveredFolderID != nil || ghostRootBlobIndex != nil)
                        BlobTreeRow(
                            blob: blob, projectID: project.id,
                            isActive: activeBlobID == blob.id,
                            isGlowing: confirmGlowItemID == blob.id,
                            glowOpacity: confirmGlowItemID == blob.id ? confirmGlowOpacity : 0,
                            indent: 38
                        )
                        .frame(height: Self.rowHeight)
                        .frame(height: isLeaving ? 0 : nil)
                        .clipped()
                        .opacity(isLeaving ? 0 : 1)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedProjectID = project.id
                            selectedFolderID = nil
                            activeBlobID = blob.id
                        }
                        .background(frameTracker(.blob(blob)))
                        .simultaneousGesture(
                            folderBlobDrag(blob: blob, project: project, sourceFolderID: folder.id),
                            including: .all
                        )
                        .contextMenu { blobContextMenu(blob, project: project, isInFolder: true) }
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.82),
                           value: blobs.map(\.id))
            }
        }
    }

    // MARK: - Ghost row

    private func treeGhost() -> some View {
        RoundedRectangle(cornerRadius: 4)
            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            .foregroundColor(AppColors.shared.contentTertiary.opacity(0.4))
            .frame(height: Self.rowHeight - 4)
    }

    // MARK: - Frame tracker

    private func frameTracker(_ item: DashboardItem) -> some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: CardFrameKey.self,
                value: [item.id: geo.frame(in: .named("sidebarNav"))]
            )
        }
    }

    // MARK: - Drag overlay

    @ViewBuilder
    private var dragOverlay: some View {
        if let id = draggedItemID, let pid = draggedProjectID,
           let project = store.projects.first(where: { $0.id == pid }) {
            Group {
                if let folder = project.folders.first(where: { $0.id == id }) {
                    dragPreview(icon: "folder.fill", text: folder.name)
                } else if let blob = project.blobs.first(where: { $0.id == id }) {
                    BlobDragPreview(blob: blob, projectID: pid)
                        .environmentObject(store)
                }
            }
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            .position(x: dragLocation.x, y: dragLocation.y)
            .allowsHitTesting(false)
        }
    }

    private func dragPreview(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11))
                .foregroundColor(AppColors.shared.contentSecondary)
            Text(text).font(.system(size: 12)).lineLimit(1)
                .foregroundColor(AppColors.shared.contentSecondary)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(AppColors.shared.backgroundPrimary)
        .cornerRadius(5)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(AppColors.shared.cardBorder, lineWidth: 1))
        .frame(width: 160, alignment: .leading)
    }

    // =========================================================================
    // MARK: - Display lists
    //
    // Each function returns the items to render for a given section.
    // The dragged item is ALWAYS included in its source list so its view stays
    // in the hierarchy (preserving the gesture). A ghost is inserted at the
    // computed target position. The dragged item is rendered invisible/collapsed
    // at the call site.
    // =========================================================================

    private func displayFolders(for project: Project) -> [DashboardItem] {
        var all = project.folders.sorted { $0.sortOrder < $1.sortOrder }.map(DashboardItem.folder)
        guard let id = draggedItemID,
              draggedProjectID == project.id,
              dragSourceFolderID == nil,
              let dragPos = all.firstIndex(where: { $0.id == id }),
              let ghostIdx = ghostFolderIndex else { return all }
        // Insert ghost at the correct slot in the full list (dragged item stays)
        let insertAt = min(max(ghostIdx <= dragPos ? ghostIdx : ghostIdx + 1, 0), all.count)
        all.insert(.ghost, at: insertAt)
        return all
    }

    private func displayRootBlobs(for project: Project) -> [DashboardItem] {
        var all = project.blobs
            .filter { $0.folderID == nil }
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(DashboardItem.blob)
        guard let id = draggedItemID, draggedProjectID == project.id else { return all }

        if dragSourceFolderID == nil, let dragPos = all.firstIndex(where: { $0.id == id }) {
            // Root blob reorder — keep dragged item, insert ghost
            guard hoveredFolderID == nil, let ghostIdx = ghostRootBlobIndex else { return all }
            let insertAt = min(max(ghostIdx <= dragPos ? ghostIdx : ghostIdx + 1, 0), all.count)
            all.insert(.ghost, at: insertAt)
        } else if dragSourceFolderID != nil {
            // Folder blob dragging out to root — just show ghost, no dragged item here
            if let ghostIdx = ghostRootBlobIndex {
                all.insert(.ghost, at: max(0, min(ghostIdx, all.count)))
            }
        }
        return all
    }

    private func displayFolderBlobs(folder: BlobFolder, project: Project) -> [DashboardItem] {
        var all = project.blobs
            .filter { $0.folderID == folder.id }
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(DashboardItem.blob)
        guard let id = draggedItemID,
              draggedProjectID == project.id,
              dragSourceFolderID == folder.id,
              let dragPos = all.firstIndex(where: { $0.id == id }) else { return all }

        // When leaving for another folder or root: keep item (at 0 height) but no ghost here
        if hoveredFolderID != nil || ghostRootBlobIndex != nil { return all }

        // Reorder within this folder
        guard let ghostIdx = ghostFolderBlobIndex else { return all }
        let insertAt = min(max(ghostIdx <= dragPos ? ghostIdx : ghostIdx + 1, 0), all.count)
        all.insert(.ghost, at: insertAt)
        return all
    }

    // =========================================================================
    // MARK: - Ghost index helper
    //
    // Returns the target insertion index within `items` (a reduced list that
    // does NOT contain the dragged item). The value maps directly to the
    // `toIndex` accepted by store.moveItem after it removes the source item.
    // =========================================================================
    private func ghostIndex(cursor: CGPoint, among items: [DashboardItem]) -> Int {
        let framed: [(Int, CGRect)] = items.enumerated().compactMap { i, item in
            guard let f = itemFrames[item.id] else { return nil }
            return (i, f)
        }.sorted { $0.1.minY < $1.1.minY }
        guard !framed.isEmpty else { return 0 }
        for (i, frame) in framed {
            if cursor.y < frame.midY { return i }
        }
        return framed.count
    }

    // =========================================================================
    // MARK: - Drag gestures
    // =========================================================================

    private func folderDrag(folder: BlobFolder, project: Project) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .named("sidebarNav"))
            .onChanged { v in
                if draggedItemID == nil {
                    draggedItemID = folder.id
                    draggedProjectID = project.id
                    dragSourceFolderID = nil
                }
                guard draggedItemID == folder.id else { return }
                dragLocation = v.location
                // Ghost position among other folders (reduced list)
                let others = project.folders.sorted { $0.sortOrder < $1.sortOrder }
                    .filter { $0.id != folder.id }.map(DashboardItem.folder)
                ghostFolderIndex = ghostIndex(cursor: v.location, among: others)
                ghostRootBlobIndex = nil; ghostFolderBlobIndex = nil; hoveredFolderID = nil
            }
            .onEnded { _ in
                guard draggedItemID == folder.id else { return }
                defer { clearDragState() }
                guard let ghostIdx = ghostFolderIndex else { return }
                let current = store.projects.first { $0.id == project.id } ?? project
                let sorted  = current.folders.sorted { $0.sortOrder < $1.sortOrder }
                guard let from = sorted.firstIndex(where: { $0.id == folder.id }) else { return }
                let to = min(max(ghostIdx, 0), sorted.count - 1)
                guard to != from else { return }
                store.moveItem(in: project.id, fromIndex: from, toIndex: to, context: nil)
                triggerGlow(for: folder.id)
            }
    }

    private func rootBlobDrag(blob: Blob, project: Project) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .named("sidebarNav"))
            .onChanged { v in
                if draggedItemID == nil {
                    draggedItemID = blob.id
                    draggedProjectID = project.id
                    dragSourceFolderID = nil
                }
                guard draggedItemID == blob.id else { return }
                dragLocation = v.location
                ghostFolderBlobIndex = nil
                let current = store.projects.first { $0.id == project.id } ?? project
                // Check hover over any folder
                for f in current.folders {
                    if let frame = itemFrames[f.id], frame.contains(v.location) {
                        hoveredFolderID = f.id; ghostRootBlobIndex = nil; return
                    }
                }
                hoveredFolderID = nil
                let others = current.blobs.filter { $0.folderID == nil && $0.id != blob.id }
                    .sorted { $0.sortOrder < $1.sortOrder }.map(DashboardItem.blob)
                ghostRootBlobIndex = ghostIndex(cursor: v.location, among: others)
            }
            .onEnded { _ in
                guard draggedItemID == blob.id else { return }
                defer { clearDragState() }
                let current = store.projects.first { $0.id == project.id } ?? project
                if let target = hoveredFolderID {
                    store.moveBlobToFolder(blob.id, to: target, in: project.id)
                    triggerGlow(for: target); return
                }
                guard let ghostIdx = ghostRootBlobIndex else { return }
                let rootBlobs = current.blobs.filter { $0.folderID == nil }
                    .sorted { $0.sortOrder < $1.sortOrder }
                guard let from = rootBlobs.firstIndex(where: { $0.id == blob.id }) else { return }
                let to = min(max(ghostIdx, 0), rootBlobs.count - 1)
                guard to != from else { return }
                store.moveItem(in: project.id, fromIndex: current.folders.count + from,
                               toIndex: current.folders.count + to, context: nil)
                triggerGlow(for: blob.id)
            }
    }

    private func folderBlobDrag(blob: Blob, project: Project, sourceFolderID: UUID) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .named("sidebarNav"))
            .onChanged { v in
                if draggedItemID == nil {
                    draggedItemID = blob.id
                    draggedProjectID = project.id
                    dragSourceFolderID = sourceFolderID
                }
                guard draggedItemID == blob.id else { return }
                dragLocation = v.location
                let current = store.projects.first { $0.id == project.id } ?? project
                // Hover over a different folder?
                for f in current.folders where f.id != sourceFolderID {
                    if let frame = itemFrames[f.id], frame.contains(v.location) {
                        hoveredFolderID = f.id
                        ghostFolderBlobIndex = nil; ghostRootBlobIndex = nil; return
                    }
                }
                hoveredFolderID = nil
                // Are we over the root blob zone or below the folder's content?
                let rootBlobItems = current.blobs.filter { $0.folderID == nil }
                    .sorted { $0.sortOrder < $1.sortOrder }.map(DashboardItem.blob)
                let folderBlobItems = current.blobs.filter { $0.folderID == sourceFolderID }
                    .sorted { $0.sortOrder < $1.sortOrder }.map(DashboardItem.blob)
                let folderMaxY = folderBlobItems.compactMap { itemFrames[$0.id]?.maxY }.max() ?? 0
                let isOverRoot = rootBlobItems.contains {
                    itemFrames[$0.id].map { $0.insetBy(dx: 0, dy: -6).contains(v.location) } ?? false
                }
                let isBelowFolder = !rootBlobItems.isEmpty && v.location.y > folderMaxY + 6

                if isOverRoot || isBelowFolder {
                    let others = rootBlobItems.filter { $0.id != blob.id }
                    ghostRootBlobIndex  = ghostIndex(cursor: v.location, among: others)
                    ghostFolderBlobIndex = nil
                } else {
                    let others = folderBlobItems.filter { $0.id != blob.id }
                    ghostFolderBlobIndex = ghostIndex(cursor: v.location, among: others)
                    ghostRootBlobIndex  = nil
                }
            }
            .onEnded { _ in
                guard draggedItemID == blob.id else { return }
                defer { clearDragState() }
                let current = store.projects.first { $0.id == project.id } ?? project
                // Drop onto a different folder
                if let target = hoveredFolderID {
                    store.moveBlobToFolder(blob.id, to: target, in: project.id)
                    triggerGlow(for: target); return
                }
                // Move to root with positional drop
                if let ghostIdx = ghostRootBlobIndex {
                    store.moveBlobToRoot(blob.id, in: project.id)
                    // Reposition in the now-updated project
                    let updated   = store.projects.first { $0.id == project.id } ?? current
                    let rootBlobs = updated.blobs.filter { $0.folderID == nil }
                        .sorted { $0.sortOrder < $1.sortOrder }
                    if let from = rootBlobs.firstIndex(where: { $0.id == blob.id }) {
                        let to = min(max(ghostIdx, 0), rootBlobs.count - 1)
                        if to != from {
                            store.moveItem(in: project.id,
                                           fromIndex: updated.folders.count + from,
                                           toIndex:   updated.folders.count + to,
                                           context: nil)
                        }
                    }
                    triggerGlow(for: blob.id); return
                }
                // Reorder within folder
                if let ghostIdx = ghostFolderBlobIndex {
                    let folderBlobs = current.blobs.filter { $0.folderID == sourceFolderID }
                        .sorted { $0.sortOrder < $1.sortOrder }
                    guard let from = folderBlobs.firstIndex(where: { $0.id == blob.id }) else { return }
                    let to = min(max(ghostIdx, 0), folderBlobs.count - 1)
                    guard to != from else { return }
                    store.moveItem(in: project.id, fromIndex: from, toIndex: to, context: sourceFolderID)
                    triggerGlow(for: blob.id)
                }
            }
    }

    // MARK: - Helpers

    private func clearDragState() {
        draggedItemID = nil; draggedProjectID = nil; dragSourceFolderID = nil
        dragLocation = .zero; ghostFolderIndex = nil; ghostRootBlobIndex = nil
        ghostFolderBlobIndex = nil; hoveredFolderID = nil
    }

    private func triggerGlow(for id: UUID) {
        confirmGlowItemID = id; confirmGlowOpacity = 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.4)) { confirmGlowOpacity = 0.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { confirmGlowItemID = nil }
        }
    }

    private func selectProject(_ project: Project) {
        selectedProjectID = project.id; selectedFolderID = nil; activeBlobID = nil
    }
    private func beginRenameProject(_ project: Project) {
        renameProjectID = project.id; renameProjectText = project.name; isRenamingProject = true
    }

    @ViewBuilder
    private func projectContextMenu(_ project: Project) -> some View {
        Button { selectProject(project) } label: { Label("Open", systemImage: "arrow.right") }
        Button { beginRenameProject(project) } label: { Label("Rename", systemImage: "pencil") }
        Button { _ = store.createFolder(in: project.id, name: "Untitled Folder") } label: {
            Label("New Folder", systemImage: "folder.badge.plus")
        }
        Button { _ = store.createBlob(in: project.id) } label: {
            Label("New Blob", systemImage: "doc.badge.plus")
        }
        Divider()
        Button(role: .destructive) {
            store.deleteProject(project.id)
            if selectedProjectID == project.id {
                selectedProjectID = nil; selectedFolderID = nil; activeBlobID = nil
            }
        } label: { Label("Delete Project", systemImage: "trash") }
    }

    @ViewBuilder
    private func blobContextMenu(_ blob: Blob, project: Project, isInFolder: Bool) -> some View {
        Button { store.printBlob(blobID: blob.id, in: project.id) } label: {
            Label("Print...", systemImage: "printer")
        }
        if isInFolder {
            Button { store.moveBlobToRoot(blob.id, in: project.id) } label: {
                Label("Send Back to Root", systemImage: "arrow.up")
            }
        }
        Divider()
        Button(role: .destructive) { store.deleteBlob(blob.id, in: project.id) } label: {
            Label("Delete Blob", systemImage: "trash")
        }
    }
}

// MARK: - BlobTreeRow

private struct BlobTreeRow: View {
    @EnvironmentObject var store: ProjectStore
    let blob: Blob
    let projectID: UUID
    let isActive: Bool
    let isGlowing: Bool
    let glowOpacity: Double
    let indent: CGFloat
    @State private var title: String?
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.text")
                .font(.system(size: 10))
                .foregroundColor(isActive
                    ? AppColors.shared.contentSecondary
                    : (isHovered ? AppColors.shared.contentPrimary : AppColors.shared.contentTertiary))
            Text(title ?? "Untitled")
                .font(.system(size: 12))
                .foregroundColor(isActive
                    ? AppColors.shared.contentSecondary
                    : (isHovered ? AppColors.shared.contentPrimary : AppColors.shared.contentTertiary))
                .lineLimit(1)
            Spacer()
        }
        .padding(.leading, indent).padding(.trailing, 8).padding(.vertical, 4)
        .background(isActive ? AppColors.shared.backgroundHighlight.opacity(0.2) : Color.clear)
        .overlay(
            isActive
                ? Rectangle().frame(width: 2).foregroundColor(AppColors.shared.contentSecondary)
                : nil,
            alignment: .leading
        )
        .overlay(isGlowing
            ? RoundedRectangle(cornerRadius: 4)
                .stroke(AppColors.shared.confirmation.opacity(glowOpacity), lineWidth: 1)
            : nil)
        .onHover { isHovered = $0 }
        .task(id: blob.updatedAt) {
            let result = await Task.detached(priority: .utility) {
                await store.loadBlobExcerpt(blobID: blob.id, in: projectID)
            }.value
            title = result.title ?? result.body.flatMap { String($0.prefix(40)) }
        }
    }
}

// MARK: - BlobDragPreview

private struct BlobDragPreview: View {
    @EnvironmentObject var store: ProjectStore
    let blob: Blob
    let projectID: UUID
    @State private var title: String?

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "doc.text").font(.system(size: 10))
                .foregroundColor(AppColors.shared.contentSecondary)
            Text(title ?? "Untitled").font(.system(size: 12)).lineLimit(1)
                .foregroundColor(AppColors.shared.contentSecondary)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(AppColors.shared.backgroundPrimary)
        .cornerRadius(5)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(AppColors.shared.cardBorder, lineWidth: 1))
        .frame(width: 160, alignment: .leading)
        .task {
            let result = await Task.detached(priority: .utility) {
                await store.loadBlobExcerpt(blobID: blob.id, in: projectID)
            }.value
            title = result.title ?? result.body.flatMap { String($0.prefix(40)) }
        }
    }
}

#Preview {
    FileNavigatorView(
        selectedProjectID: .constant(nil),
        selectedFolderID: .constant(nil),
        activeBlobID: .constant(nil)
    )
    .environmentObject(ProjectStore())
    .environmentObject(AppColors.shared)
    .frame(width: 220)
}
