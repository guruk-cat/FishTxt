# Sidebar

## UX Overview

The sidebar has two parts: a narrow button column (always visible) and an expandable panel to its right. The button column holds icons for toggling the three panels, a disabled placeholder for a future git feature, and a settings button. The three panels are mutually exclusive — activating one while another is open switches panels rather than closing the sidebar.

**The three panels:**

- **File Navigator** — two-level tree: project list → project contents (folders + blobs). Full drag-reorder at every level.
- **Blob Outline** — heading structure of the currently open blob. Collapsible subtrees; clicking a heading scrolls the editor to it.
- **Blob Merge** — select and reorder blobs, pick a merge mode, and consolidate them into a single new blob.

## SidebarView & SidebarButtonColumn (`Sources/Views/Sidebar/`)

`SidebarView` is a 48pt button column + optional 220pt panel.

Holds `@State private var activePanel: SidebarPanel` (`.navigator` / `.blobOutline` / `.blobMerge`) to enforce mutual exclusivity. When `isSidebarOpen` is true, the active panel renders at 220pt alongside the button column (268pt total).

`SidebarButtonColumn` buttons:

- Toggle file navigator (sets `activePanel = .navigator`, toggles `isSidebarOpen`)
- Toggle blob outline (sets `activePanel = .blobOutline`, toggles `isSidebarOpen`)
- Toggle blob merge (sets `activePanel = .blobMerge`, toggles `isSidebarOpen`)
- Disabled git button (placeholder)
- Settings button (opens `SettingsView` sheet)

## FileNavigatorView

Two-level navigation with full drag-reorder support.

**(Level 1) Project Picker:**

- Lists all projects
- Create new project via plus button
- Tap to enter Level 2

**(Level 2) Project Contents:**

- Header with project name and back button
- Expandable folders with nested blobs
- Root-level blobs
- Full drag-reorder: folders independently sort, blobs within folders independently sort, root blobs sort independently
- **Key invariant**: dragged items are held at `height: 0 / opacity: 0` rather than removed from the view, preventing gesture cancellation

Context menus support: rename folder/project, delete folders and blobs, move blobs to root.

## BlobOutlineView

Sidebar panel displaying the heading structure of the currently open blob.

**Layout:**

- `OUTLINE` section header
- Empty states: "No blob open." (when `activeBlobID` is nil) or "No headings." (when the blob has no heading nodes)
- Heading list, one row per heading node in document order

**Heading rows:**

- Indented by heading level (12pt per level after H1)
- Collapsible: headings with children show a chevron; clicking toggles collapse/expand for that subtree
- Active heading (currently visible in the editor viewport) is highlighted with a background tint and a 2pt left accent bar
- Clicking a row posts a `scrollToOutlineHeading` notification (carrying the heading's index), which `EditView` receives and forwards to `EditorBridge.scrollToHeading(index:)`

**Active heading tracking:**

The JS side of the editor detects which heading is in the viewport and sends a `headingVisible` message to Swift carrying the heading index. `EditorBridge` re-posts this as an `activeHeadingChanged` notification, which `BlobOutlineView` receives to update `activeHeadingIndex`.

**Data:** Reloads via `store.loadBlobHeadings(blobID:in:)` whenever `activeBlobID` or `selectedProjectID` changes.

## BlobMergeView

Expandable sidebar panel for consolidating multiple blobs into one.

**Layout (top to bottom):**

- `MERGE BLOBS` section header
- Select All / Deselect All toggle button
- Draggable, checkable blob list
- Mode picker (segmented control): **New heading** (default) / **Simple merge**
- New H1 heading text field (disabled in Simple merge mode)
- Delete blobs after merge checkbox
- Merge button

**Blob list behavior:**

- Populated from the current context (`selectedProjectID` + `selectedFolderID`) on appear and on context switch (`loadBlobs()` — full reset)
- Incrementally synced on external store changes via `onChange(of: store.projects)` → `syncBlobs()`, which preserves the user's drag-imposed order while adding/removing blobs to match the store
- Drag-to-reorder uses the standard ghost-placeholder pattern: dragged item kept at `height: 0 / opacity: 0` in the `ForEach`, ghost inserted at computed drop target; reorder committed in `.onEnded` with `defer { clearDragState() }`
- Frame tracking via `MergeListFrameKey` PreferenceKey in a `"mergeList"` named coordinate space anchored to the outer `ZStack` (outside the `ScrollView`)

**Merge modes:**

- **New heading**: prepends a new H1 node, then demotes all existing headings in source blobs by one level (H1→H2, H2→H3, capped at H3) before concatenating
- **Simple merge**: concatenates source blob content arrays as-is

For the merge logic itself (what happens in `ProjectStore` when the button is pressed), see `data-model.md`.

**After merge:** the new blob opens immediately in the editor (`activeBlobID` is set to the new blob's ID).
