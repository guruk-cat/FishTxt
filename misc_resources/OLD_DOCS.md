# FishTxt — Development Documentation

> A rich text editor for writers and researchers. Runs on macOS.

## Table of Contents

## 1. Overview

FishTxt is a hybrid between a notes app and a document editing app. It is essentially a light-weight rich text editor that focuses on rapid writing and development of ideas during the drafting phase of a major writing or and/or research project. FishTxt is intended to help with those who have fragmentary drafting styles or needs. When a writer has to juggle between several different topics, sections, chapters, etc., it is hard to keep everything drafted within a single, conventional word document; this is what FishTxt is for.

The basic unit of content is a **blob**. A blob is a piece of text — a paragraph, a passage, or even a short chapter — that may eventually end up in a larger piece of writing.

FishTxt's file organization has a three-level hierarchy, which goes: **Projects → Folders → Blobs**. Projects are top-level containers (one per writing endeavour). Folders are named categories within a project. A blob can be either stored in a folder, or in the project without belonging to a folder (at the project root). Thus, a project may contain many blobs, as well as folders which have inside them more blobs.

Blobs and folders can be "hidden." This results in those blobs and folders not appearing for the user. However, the user can choose, through a file navigator, to "see hidden content" for each project. This results in a read-only view of hidden blobs and folders for that project. A project can be "archived." This results in all folders and blobs (regardless of if they were previously "hidden") appearing together in read-only mode.

## 2. Major Features (UI/UX)

### 2.1 Dashboard

Contents of a project or of a folder within a project is primarily viewed on a dashboard. A dashboard renders a vertically scrolling 2D grid of cards. Cards wrap left-to-right in reading order. Cards are arranged automatically according to window width.

A card contains either the name of a folder, or a ~30 words excerpt of a blob. Clicking on a folder card results in another dashboard showing blobs belonging to a folder. Clicking on a blob card opens a text editor for viewing and editing the full contents of a blob. Cards can be dragged and dropped to be re-ordered within the dashboard. Blob cards can be dragged into folder cards. A brand-new project starts with no cards. The user creates folders and blobs as their organizational needs evolve.

When the mouse hovers over a blob card, a small button appears in the top-right cornder of the card. This is a "copy" button that copies the entire content of the blob to the operating system's clipboard.

### 2.2 Folder Navigation

Clicking on a folder results in another dashboard with only the blobs linked to that folder. This renders the same layout as the default project dashboard. There are no nested folders inside folders.

For blobs linked to a folder, the user can right-click its card to bring up a context menu. The menu should contain, in addition to default items, an option to "send blob back to root."

User can also navigate folders via the app sidebar.

### 2.3 Drag-and-Drop

The user can drag and drop folder cards and blob cards in the dashboard. During a drag, the dragged card turns slightly transluscnet, is removed from the dashboard grid, and follows the mouse. A "ghost" card of dashed lines is inserted into the position where the current card is hovering, to indicate where it would be placed if the mouse is released. This causes SwiftUI to animate the remaining cards sliding to make room, with a spring (response 0.30, dampingFraction 0.80) keyed on the item IDs.

A drag can be **cancelled** either when: (a) the user presses the ESC key, or (b) the mouse is released when there is no proper insert position. The card slides back into position with a spring animation.

After a successful drop, a **drop confirmation glow** appears around the dropped card. This is a perimeter around the card that fades away (0.5s hold and 0.4s fade). Use `confirmation` color from the color theme.

When a blob card hovers over a folder blob, the corresponding folder card exhibits a **drop preview glow** which is a permimeter around the folder card that holds until (a) blob card is dragged away OR (b) blob card is dropped into the folder. Use `accent` color from the color theme. If the blob is dropped into the folder, a **drop confirmation glow** appears as it would for re-ordering.

**sortOrder is always reassigned from scratch** after every move. `sortOrder` designates the order in which a given card appears in its dashboard context. More on this in §3 and §6.

### 2.4 Edit View

When a blob card is clicked via the dashboard, an EditView appears.

There are two viewing modes for the EditView. In **compact mode**, the EditView covers the whole app window minus the sidebar. In **expanded mode**, sandwiched between the sidebar and the EditView is a single-column, vertically scrollable field that lists all the dashboard items belonging to the dashboard context (i.e., either project folders+root blobs, or folder-level blobs). This field is called PinnedColumnView, and it inherits the looks and behaviors of the Dashboard.

The user can close out of EditView by cicking an "x" button in the top-right corner, or by pressing the ESC key. The edit view also features a "copy" button in the top right corner, leftside of the exit button. This button copies the entire content of the text to the operating system's clipboard. Next to the copy button is a "hide" button which "hides" the blob from the project (details of this feature are in the next section).

Any edits to the blob's text content made within EditView is automatically saved, and the change is immediately written to disk, when any of the following occurs:

