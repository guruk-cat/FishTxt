import SwiftUI

// MARK: Supporting types

private enum MergeListEntry: Identifiable {
    case blob(UUID)
    case ghost

    var id: String {
        switch self {
        case .blob(let id): return id.uuidString
        case .ghost: return "ghost"
        }
    }
}

private struct MergeListFrameKey: PreferenceKey {
    typealias Value = [UUID: CGRect]
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: View

struct BlobMergeView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var appColors: AppColors

    @Binding var selectedProjectID: UUID?
    @Binding var selectedFolderID: UUID?
    @Binding var activeBlobID: UUID?

    // Blob list state
    @State private var orderedBlobIDs: [UUID] = []
    @State private var blobTitles: [UUID: String] = [:]
    @State private var checkedBlobIDs: Set<UUID> = []

    // Merge settings
    @State private var mergeMode: BlobMergeMode = .newHeading
    @State private var newHeadingText: String = ""
    @State private var deleteAfterMerge: Bool = false

    // Drag state
    @State private var draggedBlobID: UUID? = nil
    @State private var dragLocation: CGPoint = .zero
    @State private var ghostDragIndex: Int? = nil
    @State private var blobFrames: [UUID: CGRect] = [:]
    @State private var confirmGlowID: UUID? = nil
    @State private var confirmGlowOpacity: Double = 0.0

    // Hover states
    @State private var hoverSelectAll: Bool = false
    @State private var hoverMerge: Bool = false

    private static let rowHeight: CGFloat = 26

    private var allSelected: Bool {
        !orderedBlobIDs.isEmpty && orderedBlobIDs.allSatisfy { checkedBlobIDs.contains($0) }
    }

    // Builds the display list: all blob entries (dragged one kept but hidden) + ghost inserted.
    // ghostDragIndex is in "without-dragged" terms; map it to a full-list insertion point.
    private var displayItems: [MergeListEntry] {
        var items = orderedBlobIDs.map { MergeListEntry.blob($0) }
        guard let dragID = draggedBlobID,
              let gIdx = ghostDragIndex,
              let sourceIdx = orderedBlobIDs.firstIndex(of: dragID) else {
            return items
        }
        // If ghost target is before the dragged item's slot, insert at gIdx directly.
        // If at or after, shift by 1 to account for the hidden dragged item occupying a slot.
        let fullIdx = gIdx <= sourceIdx ? gIdx : gIdx + 1
        items.insert(.ghost, at: min(fullIdx, items.count))
        return items
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(spacing: 0) {
                    headerRow
                    blobList
                    settingsSection
                    mergeSection
                }
                .padding(.trailing, 8)
                .padding(.leading, 8)
            }

