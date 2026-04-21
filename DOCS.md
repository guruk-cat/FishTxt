# FishTxt - Comprehensive Documentation

> A rich text editor for rapid brainstorming and managing long drafts.

## Overview

### Purpose

FishTxt is a hybrid between a notetaking app and a conventional word document. It is a light-weight rich text editor that supports two distinct kinds of work in a single environment:

1. Rapid brainstorming, piece-wise drafting, and jumping between ideas
2. Careful organization of drafts, and longer sessions of focused writing.

When writing a long article that covers many sources and topics, it is hard to keep everything coherent in a single word document right from the start. Conversely, it is hard to develop a holistic vision only through a form of notetaking, whether it be in a physical notebook, a dedicated notes app, or — the worst but perhaps the simplest — another word document where you just throw everything in. Thus, most people require some combination of the two kinds of tools.

FishTxt was designed to be exactly that kind of combination: a set of tools that you can use from the very beginning of a project all the way to the first or second draft. Of course, you'll likely need at some point an actual, robust document editor like Microsoft Word or Apple Pages. While FishTxt can export to a printer or PDF, this is done through built-in CSS profiles, which is quite different from document editors if that's what you're used to. But remember, FishTxt was designed specifically for the development phase, for longer projects, for the part of your work where it's still unclear what the finished product should really look like. In that regard, FishTxt is not intended to replace your document editor; but it does make you rethink what each tool is best used for.

### Authors

FishTxt was designed by me, and the codebase was built largely by Claude Sonnet.

### Current Version

This version is the Beta version (build 2), currently being tested in real use (by me).

### Repository Map

- `FishTxt/`: source codes, application assets, etc.
  - `Assets.xcassets`
  - `FishTxt.icon`
  - `Resources/`
  - `Sources/`: most of the `.swift` files live here.
  - `FishTxt.entitlements`
  - `info.plist`
- `FishTxt.xcodeproj`: Xcode project file
- `mist_resources`: miscellaneous tools and files for development
  - `FishTxt.icon`: the original icon file is left as a duplicate, so that it can be edited without affecting the app build in Xcode
  - `imgs/`: screenshots for the `READ_ME.md`
  - `welcome-project`: project files for the example project that is saved to `~/Documents/FishTxt` on the app's first launch
  - `color_preview.html`: an html template that simulates different UI elements of FishTxt, with different color themes loaded from `FishTxt/Resources/colors.json`
  - `color_preview.py`: a pythons script that opens a local host for `colors_preview.html` and ensures that any edits to `colors.json` are freshly loaded at `Cmd+R`
  - `DRAG_FEATURE_HELP.md`: There was a reoccuring bug with the drag-and-drop features, so this file exists for reference when trying to fix similar issues.
- `packaging/`: app distribution formats
  - `FishTxt.dmg`
  - `FishTxt.zip`

## Entry & Shell

- **`Sources/App/FishTxtApp.swift`** — `@main` entry point. Installs `ProjectStore` and `AppColors` as environment objects, wires a `⌘S` `saveDocument` notification, and flushes a save on app quit via `AppDelegate`.
- **`Sources/Views/ContentView.swift`** — root layout. `SidebarView` on the left; on the right either `DashboardView` (when no blob is active) or `EditView` (when `activeBlobID != nil`). State lives here: `selectedProjectID`, `selectedFolderID`, `activeBlobID`, `isSidebarOpen`.

## Data Model (`Sources/Models/`)

- **`Project`** — contains `folders` and `blobs`. Serialized to `~/Documents/FishTxt/<projectID>/project.json`.
- **`BlobFolder`** — id, name, sortOrder. Represents a collection for organizing blobs.
- **`Blob`** — id, optional `folderID`, sortOrder, and timestamps. Content stored separately at `<projectID>/<blobID>.json` as TipTap JSON.
- **`DashboardItem`** — enum wrapping `.folder`, `.blob`, or `.ghost`. Ghost is the drag-reorder placeholder shown during drag operations.
- **`BlobMergeMode`** — enum with cases `.newHeading` (default) and `.simple`. Shared between `BlobMergeView` and `ProjectStore.mergeBlobs`.

## Services

### ProjectStore (`Sources/Services/ProjectStore.swift`)

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

Data is stored in `~/Documents/FishTxt/` with one directory per project containing `project.json` (metadata) and individual `<blobID>.json` files for blob content.

Welcome project is copied from `Resources/welcome-project/` on first launch.

### Blob Merge (`mergeBlobs`)

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

### Printing

Blobs can be printed to PDF or physical printer via `printBlob(blobID:in:)`. The print flow:

