# FishTxt Docs Map

## About FishTxt

FishTxt is a hybrid between a notetaking app and a conventional word document. It is a light-weight rich text editor that supports two distinct kinds of work in a single environment:

1. Rapid brainstorming, piece-wise drafting, and jumping between ideas
2. Careful organization of drafts, and longer sessions of focused writing.

When writing a long article that covers many sources and topics, it is hard to keep everything coherent in a single word document right from the start. Conversely, it is hard to develop a holistic vision only through a form of notetaking, whether it be in a physical notebook, a dedicated notes app, or — the worst but perhaps the simplest — another word document where you just throw everything in. Thus, most people require some combination of the two kinds of tools.

FishTxt was designed to be exactly that kind of combination: a set of tools that you can use from the very beginning of a project all the way to the first or second draft. Of course, you'll likely need at some point an actual, robust document editor like Microsoft Word or Apple Pages. While FishTxt can export to a printer or PDF, this is done through built-in CSS profiles, which is quite different from document editors if that's what you're used to. But remember, FishTxt was designed specifically for the development phase, for longer projects, for the part of your work where it's still unclear what the finished product should really look like. In that regard, FishTxt is not intended to replace your document editor; but it does make you rethink what each tool is best used for.

## Authors and Credits

FishTxt was designed by me, and the codebase was built largely by Claude Sonnet. The actual text editor uses [TipTap](https://tiptap.dev/docs/editor/getting-started/overview), an open-source rich text editor framework. Moreover, the [tiptap-footnoes](https://github.com/buttondown/tiptap-footnotes) extension is used for adding in-line references and notes.

## Repository Map

- `FishTxt/`: source codes, application assets, etc.
  - `Assets.xcassets`
  - `FishTxt.icon`
  - `Resources/`
  - `Sources/`: most of the `.swift` files live here.
  - `FishTxt.entitlements`
  - `info.plist`
- `FishTxt.xcodeproj`: Xcode project file
- `editor-src/`: Vite project that compiles `Resources/editor.html`.
- `misc_resources`: miscellaneous tools and files for development
  - `imgs/`: screenshots for the `READ_ME.md`
  - `welcome-project`: project files for the example project that is saved to `~/Documents/FishTxt` on the app's first launch
- `docs/`: various documentation files in `.markdown` format.
- `Application (Beta)/`: app distribution formats
  - `FishTxt.zip`

## Documentation Files

| File | What it covers |
| ---- | -------------- |
| `docs-map.md` | This file. App overview, repo map, and index of all docs. |
| `data-model.md` | Data structs (`Project`, `Blob`, `BlobFolder`), `ProjectStore` persistence and CRUD, blob merge logic, footnote consolidation. |
| `editor.md` | The text editor end-to-end: `EditView`, `WebEditorView`, `EditorBridge`, the JS/Vite source, astig mode implementation. |
| `sidebar.md` | All three sidebar panels (file navigator, outline, merge) and the sidebar button column. |
| `dashboard.md` | Dashboard card grid, drag-and-drop, navigation state. |
| `printing.md` | Print flow, print profiles, footnote HTML rendering. |
| `colors.md` | Color palette design spec: hue tiers, color role mappings, contrast guidelines. |
| `astigmatism-mode.md` | UX-level description of astigmatism mode: purpose, scope, and how to toggle it. |

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
| Astigmatism mode (architecture, geometry, pitfalls) | `editor.md`; `AppColors.astigDocStartJS()`, `AppColors.astigLightColors()`, `EditorBridge.setAstigMode(_:)`, `main.js` (`AstigFocusExtension`, `setContent`, `setAstigMode`) |
| Dashboard drag & drop | `DashboardView.swift` |
| Sidebar tree drag & drop | `FileNavigatorView.swift` |
| Card rendering & previews | `CardView.swift` |
| Save lifecycle | `EditView.swift` |
| JS ↔ Swift editor messages | `EditorBridge.swift`, `WebEditorView.toolbarInitJS` |
| Editor DOM / TipTap internals | `editor-src/src/main.js`, `editor-src/src/style.css` (rebuild to apply) |
| Compiled editor (read-only) | `Resources/editor.html` (grep; do not edit directly) |
| Settings & user preferences | `SettingsView.swift` (includes print profile picker) |