            dragOverlay
        }
        .coordinateSpace(name: "mergeList")
        .onPreferenceChange(MergeListFrameKey.self) { blobFrames = $0 }
        .onAppear { loadBlobs() }
        .onChange(of: selectedProjectID) { _ in loadBlobs() }
        .onChange(of: selectedFolderID) { _ in loadBlobs() }
        .onChange(of: store.projects) { _ in syncBlobs() }
    }

    // MARK: Header

    private var headerRow: some View {
        HStack {
                Text("MERGE BLOBS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(AppColors.shared.contentSecondary)
                Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 6)
    }
    
    // MARK: Merge section
    
    private var mergeSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppColors.shared.contentTertiary.opacity(0.2))
                .frame(height: 1)
                .padding(.top, 8)
                .padding(.bottom, 8)
            
            HStack {
                Text("3. Merge")
                    .font(.system(size: 12))
                    .tracking(0.5)
                    .foregroundColor(AppColors.shared.contentSecondary)
                Spacer()
            }.padding(.bottom, 8)

            // New H1 heading text field
            TextField("New H1 heading…", text: $newHeadingText)
                .font(.system(size: 13))
                .textFieldStyle(.plain)
                .foregroundColor(
                    mergeMode == .newHeading
                        ? AppColors.shared.contentPrimary
                        : AppColors.shared.contentTertiary
                )
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.shared.backgroundSecondary.opacity(
                            mergeMode == .newHeading ? 0.6 : 0.3
                        ))
                )
                .padding(.top, 8)
                .disabled(mergeMode == .simple)
            
            // Merge button
            Button(action: performMerge) {
                Text("Merge")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(
                        hoverMerge
                            ? AppColors.shared.backgroundPrimary
                            : AppColors.shared.contentPrimary
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(hoverMerge
                                  ? AppColors.shared.accent
                                  : AppColors.shared.backgroundSecondary
                            )
                    )
                    .animation(.easeInOut(duration: 0.12), value: hoverMerge)
            }
            .buttonStyle(.plain)
            .onHover { hoverMerge = $0 }
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
    }

    // MARK: Blob list

    @ViewBuilder
    private var blobList: some View {
        VStack {
            Rectangle()
                .fill(AppColors.shared.contentTertiary.opacity(0.2))
                .frame(height: 1)
                .padding(.top, 8)
                .padding(.bottom, 8)

            HStack {
                Text("1. Select Blobs")
                    .font(.system(size: 12))
                    .tracking(0.5)
                    .foregroundColor(AppColors.shared.contentSecondary)
                
                Spacer()
                
                Button(action: toggleSelectAll) {
                    Text(allSelected ? "Deselect All" : "Select All")
                        .font(.system(size: 11))
                        .foregroundColor(
                            hoverSelectAll
                            ? AppColors.shared.contentPrimary
                            : AppColors.shared.contentTertiary
                        )
                        .animation(.easeInOut(duration: 0.12), value: hoverSelectAll)
                }
                .buttonStyle(.plain)
                .onHover { hoverSelectAll = $0 }
                .disabled(orderedBlobIDs.isEmpty)
            }
            .padding(.bottom, 6)
        }
        
        if orderedBlobIDs.isEmpty {
            Text("No blobs in this context.")
                .font(.system(size: 12))
                .foregroundColor(AppColors.shared.contentTertiary)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            ForEach(displayItems) { entry in
                switch entry {
                case .ghost:
                    ghostRow
                case .blob(let blobID):
                    blobRow(blobID)
                        .opacity(draggedBlobID == blobID ? 0 : 1)
                        .frame(height: draggedBlobID == blobID ? 0 : Self.rowHeight)
                        .clipped()
                }
            }
        }
    }

    private func blobRow(_ blobID: UUID) -> some View {
        let isChecked = checkedBlobIDs.contains(blobID)
        let isGlowing = confirmGlowID == blobID
        return HStack(spacing: 6) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 10))
                .foregroundColor(AppColors.shared.contentTertiary.opacity(0.5))

            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                .font(.system(size: 12))
                .foregroundColor(
                    isChecked
                        ? AppColors.shared.accent
                        : AppColors.shared.contentTertiary
                )

            Text(blobTitles[blobID] ?? "Untitled")
                .font(.system(size: 12))
                .foregroundColor(AppColors.shared.contentPrimary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, 4)
        .frame(height: Self.rowHeight)
        .contentShape(Rectangle())
        .overlay(
            isGlowing
                ? RoundedRectangle(cornerRadius: 4)
                    .stroke(AppColors.shared.confirmation.opacity(confirmGlowOpacity), lineWidth: 1)
                : nil
        )
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: MergeListFrameKey.self,
                    value: [blobID: geo.frame(in: .named("mergeList"))]
                )
            }
        )
        .onTapGesture { toggleCheck(blobID) }
        .simultaneousGesture(
            DragGesture(minimumDistance: 8, coordinateSpace: .named("mergeList"))
                .onChanged { value in
                    if draggedBlobID == nil { draggedBlobID = blobID }
                    guard draggedBlobID == blobID else { return }
                    dragLocation = value.location
                    ghostDragIndex = computeGhostIndex(cursor: value.location)
                }
                .onEnded { _ in
                    guard draggedBlobID == blobID else { return }
                    defer { clearDragState() }
                    guard let gIdx = ghostDragIndex,
                          let sourceIdx = orderedBlobIDs.firstIndex(of: blobID) else { return }

                    // gIdx is the target index in the "without-dragged" list.
                    // Remove source, then insert at gIdx (which is now correct).
                    var newOrder = orderedBlobIDs
                    newOrder.remove(at: sourceIdx)
                    newOrder.insert(blobID, at: max(0, min(gIdx, newOrder.count)))
                    orderedBlobIDs = newOrder
                    triggerGlow(for: blobID)
                }
        )
    }

    private var ghostRow: some View {
        RoundedRectangle(cornerRadius: 4)
            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            .foregroundColor(AppColors.shared.contentTertiary.opacity(0.4))
            .frame(height: Self.rowHeight - 4)
            .padding(.vertical, 2)
    }

    @ViewBuilder
    private var dragOverlay: some View {
        if let dragID = draggedBlobID {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.shared.contentTertiary.opacity(0.5))
                Image(systemName: checkedBlobIDs.contains(dragID) ? "checkmark.square.fill" : "square")
                    .font(.system(size: 12))
                    .foregroundColor(
                        checkedBlobIDs.contains(dragID)
                            ? AppColors.shared.accent
                            : AppColors.shared.contentTertiary
                    )
                Text(blobTitles[dragID] ?? "Untitled")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.shared.contentPrimary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.vertical, 4)
            .frame(width: 270, height: Self.rowHeight)
            .background(AppColors.shared.sidebarBackground)
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            .opacity(0.85)
            .position(x: 110, y: dragLocation.y)
            .allowsHitTesting(false)
        }
    }

    // MARK: Settings section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(AppColors.shared.contentTertiary.opacity(0.2))
                .frame(height: 1)
                .padding(.top, 8)
                .padding(.bottom, 8)
            
            Text("2. Review Options")
                .font(.system(size: 12))
                .tracking(0.5)
                .foregroundColor(AppColors.shared.contentSecondary)
                .padding(.bottom, 4)
            
            Spacer()

            // Mode toggle
            HStack {
                Text("Add new top-level heading")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.shared.contentPrimary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { mergeMode == .newHeading },
                    set: { mergeMode = $0 ? .newHeading : .simple }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
            }
            .padding(.bottom, 8)
 
            // Delete after merge
            HStack {
                Text("Delete blobs after merge")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.shared.contentPrimary)
                Spacer()
                Toggle("", isOn: $deleteAfterMerge)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
            }
        }
    }

    // MARK: Drag helpers

    // ghostDragIndex is the target position in the "without-dragged" subsequence.
    private func computeGhostIndex(cursor: CGPoint) -> Int {
        let sorted = orderedBlobIDs
            .filter { $0 != draggedBlobID }
            .compactMap { id -> (UUID, CGRect)? in
                guard let frame = blobFrames[id] else { return nil }
                return (id, frame)
            }
            .sorted { $0.1.minY < $1.1.minY }

        for (i, (_, frame)) in sorted.enumerated() {
            if cursor.y < frame.midY { return i }
        }
        return sorted.count
    }

    private func clearDragState() {
        draggedBlobID = nil
        dragLocation = .zero
        ghostDragIndex = nil
    }

    private func triggerGlow(for id: UUID) {
        confirmGlowID = id
        confirmGlowOpacity = 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.4)) { confirmGlowOpacity = 0.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { confirmGlowID = nil }
        }
    }

    // MARK: Actions

    private func performMerge() {
        guard let projectID = selectedProjectID else { return }
        let selected = orderedBlobIDs.filter { checkedBlobIDs.contains($0) }
        guard !selected.isEmpty else { return }

        let newBlobID = store.mergeBlobs(
            orderedBlobIDs: selected,
            in: projectID,
            folderID: selectedFolderID,
            mode: mergeMode,
            newHeading: mergeMode == .newHeading ? newHeadingText : nil,
            deleteAfterMerge: deleteAfterMerge
        )

        if let id = newBlobID {
            loadBlobs()
            activeBlobID = id
        }
    }

    private func toggleSelectAll() {
        if allSelected {
            checkedBlobIDs.removeAll()
        } else {
            checkedBlobIDs = Set(orderedBlobIDs)
        }
    }

    private func toggleCheck(_ blobID: UUID) {
        if checkedBlobIDs.contains(blobID) {
            checkedBlobIDs.remove(blobID)
        } else {
            checkedBlobIDs.insert(blobID)
        }
    }

    // Incremental sync triggered by external store changes (e.g. dashboard creates/deletes).
    // Preserves the user's drag-imposed order: removes IDs that are gone, appends new ones.
    private func syncBlobs() {
        guard let projectID = selectedProjectID,
              let project = store.projects.first(where: { $0.id == projectID }) else {
            orderedBlobIDs = []
            blobTitles = [:]
            checkedBlobIDs = []
            return
        }

        let currentBlobs = project.blobs
            .filter { $0.folderID == selectedFolderID }
        let currentIDs = Set(currentBlobs.map { $0.id })

        // Drop IDs that no longer exist in the store
        orderedBlobIDs.removeAll { !currentIDs.contains($0) }
        checkedBlobIDs = checkedBlobIDs.filter { currentIDs.contains($0) }

        // Append any newly added blobs (in their natural sortOrder) after existing entries
        let existingSet = Set(orderedBlobIDs)
        let newBlobs = currentBlobs
            .filter { !existingSet.contains($0.id) }
            .sorted { $0.sortOrder < $1.sortOrder }
        for blob in newBlobs {
            orderedBlobIDs.append(blob.id)
            checkedBlobIDs.insert(blob.id)
        }

        // Refresh titles for all current blobs, drop stale entries
        for blob in currentBlobs {
            let excerpt = store.loadBlobExcerpt(blobID: blob.id, in: projectID)
            blobTitles[blob.id] = excerpt.title ?? excerpt.body.flatMap { String($0.prefix(40)) } ?? "Untitled"
        }
        blobTitles = blobTitles.filter { currentIDs.contains($0.key) }
    }

    private func loadBlobs() {
        guard let projectID = selectedProjectID,
              let project = store.projects.first(where: { $0.id == projectID }) else {
            orderedBlobIDs = []
            blobTitles = [:]
            checkedBlobIDs = []
            return
        }

        let blobs = project.blobs
            .filter { $0.folderID == selectedFolderID }
            .sorted { $0.sortOrder < $1.sortOrder }

        orderedBlobIDs = blobs.map { $0.id }

        for blob in blobs {
            let excerpt = store.loadBlobExcerpt(blobID: blob.id, in: projectID)
            blobTitles[blob.id] = excerpt.title ?? excerpt.body.flatMap { String($0.prefix(40)) } ?? "Untitled"
        }

        checkedBlobIDs = Set(orderedBlobIDs)
    }
}
