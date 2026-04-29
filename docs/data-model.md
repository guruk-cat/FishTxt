# Data Model & Persistence

## Data Structures (`Sources/Models/`)

- **`Project`** — contains `folders` and `blobs`. Serialized to `~/Documents/FishTxt/<projectID>/project.json`.
- **`BlobFolder`** — id, name, sortOrder. Represents a collection for organizing blobs.
- **`Blob`** — id, optional `folderID`, sortOrder, and timestamps. Content stored separately at `<projectID>/<blobID>.json` as TipTap JSON.
- **`DashboardItem`** — enum wrapping `.folder`, `.blob`, or `.ghost`. Ghost is the drag-reorder placeholder shown during drag operations.
- **`BlobMergeMode`** — enum with cases `.newHeading` (default) and `.simple`. Shared between `BlobMergeView` and `ProjectStore.mergeBlobs`.

Data is stored in `~/Documents/FishTxt/` with one directory per project containing `project.json` (metadata) and individual `<blobID>.json` files for blob content.

The welcome project is copied from `Resources/welcome-project/` on first launch.

## ProjectStore (`Sources/Services/ProjectStore.swift`)

The only persistence layer. Handles all project/folder/blob CRUD operations, including:

- Project lifecycle (create, delete, rename)
- Folder management
- Blob management with move to folder/root
- Sort order rebuilds across folders and root level
- Drag-move logic (`moveItem`, `moveBlobToFolder`, `moveBlobToRoot`)
- Blob merge (`mergeBlobs`) — see below
- TipTap JSON parsing and extraction:
  - `loadBlobExcerpt` — extracts title (first heading) and body with inline formatting for card previews
  - `loadBlobHeadings` — returns all heading nodes in document order as `[BlobHeading]` (level + plain text); used by `BlobOutlineView`
  - `loadBlobPlainText` — plain text extraction with optional word limit
  - `loadBlobHTML` — full HTML generation preserving structure
  - `loadBlobContent` — raw TipTap JSON

## Blob Merge (`mergeBlobs`)

`mergeBlobs(orderedBlobIDs:in:folderID:mode:newHeading:deleteAfterMerge:) -> UUID?`

Merges an ordered, filtered list of blobs into a new blob in the same context (project root or folder). Steps:

1. Load each source blob's TipTap JSON from disk (all reads happen before any mutations)
2. In New heading mode: prepend an H1 node; demote all existing headings in each blob's content by one level via `demoteHeadings(in:)`
3. Concatenate all content node arrays
4. Run `consolidateFootnotes(in:)` to strip mid-document `footnotes` container nodes, renumber all `footnoteReference` / `footnote` pairs sequentially using `data-id` as the stable key, and append a single consolidated `footnotes` container at the end
5. If `deleteAfterMerge`: delete source blob content files synchronously from disk
6. Single `mutateProject` call that atomically removes source blobs from `project.blobs` (if deleting) and inserts the new blob with correct sort order — avoiding the stale-snapshot race that would occur with chained `updateProject` (async) calls
7. Write the new blob's content file via `saveBlobContent` (after the blob is in `project.blobs`, so `updatedAt` is set correctly)

**Why `mutateProject` instead of `createBlob`/`deleteBlob`**: both of those go through `updateProject`, which dispatches to `DispatchQueue.main.async`. Chaining multiple async snapshots means each one captures a stale `projects[index]` and the last write wins — causing either the new blob or the deleted blobs to be lost. `mutateProject` modifies `projects[index]` in place synchronously, so one mutation sees the result of the previous.

## AppColors (`Sources/Services/AppColors.swift`)

Loads color palettes from `Resources/colors.json` and exposes SwiftUI `Color` properties. See `colors.md` for the palette design spec.

Computes `isDark` flag using W3C luminance formula to set appropriate color scheme.

Produces JavaScript snippets for editor theming:

- `editorCSSVariablesJS()` — sets CSS custom properties at document-start (prevents flash)
- `editorCSSInjection()` — full injection with selection override, requires document.head
- `astigDocStartJS()` — sets `window.__ft_astig` and astig CSS variables at document-start; used as a WKUserScript so the mode is active before `onCreate` fires
- `astigLightColors()` — resolves the light counterpart palette (requires `*-dark`/`*-light` naming convention); returns nil if the current palette is light or has no named counterpart

## Resources

- **`Resources/colors.json`** — palette definitions. Nested structure: `{ "paletteName": { "color_key": [R, G, B] } }`. See `colors.md` for the full key reference.
- **`Resources/welcome-project/`** — seed project containing `project.json` and blob content JSONs, copied to user's Documents on first launch.
