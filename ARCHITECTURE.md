# FishTxt Architecture

FishTxt is a SwiftUI macOS app for writing text "blobs" organized into folders within projects, with a WebKit-hosted TipTap editor for rich text.

## Entry & Shell

- **`Sources/App/FishTxtApp.swift`** — `@main` entry point. Installs `ProjectStore` and `AppColors` as environment objects, wires a `⌘S` `saveDocument` notification, and flushes a save on app quit via `AppDelegate`.
- **`Sources/Views/ContentView.swift`** — root layout. `SidebarView` on the left; on the right either `DashboardView` (when no blob is active) or `EditView` (when `activeBlobID != nil`). State lives here: `selectedProjectID`, `selectedFolderID`, `activeBlobID`, `isSidebarOpen`, `isViewingHidden`.

## Data Model (`Sources/Models/`)

- **`Project`** — contains `folders`, `hiddenFolders`, `blobs`, and `isArchived` flag. Serialized to `~/Documents/FishTxt/<projectID>/project.json`.
- **`BlobFolder`** — id, name, sortOrder. Represents a collection for organizing blobs.
- **`Blob`** — id, optional `folderID`, sortOrder, `isHidden`, and timestamps. Content stored separately at `<projectID>/<blobID>.json` as TipTap JSON.
- **`DashboardItem`** — enum wrapping `.folder`, `.blob`, or `.ghost`. Ghost is the drag-reorder placeholder shown during drag operations.

## Services

### ProjectStore (`Sources/Services/ProjectStore.swift`)

The only persistence layer. Handles all project/folder/blob CRUD operations, including:

- Project lifecycle (create, delete, rename, archive/restore)
- Folder management with hide/unhide support
- Blob management with individual hide/unhide, move to folder/root
- Sort order rebuilds across folders and root level
- Drag-move logic (`moveItem`, `moveBlobToFolder`, `moveBlobToRoot`)
- TipTap JSON parsing and extraction:
  - `loadBlobExcerpt` — extracts title (first heading) and body with inline formatting for card previews
  - `loadBlobPlainText` — plain text extraction with optional word limit
  - `loadBlobHTML` — full HTML generation preserving structure
  - `loadBlobContent` — raw TipTap JSON

Data is stored in `~/Documents/FishTxt/` with one directory per project containing `project.json` (metadata) and individual `<blobID>.json` files for blob content.

Welcome project is copied from `Resources/welcome-project/` on first launch.

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

48pt button column + optional 220pt file navigator for dual-level navigation.

### SidebarButtonColumn

- Toggle sidebar visibility
- New folder button (with glow confirmation)
- New blob button (with glow confirmation)
- Disabled git button (placeholder for future feature)
- Settings button (opens SettingsView sheet)

### FileNavigatorView

Two-level navigation with full drag-reorder support:

#### Level 1: Project Picker

- Lists live and archived projects
- Create new project via plus button
- Tap to enter Level 2

#### Level 2: Project Contents

- Header with project name and back button
- Expandable folders with nested blobs
- Root-level blobs
- Full drag-reorder: folders independently sort, blobs within folders independently sort, root blobs sort independently
- **Key invariant**: dragged items are held at height 0 / opacity 0 rather than removed from the view, preventing gesture cancellation

Supports context menus for:

- Rename folder/project
- Hide/unhide folders and blobs
- Delete folders and blobs
- Move blobs to root
- Archive/restore projects

## Dashboard (`Sources/Views/Dashboard/`)

### DashboardView

`LazyVGrid` layout displaying folders (80pt cards) and blobs (200pt cards) with full drag-and-drop support.

#### Drag state machine

- Ghost placeholders show target position
- `cardFrames` tracked via `CardFrameKey` PreferenceKey for hit detection
- Folder drag detection for moving blobs into folders
- ESC key cancels active drag
- Confirm glow animation on successful drop

#### Read-only mode

When project is archived or viewing hidden items.

#### Context menus for

- Rename/hide/delete folders
- Hide/delete blobs
- Move blobs to root
- Restore hidden items

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
- Copy all (sends content back to Swift)
- Hide blob
- Close editor

Uses `WeakMessageHandler` to prevent retain cycle between `WKUserContentController` and `EditorBridge`.

Updates auto-scroll mode on settings change via coordinator.

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
- `hideBlob` — trigger save and hide

**Swift → JS** (commands):

- Toggle formatting: `toggleBold()`, `toggleItalic()`, `toggleUnderline()`, `toggleBlockquote()`, `toggleBulletList()`, `toggleOrderedList()`
- Heading: `setHeading(level:)`
- Content: `setContent(_:)`, `getContent(completion:)`
- Navigation: `scrollToTop()`, `focus()`
- Theming: `applyColors()`, `setAutoScroll(_:)`

**Clipboard helper**:

- `writeToClipboard(html:plainText:)` — wraps HTML in UTF-8 document wrapper so Pages/Word handle multi-byte characters (curly quotes, em-dashes) correctly

## Settings (`Sources/Views/Settings/`)

### SettingsView

Modal sheet with @AppStorage bindings:

- **Editor**
  - Font family (text field)
  - Font size (−/+ buttons, range 10–36pt)
- **Appearance**
  - Color palette (dropdown, populated from `colors.json` keys)
  - Auto-scroll mode (regular vs centered, segmented control)

Palette change reactively calls `appColors.loadColors(palette:)`, triggering color updates across app and editor.

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
- `isViewingHidden` — viewing hidden items panel vs normal items

The sidebar reflects project selection and folder navigation. The dashboard shows items for the selected context (project root or specific folder). The editor appears when `activeBlobID` is set.

## Where to Look

| Task | File(s) |
| ---- | ------- |
| Persistence, CRUD, sort order, drag logic | `ProjectStore.swift` |
| Color theming (Swift + web) | `AppColors.swift` |
| Dashboard drag & drop | `DashboardView.swift` |
| Sidebar tree drag & drop | `FileNavigatorView.swift` |
| Card rendering & previews | `CardView.swift` |
| Save lifecycle | `EditView.swift` |
| JS ↔ Swift editor messages | `EditorBridge.swift`, `WebEditorView.toolbarInitJS` |
| Editor DOM / TipTap internals | `Resources/editor.html` (grep) |
| Settings & user preferences | `SettingsView.swift` |