* User closes out of the EditView.
* User hits Command+S keys.
* User registers the blob as a hidden blob.

**IMPORTANT:** The actual internals of EditView has already been built in parallel.

### 2.5 Hiding and Archiving

There are three distinct visibility levels. Each must be understood separately. First, note the terminology asymmetry: blobs and folders use **"hide/unhide"**; projects use **"archive/unarchive"**.

**Individual blobs can be hidden** by right-clicking on their corresponding dashboard cards to bring up a context menu, and selecting "hide."

**Folders can be hidden** by the same action via the dashboard. Hiding a folder affects all blobs linked to that folder.

The user can **see hidden items** for each project via the sidebar navigation. This results in a view that is visually identical to the regular dashboard, but is presented in a read-only mode. Dragging is also disabled.The user can also **unhide** both folders and blobs via the context menu of cards in this case.

**Projects can be archived**. This results in the entire project, including all its folders and blobs, being archived. The only thing this changes is twofold. First, the **project dashboard becomes read-only**, with dragging and EditView disabled. Secondly, active and hidden items are all shown in the same dashboard; "hidden" items are affectively "unhidden" within an archived project's dashboard. Thus, hiding, unhiding, and viewing hidden items are also disabled for archived projects. Projects can also be **restored**, or un-archived.

### 2.6 Sidebar and Navigation

The Sidebar sits on the left side of the app window. It is 248 px wide when open and 48 px wide when collapsed. 

The sidebar has a nested structure; it permanently shows icons (buttons) for different sidebar functionalities, even when "collapsed." Clicking on certain buttons expands the sidebar to reveal details. Hence, an "expanded" sidebar essentially consists in two adjacent sidebars, one thin (48px) and the other wider. Clicking on certain other buttons result in other functions (see below).

When the sidebar is **closed**, it shows the following items, in this order:

* File navigator
* New folder
* New blob
* git version control (planned feature; only placeholder button for now)
* (at the bottom) Settings

The following buttons are disabled when no project is selected: new folder, new blob, and git.

Clicking on the **file navigator** button expands the sidebar to reveal the following:

* "PROJECTS" section. This is a collapsible disclosure group containing live projects. The project in which the user is currently working is highlighted with a 2-pt left border accent and a slightly darker background.
* "ARCHIVED PROJECTS" section. This is a collapsible disclosure group of archived projects. The working-directory project features the same accent as live (non-archived) projects, as described above.

Clicking again the file navigator when the sidebar is open results in the sidebar collapsing.

Clicking on the settings button brings up the settings panel. Within the settings panel, the user can modify default font style, font size, EditView options (compact or expanded), color pallete, etc.

### 2.7 Context Menus

**Live project** (right-click in sidebar): Open, Rename, New folder, New blob [divider], View hidden items, [divider], Archive project (destructive, shown in red).

**Archived project** (right-click in sidebar): Open, [divider], Restore project, [divider], Delete project (destructive).

**Folder** (right click card in dashboard): Rename folder, Hide folder, [divider], Delete folder (destructive).

**Blob** (right click card in dashboard): Copy blob, Hide blob, Delete blob (destructive).

Folders and blobs have different context menus when hidden; the following are context menus available via the dashboard that results in Navigator → Right click on project → View hidden items:

**Hidden folder** (right click card): Restore folder, Delete folder (destructive).

**Hidden blob** (right click card): Restore blob, Delete blob (destructive).

Within an archived project, which is strictly read-only, right-clicking cards in the dashboard does not bring up any context menus.

## 3. Data Model

### 3.1 Blob

`Blob` (`Models/Blob.swift`) is the fundamental content unit. **(TO-DO: The following table should be updated during TipTap implementation.)**

| Field | Type | Purpose |
| --- | --- | --- |
| `id` | `UUID` | Globally unique identifier |
| `folderID` | `UUID?` | Which folder this blob belongs to. `nil` means the blob lives at the project root level. |
| `sortOrder` | `Int` | 0-based position among active blobs in the same context (folder or root); reassigned on every move |
| `isHidden` | `Bool` | `true` only when the blob was individually hidden, not when its folder was hidden wholesale. |
| `createdAt` | `Date` | Creation timestamp |
| `updatedAt` | `Date` | Last modified timestamp |

### 3.2 BlobFolder

`BlobFolder` (`Models/BlobFolder.swift`) is pure metadata: an `id` (`UUID`), a `name` (`String`), and a `sortOrder` (`Int`). It does **not** own or store blobs. The blobs that belong to a folder are found by filtering `project.blobs` where `blob.folderID == folder.id`.

Note that `sortOrder` of a `BlobFolder` might share the same context as some instances of `Blob`, since Blobs can exist at project root level.

### 3.3 DashboardItem

`DashboardItem` (`Models/DashboardItem.swift`) is an enum representing one cell in the project root dashboard grid.

