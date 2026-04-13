import SwiftUI

enum BlobMergeMode {
    case newHeading
    case simple
}

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

    // Hover states
    @State private var hoverSelectAll: Bool = false
    @State private var hoverMerge: Bool = false

    private static let rowHeight: CGFloat = 26

    private var allSelected: Bool {
        !orderedBlobIDs.isEmpty && orderedBlobIDs.allSatisfy { checkedBlobIDs.contains($0) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerRow
                blobList
                settingsSection
            }
            .padding(.trailing, 4)
        }
        .onAppear { loadBlobs() }
        .onChange(of: selectedProjectID) { _ in loadBlobs() }
        .onChange(of: selectedFolderID) { _ in loadBlobs() }
    }

    // MARK: - Header

    private var headerRow: some View {
        VStack(spacing: 0) {
            HStack {
                Text("MERGE BLOBS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(AppColors.shared.contentSecondary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 12)
            .padding(.bottom, 6)

            HStack {
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
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
        }
    }

    // MARK: - Blob list

    @ViewBuilder
    private var blobList: some View {
        if orderedBlobIDs.isEmpty {
            Text("No blobs in this context.")
                .font(.system(size: 12))
                .foregroundColor(AppColors.shared.contentTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            ForEach(orderedBlobIDs, id: \.self) { blobID in
                blobRow(blobID)
            }
        }
    }

    private func blobRow(_ blobID: UUID) -> some View {
        let isChecked = checkedBlobIDs.contains(blobID)
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
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { toggleCheck(blobID) }
    }

    // MARK: - Settings section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(AppColors.shared.contentTertiary.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 8)

            // Mode picker
            Picker("", selection: $mergeMode) {
                Text("New heading").tag(BlobMergeMode.newHeading)
                Text("Simple merge").tag(BlobMergeMode.simple)
            }
            .pickerStyle(.segmented)
            .padding(.trailing, 8)

            // New H1 heading text field
            TextField("New H1 heading…", text: $newHeadingText)
                .font(.system(size: 12))
                .textFieldStyle(.plain)
                .foregroundColor(
                    mergeMode == .newHeading
                        ? AppColors.shared.contentPrimary
                        : AppColors.shared.contentTertiary
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.shared.backgroundSecondary.opacity(
                            mergeMode == .newHeading ? 0.6 : 0.3
                        ))
                )
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .disabled(mergeMode == .simple)

            // Delete after merge
            Toggle(isOn: $deleteAfterMerge) {
                Text("Delete blobs after merge")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.shared.contentPrimary)
            }
            .toggleStyle(.checkbox)
            .padding(.horizontal, 8)
            .padding(.top, 10)

            // Merge button
            Button(action: {}) {
                Text("Merge")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(
                        hoverMerge
                            ? AppColors.shared.contentSecondary
                            : AppColors.shared.contentPrimary
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(AppColors.shared.backgroundHighlight.opacity(
                                hoverMerge ? 0.35 : 0.2
                            ))
                    )
                    .animation(.easeInOut(duration: 0.12), value: hoverMerge)
            }
            .buttonStyle(.plain)
            .onHover { hoverMerge = $0 }
            .padding(.horizontal, 8)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .padding(.trailing, 8)
    }

    // MARK: - Actions

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

    private func loadBlobs() {
        guard let projectID = selectedProjectID,
              let project = store.projects.first(where: { $0.id == projectID }) else {
            orderedBlobIDs = []
            blobTitles = [:]
            checkedBlobIDs = []
            return
        }

        let blobs = project.blobs
            .filter { !$0.isHidden && $0.folderID == selectedFolderID }
            .sorted { $0.sortOrder < $1.sortOrder }

        orderedBlobIDs = blobs.map { $0.id }

        for blob in blobs {
            let excerpt = store.loadBlobExcerpt(blobID: blob.id, in: projectID)
            blobTitles[blob.id] = excerpt.title ?? "Untitled"
        }

        checkedBlobIDs = Set(orderedBlobIDs)
    }
}