1. Generate HTML from blob's TipTap JSON using `loadBlobHTML()` (preserves headings, lists, bold/italic/underline, blockquotes, and footnotes with two-way linking which can be leveraged *if needed*)
2. Load the active print profile CSS from `Resources/print-profiles/` subdirectory
3. Wrap HTML fragment in a minimal `<html>` document with the profile CSS injected
4. Create a temporary off-screen `WKWebView`, load the document, and invoke `printOperation(with:)` on macOS 13+
5. Show the system print sheet (which includes "Save as PDF")

**Image support**: `image` nodes → `<figure><img src="..." alt="..."></figure>`. The `src` is a base64 data URL stored directly in the blob JSON. Print output respects the `imageLimitHalfWidth` setting by injecting `--ft-print-img-max-width: 50%|100%` as a CSS variable before the profile CSS, which print profiles consume via `max-width: var(--ft-print-img-max-width, 100%)` on `figure`.

**Footnote support**: The HTML renderer handles:

- `footnoteReference` nodes → `<sup><a href="#fn:1" id="ref:1">[1]</a></sup>` (clickable links both ways)
- `footnotes` / `footnote` nodes → `<ol class="footnotes"><li id="fn:1">...content... <a href="#ref:1">↑</a></li></ol>` (with backlinks)

Print-specific CSS can style footnotes appropriately (e.g., smaller font, page break handling).

### Print Profiles

Print profiles are self-contained CSS files stored in `Resources/print-profiles/`. Each profile:

- Is named `<profileName>.css` (e.g., `palatino_basic.css`, `monospace.css`)
- Owns all styling: fonts, sizes, margins, headings, lists, blockquotes, footnotes, figures, etc.
- Is injected into the `<style>` block of the print document, preceded by a `:root { --ft-print-img-max-width: ... }` declaration injected by `printBlob` based on the `imageLimitHalfWidth` setting
- Profiles consume `--ft-print-img-max-width` via `figure { max-width: var(--ft-print-img-max-width, 100%); }`

Selection is persisted via `@AppStorage("printProfile")` (defaults to first available profile if not set). Users select a profile in Settings (see **Settings** section below).

New profiles can be added by:

1. Creating a `.css` file in `FishTxt/Resources/print-profiles/`
2. Adding it to the Xcode target's "Copy Bundle Resources" build phase (already configured)
3. Restarting the app; the profile will appear in Settings automatically

### AppColors (`Sources/Services/AppColors.swift`)

Loads color palettes from `Resources/colors.json` and exposes SwiftUI `Color` properties:

- Background colors (primary, secondary, highlight)
- Content colors (primary, secondary, tertiary)
- Accent, confirmation, sidebar background, card border, destructive

Computes `isDark` flag using W3C luminance formula to set appropriate color scheme.

Produces JavaScript snippets for editor theming:

- `editorCSSVariablesJS()` — sets CSS custom properties at document-start (prevents flash)
- `editorCSSInjection()` — full injection with selection override, requires document.head

## Sidebar (`Sources/Views/Sidebar/`)

### SidebarView

48pt button column + optional 220pt panel for dual-level navigation or blob merging.

Holds `@State private var activePanel: SidebarPanel` (`.navigator` / `.blobMerge`) to enforce mutual exclusivity between the two expandable panels. When `isSidebarOpen` is true, the active panel is rendered at 220pt width alongside the 48pt button column (268pt total).

### SidebarButtonColumn

- Toggle file navigator (sets `activePanel = .navigator`, toggles `isSidebarOpen`)
- Toggle blob outline panel (sets `activePanel = .blobOutline`, toggles `isSidebarOpen`)
- Toggle blob merge panel (sets `activePanel = .blobMerge`, toggles `isSidebarOpen`)
- Disabled git button (placeholder for future feature)
- Settings button (opens SettingsView sheet)

The three panel-toggle buttons are mutually exclusive: activating one while another is open switches the panel rather than closing it.

### FileNavigatorView

Two-level navigation with full drag-reorder support:

**(Level 1) Project Picker:**

- Lists all projects
- Create new project via plus button
- Tap to enter Level 2

**(Level 2) Project Contents:**

- Header with project name and back button
- Expandable folders with nested blobs
- Root-level blobs
- Full drag-reorder: folders independently sort, blobs within folders independently sort, root blobs sort independently
- **Key invariant**: dragged items are held at height 0 / opacity 0 rather than removed from the view, preventing gesture cancellation

Supports context menus for:

- Rename folder/project
- Delete folders and blobs
- Move blobs to root

### BlobOutlineView

Sidebar panel displaying the heading structure of the currently open blob. Occupies the same 270pt width as the other panels.