| Case | Description |
| --- | --- |
| `.folder(BlobFolder)` | A folder card. By default, this appears before blob cards in the grid. |
| `.blob(Blob)` | A blob card. Appears after all folder cards by default. |
| `.ghost` | A transient drag placeholder inserted at the hovered drop position to show where the dragged blob would land. Never stored or persisted. Uses a fixed UUID (`00000000-0000-0000-0000-000000000001`) so SwiftUI's `ForEach` can track it without identity conflicts. |

`DashboardItem` conforms to `Identifiable` and `Equatable`.

### 3.4 Project

`Project` (`Models/Project.swift`) is the top-level container.

| Field | Type | Purpose |
|---|---|---|
| `id` | `UUID` | Unique identifier; also used as the JSON filename |
| `name` | `String` | Display name shown in the sidebar |
| `folders` | `[BlobFolder]` | Active folders shown on the dashboard |
| `hiddenFolders` | `[BlobFolder]` | Folders archived wholesale; their blobs remain in `blobs` |
| `blobs` | `[Blob]` | Flat pool of every blob in the project (both active and hidden) |
| `isArchived` | `Bool` | `true` when the entire project has been archived |
| `createdAt` | `Date` | Used to sort projects in sidebar display order |

As noted in the table above, blobs live in a flat `project.blobs` array rather than being nested inside each folder. This was an intentional design choice that makes several operations simple:

* **Drag into a folder**: just update `blob.folderID` and reassign `sortOrder` values. No splicing of nested arrays.
* **Hiding a folder**: move the folder metadata from `project.folders` to `project.hiddenFolders`. The blobs remain untouched, with their original `folderID`. Blobs are filtered out when entering a dashboard, by matching their `folderID`.
* **Blob hiding**: just set `blob.isHidden = true`. The blob stays in the flat pool, and are filtered out in the dashboard context.

## 4. Persistence

The FishTxt app should save any files relating to projects (metadata and blob contents) in `~/Documents/FishTxt/`. If the directory does not exist, FishTxt should create it on first launch.

## 5. Visual Design

### 5.1 Animations

Use native macOS animations when possible and applicable.

### 5.2 Window

* Minimum size 700 × 480 pt.
* Default size 1100 × 720 pt.

### 5.3 Typography

* Default to Menlo (or user-selected font), 16pt (or user-selected size) for all blobs in EditView.
* System font (San Francisco) for all UI chrome (column headers, sidebar labels, buttons).

### 5.4 Colors

Color palettes should be accessible through settings. See `FishTxt/resources/color_reference.md` tells you which color to map where. Only one palette availalbe for now: **Kimbie dark** (default on first launch). This is available in `FishTxt/web_wrapper/EditorDemo/Resources/colors.json`; this is the file that was used while EditView was being tested and developed in parallel. Take a look at `FishTxt/web_wrapper/EditorDemo/Sources/Colors.swift` to see how the EditView demo app handled colors. For now, let's just replicate the same mechanism. Later on, when we are ready to port over source codes from the demo app, we will consolidate any duplicate or conflicting items.

## 6. Anticipated logical pitfalls

This section outlines mistakes and confusions that were repeated during planning and previous attempts at implementation. Not all of these tips might apply to your implementation, but are presented below for your convenience.

___

**There are three conditions in which a blob will be read-only**: (1) project is archived, (2) blob is hidden, (3) blob's folderID is linked to a hidden folder. Be sure to verify that all three conditions are checked.
___

**Removing drop zones for read-only views.** In read-only views, drag-and-drop is disabled. Thus, you may find yourself removing the drop-zone from the layout. This will likely cause cards to pack together with no gaps. If so, a proper fix should be implemented to maintain the 12pt visual gap between cards even if drop zones are gone.

___

**`BlobFolder` is metadata only — it owns no blobs.** When adding a feature that queries "all blobs in this folder," always go through `project.blobs` filtered by `folderID`, not through the folder object itself. Similarly, when a folder is hidden or deleted, the operation only moves/removes the `BlobFolder` entry; the blobs are handled separately, and corresponding actions should be implemented (for example, a function that deletes all blobs with a matching `folderID` from `project.blobs`.)

___

**`sortOrder` should always be reassigned from scratch — treat it as volatile.** Examples of actions to which this tip might apply: moving blob from root to folder, re-ordering blobs, creating new folder, etc. These actions should all rebuild `sortOrder` valyes (0, 1, 2, ...) for every item in the affected context. Code that tries to insert a blob at a specific `sortOrder` value by incrementing an existing value will likely produce incorrect orderings.

___

**There are two distinct conditions wherein a blob may be "hidden" in the project:**

1. Blob was individually hidden via the dashboard. In this case, the blob's `isHidden == true` AND its `folderID` is `nil` or still in `project.folders`.
2. A folder containing the blob was hidden. In this case, the blob's `folderID` matches a hidden folder. The blob's `isHidden` may either be true or false.
