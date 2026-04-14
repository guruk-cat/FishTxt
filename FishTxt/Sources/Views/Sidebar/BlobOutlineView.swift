import SwiftUI

struct BlobOutlineView: View {

    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var appColors: AppColors
    @Binding var selectedProjectID: UUID?
    @Binding var activeBlobID: UUID?

    @State private var headings: [ProjectStore.BlobHeading] = []
    @State private var collapsedIndices: Set<Int> = []
    @State private var hoveredIndex: Int? = nil
    @State private var activeHeadingIndex: Int = -1

    static let rowHeight: CGFloat = 26
    private static let baseIndent: CGFloat = 8
    private static let levelIndent: CGFloat = 12

    // MARK: - Helpers

    // True when the heading at `index` has at least one subsequent heading with
    // a strictly greater level before any sibling/ancestor heading interrupts.
    private func hasChildren(at index: Int) -> Bool {
        let level = headings[index].level
        for i in (index + 1)..<headings.count {
            if headings[i].level <= level { return false }
            return true
        }
        return false
    }

    // MARK: - Visible headings

    // Returns (originalIndex, heading) pairs, skipping any heading that is a
    // descendant of a collapsed ancestor. A heading at index j is a descendant
    // of a collapsed heading at index i when:
    //   • heading[j].level > heading[i].level, AND
    //   • every heading between i and j also has level > heading[i].level
    //     (i.e. no sibling/ancestor broke the chain)
    // The stack tracks the blocking level of each active collapsed ancestor.
    private var visibleHeadings: [(index: Int, heading: ProjectStore.BlobHeading)] {
        var result: [(index: Int, heading: ProjectStore.BlobHeading)] = []
        var collapsedStack: [Int] = []   // levels currently blocking visibility

        for (index, heading) in headings.enumerated() {
            // A heading at this level ends any collapse blocks at the same or
            // deeper level — it is a sibling or ancestor, not a child.
            collapsedStack.removeAll { $0 >= heading.level }

            guard collapsedStack.isEmpty else { continue }   // hidden

            result.append((index: index, heading: heading))

            if collapsedIndices.contains(index) {
                collapsedStack.append(heading.level)
            }
        }
        return result
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                contentRows
            }
        }
        .onAppear { reload() }
        .onChange(of: activeBlobID) { _ in reload() }
        .onChange(of: selectedProjectID) { _ in reload() }
        .onReceive(NotificationCenter.default.publisher(for: .activeHeadingChanged)) { notif in
            activeHeadingIndex = notif.object as? Int ?? -1
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("OUTLINE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(AppColors.shared.contentSecondary)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentRows: some View {
        if activeBlobID == nil {
            emptyLabel("No file open.")
        } else if headings.isEmpty {
            emptyLabel("No headings.")
        } else {
            ForEach(visibleHeadings, id: \.index) { entry in
                headingRow(entry.heading, index: entry.index)
            }
        }
    }

    private func headingRow(_ heading: ProjectStore.BlobHeading, index: Int) -> some View {
        let indent = Self.baseIndent + CGFloat(heading.level - 1) * Self.levelIndent
        let isHovered = hoveredIndex == index
        let expandable = hasChildren(at: index)
        let isCollapsed = collapsedIndices.contains(index)
        let isActive = activeHeadingIndex == index
        return HStack(spacing: 0) {
            Text(heading.text)
                .font(.system(size: 12))
                .foregroundColor(
                    isActive ? AppColors.shared.contentSecondary :
                    isHovered
                        ? AppColors.shared.contentPrimary
                        : AppColors.shared.contentTertiary
                )
                .lineLimit(1)
                .animation(.easeInOut(duration: 0.12), value: isHovered)
            Spacer()
        }
        // Reserve 14px for the chevron overlay, then indent per heading level
        .padding(.leading, indent + 14)
        .padding(.trailing, 8)
        .overlay(alignment: .leading) {
            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(!expandable ? Color.clear : isHovered ? AppColors.shared.contentPrimary : AppColors.shared.contentTertiary)
                .animation(.easeInOut(duration: 0.12), value: isHovered)
                .frame(width: 14)
                .padding(.leading, indent)
                .onTapGesture{ if expandable { toggleCollapse(at: index) } }
        }
        .frame(height: Self.rowHeight)
        .background(isActive ? AppColors.shared.backgroundHighlight.opacity(0.2) : Color.clear)
        .overlay(isActive ? Rectangle().frame(width: 2).foregroundColor(AppColors.shared.contentSecondary) : nil, alignment: .leading)
        .contentShape(Rectangle())
        .onHover { hoveredIndex = $0 ? index : nil }
        .onTapGesture { NotificationCenter.default.post(name: .scrollToOutlineHeading, object: index) }
    }

    private func emptyLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(AppColors.shared.contentTertiary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Collapse

    private func toggleCollapse(at index: Int) {
        if collapsedIndices.contains(index) {
            collapsedIndices.remove(index)
        } else {
            collapsedIndices.insert(index)
        }
    }

    // MARK: - Data

    private func reload() {
        guard let blobID = activeBlobID,
              let projectID = selectedProjectID else {
            headings = []
            collapsedIndices = []
            activeHeadingIndex = -1
            return
        }
        headings = store.loadBlobHeadings(blobID: blobID, in: projectID)
        collapsedIndices = []
        activeHeadingIndex = -1
    }
}