**Layout:**

- `OUTLINE` section header
- Empty states: "No blob open." (when `activeBlobID` is nil) or "No headings." (when the blob has no heading nodes)
- Heading list, one row per heading node in document order

**Heading rows:**

- Indented by heading level (12pt per level after H1)
- Collapsible: headings with children show a chevron; clicking the chevron toggles collapse/expand for that subtree
- Active heading (the heading currently visible in the editor viewport) is highlighted with a background tint and a 2pt left accent bar
- Clicking a row posts a `scrollToOutlineHeading` notification (carrying the heading's index) which `EditView` receives and forwards to `EditorBridge.scrollToHeading(index:)`

**Active heading tracking:**

The JS side of the editor detects which heading is in the viewport and sends a `headingVisible` message to Swift carrying the heading index. `EditorBridge` re-posts this as an `activeHeadingChanged` notification, which `BlobOutlineView` receives to update `activeHeadingIndex`.

**Data:** Reloads via `store.loadBlobHeadings(blobID:in:)` whenever `activeBlobID` or `selectedProjectID` changes.

### BlobMergeView

Expandable sidebar panel for consolidating multiple blobs into one. Occupies the same 220pt width as `FileNavigatorView` and follows the same typography and spacing conventions.

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

**After merge:** the new blob opens immediately in the editor (`activeBlobID` is set to the new blob's ID).

## Dashboard (`Sources/Views/Dashboard/`)

### DashboardView

`LazyVGrid` layout displaying folders (80pt cards) and blobs (200pt cards) with full drag-and-drop support.

#### Drag state machine

- Ghost placeholders show target position
- `cardFrames` tracked via `CardFrameKey` PreferenceKey for hit detection
- Folder drag detection for moving blobs into folders
- ESC key cancels active drag
- Confirm glow animation on successful drop

#### Floating island of buttons

- New folder button
- New blob button

#### Context menus for

- Rename/delete folders
- Copy/print/delete blobs
- Move blobs to root

### CardView

Renders three types of cards:

**Folder cards** (80pt)

- Icon + name
- Click to navigate into folder
- Drop target for blob drags

**Blob cards** (200pt)

- Title (first heading from TipTap JSON)
- Body preview with inline formatting preserved (bold/italic/underline)
- Empty state indicator
- Hover-revealed copy button (copies both HTML and plain text)
- Async loads `BlobExcerpt` on mount

**Ghost cards** (placeholder)

- Dashed border indicating drop position

## Editor (`Sources/Views/Editor/`)

### EditView

Hosts the WebKit editor and manages save lifecycle:

- Listens for `.saveDocument` notification (⌘S or app quit)
- Autosaves 5 seconds after first dirty event
- Saves before closing/hiding
- Shows "Saving..." / "Saved!" island
- Reapplies colors on palette change
- ESC key triggers save and close
- Injects ESC monitor on appear, cleans up on disappear

### WebEditorView

`NSViewRepresentable` wrapping `WKWebView` that loads `Resources/editor.html`.

**Injection timing**:

- **Document-start**: Color CSS variables (prevents color flash)
- **Document-end**: Toolbar wiring JavaScript (after all TipTap modules loaded)

**Toolbar init** wires up click handlers for:

- Bold/italic/underline/blockquote toggles
- Heading level dropdown (H1/H2/H3)
- Bullet/ordered list dropdown
- Image insertion (posts `insertImage` to Swift)
- Copy all (sends content back to Swift)
- Close editor

Uses `WeakMessageHandler` to prevent retain cycle between `WKUserContentController` and `EditorBridge`.

Updates auto-scroll mode, font, and image half-width on settings change via coordinator.

### EditorBridge

`ObservableObject` + `WKScriptMessageHandler` bridging JavaScript ↔ Swift.

**Published state**:

- `isReady` — editor has loaded
- `isDirty` — content changed since last save
- `editorState` — current formatting state (bold, italic, underline, heading level, list types, blockquote)

**JS → Swift** (messages):

- `editorReady` — editor initialized
- `documentChanged` — mark as dirty
- `stateUpdate` — reflect formatting state
- `copyAll` — copy HTML + plain text to clipboard
- `closeEditor` — trigger save and close
- `insertImage` — toolbar "Image" button tapped; Swift opens `NSOpenPanel`, reads the file, base64-encodes it, and calls back via `insertImage(src:)`

**Swift → JS** (commands):

- Toggle formatting: `toggleBold()`, `toggleItalic()`, `toggleUnderline()`, `toggleBlockquote()`, `toggleBulletList()`, `toggleOrderedList()`
- Heading: `setHeading(level:)`
- Content: `setContent(_:)`, `getContent(completion:)`
- Navigation: `scrollToTop()`, `focus()`
- Theming: `applyColors()`, `setAutoScroll(_:)`
- Image: `insertImage(src:)` — inserts a `figure > img` block at the cursor using `callAsyncJavaScript` (handles large base64 payloads safely); `setImageHalfWidth(_:)` — injects `--ft-img-max-width: 50%|100%` CSS variable

**Clipboard helper**:

- `writeToClipboard(html:plainText:)` — wraps HTML in UTF-8 document wrapper so Pages/Word handle multi-byte characters (curly quotes, em-dashes) correctly

**Notification names** (defined as `Notification.Name` extensions in `EditorBridge.swift`):

- `scrollToOutlineHeading` — posted by `BlobOutlineView` (object: `Int` heading index); received by `EditView` to call `bridge.scrollToHeading(index:)`
- `activeHeadingChanged` — posted by `EditorBridge` when the JS side reports a `headingVisible` message (object: `Int` heading index); received by `BlobOutlineView` to highlight the active row

## Settings (`Sources/Views/Settings/`)

### SettingsView

Modal sheet with @AppStorage bindings:

- **Editor**
  - Font family (text field)
  - Font size (−/+ buttons, range 10–36pt)
  - Auto-scroll mode (dropdown: Off / On)
  - Limit image width to half (switch toggle — `imageLimitHalfWidth`; when ON, `--ft-img-max-width` is set to `50%` in the editor and `--ft-print-img-max-width` to `50%` in print output)
- **Appearance**
  - Color palette (dropdown, populated from `colors.json` keys)
  - Print profile (dropdown, auto-populated from `.css` files in `Resources/print-profiles/`)

Palette change reactively calls `appColors.loadColors(palette:)`, triggering color updates across app and editor.

Print profile selection is persisted and used whenever the user prints a blob from the dashboard, sidebar, or editor (⌘P in editor).

## Resources

- **`Resources/editor.html`** — large minified TipTap editor page. Grep for specific patterns rather than reading in full.
- **`Resources/colors.json`** — palette definitions. Nested structure: `{ "paletteName": { "color_key": [R, G, B] } }`. Keys: `background_primary`, `background_secondary`, `background_highlight`, `content_primary`, `content_secondary`, `content_tertiary`, `accent`, `confirmation`, `sidebar_background`, `card_border`, `destructive`.
- **`Resources/welcome-project/`** — seed project containing `project.json` and blob content JSONs, copied to user's Documents on first launch.

## Navigation State

Root state lives in `ContentView`:

- `selectedProjectID` — which project is active
- `selectedFolderID` — which folder (if any) is being viewed in dashboard
- `activeBlobID` — which blob (if any) is open in editor
- `isSidebarOpen` — sidebar visibility

The sidebar reflects project selection and folder navigation. The dashboard shows items for the selected context (project root or specific folder). The editor appears when `activeBlobID` is set.

## Where to Look

| Task | File(s) |
| ---- | ------- |
| Persistence, CRUD, sort order, drag logic | `ProjectStore.swift` |
| Blob merge logic, footnote consolidation | `ProjectStore.mergeBlobs()`, `ProjectStore.consolidateFootnotes()` |
| Merge panel UI & drag reorder | `BlobMergeView.swift` |
| Blob outline panel UI & collapse logic | `BlobOutlineView.swift` |
| Blob outline heading extraction | `ProjectStore.loadBlobHeadings()`, `ProjectStore.BlobHeading` |
| Outline ↔ editor scroll sync | `EditorBridge.swift` (`scrollToOutlineHeading`, `activeHeadingChanged` notifications) |
| Sidebar panel switching (navigator / outline / merge) | `SidebarView.swift`, `SidebarButtonColumn.swift` |
| Printing & print profiles | `ProjectStore.printBlob()`, `BlobPrinter`, `Resources/print-profiles/*.css` |
| Footnote HTML rendering | `ProjectStore.renderNodeHTML()` (cases: `footnoteReference`, `footnotes`, `footnote`) |
| Color theming (Swift + web) | `AppColors.swift` |
| Dashboard drag & drop | `DashboardView.swift` |
| Sidebar tree drag & drop | `FileNavigatorView.swift` |
| Card rendering & previews | `CardView.swift` |
| Save lifecycle | `EditView.swift` |
| JS ↔ Swift editor messages | `EditorBridge.swift`, `WebEditorView.toolbarInitJS` |
| Editor DOM / TipTap internals | `Resources/editor.html` (grep; file is large and minified) |
| Settings & user preferences | `SettingsView.swift` (includes print profile picker) |
