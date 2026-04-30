# Editor

## UX Overview

The editor occupies the right side of the app window whenever a blob is open. It is a rich text editor built on TipTap (ProseMirror), hosted inside a WKWebView. The toolbar sits above the editing area and provides formatting controls: bold, italic, underline, blockquote, heading levels (H1–H3), bullet and ordered lists, and image insertion.

The editor autosaves 5 seconds after a change, and also saves on ⌘S, on ESC (which also closes the editor), and when the app quits. A small "Saving..." / "Saved!" island confirms save state.

Settings that affect the editor: font family, font size, auto-scroll mode, image width limit, astigmatism mode. See `docs-map.md` → Settings for where these live in code.

For astigmatism mode from a user/feature perspective, see `astigmatism-mode.md`. The implementation details are in the **Astigmatism Mode** section below.

## Entry & Shell

- **`Sources/App/FishTxtApp.swift`** — `@main` entry point. Installs `ProjectStore` and `AppColors` as environment objects, wires a `⌘S` `saveDocument` notification, and flushes a save on app quit via `AppDelegate`.
- **`Sources/Views/ContentView.swift`** — root layout. `SidebarView` on the left; on the right either `DashboardView` (when no blob is active) or `EditView` (when `activeBlobID != nil`).

## EditView (`Sources/Views/Editor/EditView.swift`)

Hosts the WebKit editor and manages the save lifecycle:

- Listens for `.saveDocument` notification (⌘S or app quit)
- Autosaves 5 seconds after first dirty event
- Saves before closing/hiding
- Shows "Saving..." / "Saved!" island
- Reapplies colors on palette change
- ESC key triggers save and close
- Injects ESC monitor on appear, cleans up on disappear
- `onChange(of: appColors.surface)` calls `bridge.setAstigMode(astigMode)` on palette change to recompute astig colors from the new light counterpart

## WebEditorView (`Sources/Views/Editor/WebEditorView.swift`)

`NSViewRepresentable` wrapping `WKWebView` that loads `Resources/editor.html`.

**Injection timing**:

- **Document-start**: Color CSS variables (prevents color flash); astig mode initial state (`window.__ft_astig`, astig CSS vars)
- **Document-end**: Toolbar wiring JavaScript (`toolbarInitJS` — wired after TipTap modules load from the compiled bundle)

**Toolbar init** wires up click handlers for:

- Bold/italic/underline/blockquote toggles
- Heading level dropdown (H1/H2/H3)
- Bullet/ordered list dropdown
- Image insertion (posts `insertImage` to Swift)
- Copy all (sends content back to Swift)
- Close editor

Uses `WeakMessageHandler` to prevent retain cycle between `WKUserContentController` and `EditorBridge`.

Updates auto-scroll mode, font, and image half-width on settings change via coordinator.

## EditorBridge (`Sources/Views/Editor/EditorBridge.swift`)

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
- `headingVisible` — JS reports which heading is in the viewport (object: `Int` heading index); `EditorBridge` re-posts as `activeHeadingChanged` notification for `BlobOutlineView`

**Swift → JS** (commands):

- Toggle formatting: `toggleBold()`, `toggleItalic()`, `toggleUnderline()`, `toggleBlockquote()`, `toggleBulletList()`, `toggleOrderedList()`
- Heading: `setHeading(level:)`
- Content: `setContent(_:)`, `getContent(completion:)`
- Navigation: `scrollToTop()`, `focus()`, `scrollToHeading(index:)`
- Theming: `applyColors()`, `setAutoScroll(_:)`, `setAstigMode(_:)`
- Image: `insertImage(src:)` — inserts a `figure > img` block at the cursor using `callAsyncJavaScript` (handles large base64 payloads safely); `setImageHalfWidth(_:)` — injects `--ft-img-max-width: 50%|100%` CSS variable

**Clipboard helper**:

- `writeToClipboard(html:plainText:)` — wraps HTML in UTF-8 document wrapper so Pages/Word handle multi-byte characters (curly quotes, em-dashes) correctly

**Notification names** (defined as `Notification.Name` extensions in `EditorBridge.swift`):

- `scrollToOutlineHeading` — posted by `BlobOutlineView` (object: `Int` heading index); received by `EditView` to call `bridge.scrollToHeading(index:)`
- `activeHeadingChanged` — posted by `EditorBridge` when the JS side reports a `headingVisible` message (object: `Int` heading index); received by `BlobOutlineView` to highlight the active row

**`evaluateJavaScript` vs `callAsyncJavaScript`**:

`evaluateJavaScript` (via `EditorBridge.evaluate(_:)`) is used for style injection (the `ft-font` `<style>` element) and works reliably when called after `webView(_:didFinish:)` with a short delay. `callAsyncJavaScript` is used for `setAstigMode` and image insertion because it handles larger payloads and is the more reliable channel for runtime commands. Do not assume these are interchangeable.

## Editor Source (`editor-src/`)

`Resources/editor.html` is generated by a Vite build — do not edit it directly. The source lives in `editor-src/`:

- **`editor.html`** — HTML entry point: toolbar markup, `#editor` div, `#footnote-tooltip` div, `<script type="module" src="/src/main.js">`.
- **`src/main.js`** — all editor logic: TipTap initialisation, Swift bridge (`window.editorBridge`), custom cursor, centred-scroll mode, footnote tooltip, and footnote-reference click handling.
- **`src/style.css`** — all editor CSS: toolbar, ProseMirror content styles, footnotes, custom cursor.
- **`vite.config.js`** — uses `vite-plugin-singlefile` to inline everything into a single `editor.html`. Output goes directly to `../FishTxt/Resources/`.
- **`package.json`** — dependencies: TipTap 2.27.x core + extensions (`@tiptap/core`, `@tiptap/starter-kit`, `@tiptap/extension-*`), `tiptap-footnotes`, `tiptap-text-direction`. Dev: Vite, `vite-plugin-singlefile`.

**To rebuild after editing source files:**

```bash
cd editor-src
npm run build
```

The output `FishTxt/Resources/editor.html` is what the app loads. Rebuild and relaunch the Xcode app to pick up changes.

**Key design points:**

- TipTap's Document schema is extended to `block+ footnotes?` so `tiptap-footnotes` can place a `footnotes` node at the end.
- `window.editorBridge` is the JS object Swift calls via `evaluateJavaScript`. `window.webkit.messageHandlers.editorBridge` is the handler JS posts messages to.
- The custom cursor (`#custom-cursor`) replaces the native caret (`caret-color: transparent` on `.ProseMirror`). It is repositioned in `updateCursor()` on every selection/focus/update event.
- Centred-scroll mode (`doCenteredScroll`) only triggers when the cursor is below the vertical midpoint of `#editor`, matching the original editor behaviour.
- **`Resources/editor.html`** — compiled single-file TipTap editor. **Do not edit directly** — rebuild from `editor-src/` instead. Grep for specific patterns rather than reading in full.

## Astigmatism Mode

For the full UX-level description, see `astigmatism-mode.md`.

`astig-mode` applies only to dark palettes. When active, the currently focused text block is highlighted with a light box using colors from the light counterpart of the active dark palette (e.g. `paper-dark` → pulls colors from `paper-light`). All other blocks remain in the normal dark-on-light style.

**End-to-end flow:**

1. `AppColors.astigDocStartJS()` generates a WKUserScript injected at document-start. It sets `window.__ft_astig = true/false` and writes five astig CSS variables (`--astig-surface`, `--astig-text-body`, `--astig-text-heading`, `--astig-meta-indication`, `--astig-text-muted`) directly on `document.documentElement.style` (same mechanism as palette color vars — inline style, highest specificity, no flash).
2. `main.js` `onCreate`: if `window.__ft_astig`, sets `astigMode = true` and adds `astig-mode` to `document.body`. Does **not** dispatch the ProseMirror enable transaction yet — see `contentReady` below.
3. `main.js` `setContent()`: on first call, sets `contentReady = true` and, if `astigMode`, dispatches the ProseMirror enable transaction. This prevents the decoration appearing on the blank pre-load state.
4. `EditorBridge.setAstigMode(_:)` handles runtime toggles (from Settings). Uses `callAsyncJavaScript` to set astig CSS vars and call `window.editorBridge.setAstigMode(enabled)`. Only dispatches the enable transaction if `contentReady`.
5. `EditView.onChange(of: appColors.surface)` calls `bridge.setAstigMode(astigMode)` on palette change to recompute colors from the new light counterpart.

**ProseMirror decoration — the only correct approach:**

The highlight is implemented as a ProseMirror `Plugin` (`AstigFocusExtension` in `main.js`). The plugin carries a boolean state (enabled/disabled) toggled by dispatching `tr.setMeta(astigKey, enabled)`. Its `decorations` prop is called automatically on every state transaction (cursor moves, edits, selection changes) and returns a `Decoration.node` on the currently focused block.

**Do not attempt to add the highlight by calling `element.classList.add()` on nodes inside `.ProseMirror`.** ProseMirror manages its DOM via `MutationObserver` and re-renders nodes when it detects attribute mutations, immediately overwriting any externally added classes. The result is a brief flash followed by reversion — the decoration will appear and disappear within a single frame. Decorations are the framework-sanctioned mechanism precisely because ProseMirror applies them itself during rendering.

**Box-highlight geometry — why px values are baked from Swift:**

The highlight box is rendered using 8 `box-shadow` layers (0 spread, explicit offsets) to achieve independent horizontal and vertical extension. The horizontal offset (`X px`, where `X = Int(currentFontSize)` — 1em of the body text font) is injected as a literal value from `applyEditorStyle()` in `EditorBridge`.

Two pitfalls drove this design:

- **CSS custom properties do not work in `box-shadow` x-offset in WKWebView.** Using `var(--ft-font-size, 1em)` as the x-offset silently falls back to `1em` regardless of whether the variable is set. There is no error; the fallback is simply used. Baking the px value from Swift into the injected CSS string is the only reliable approach.
- **`em` in `box-shadow` resolves to the element's own font-size.** A `0.5em` spread on an `h1` (which has `font-size: 2em`) is visually twice as wide as the same spread on a `<p>`. This makes heading highlights inconsistent with paragraph highlights. Using a px value derived from the body font size (injected by Swift, which knows `currentFontSize`) ensures all node types get the same horizontal extent.

The 8-shadow composition:

```
0  -V 0 0 color   /* top */
0   V 0 0 color   /* bottom */
X   0 0 0 color   /* right */
-X  0 0 0 color   /* left */
X  -V 0 0 color   /* top-right corner */
-X -V 0 0 color   /* top-left corner */
X   V 0 0 color   /* bottom-right corner */
-X  V 0 0 color   /* bottom-left corner */
```

Where `X = body font size px` and `V = 0.4em` (em-relative to each node's own font size, so vertical padding adapts to heading vs. paragraph line height). The 4 corner shadows fill the gaps that would otherwise appear between the edge shadows.

**List item geometry:**

The `<ul>` / `<ol>` has `padding-left: 1.5em`. The `<li>` element's left edge is therefore `1.5 × font_size px` inside the text area left edge — the same edge that paragraph highlights start from. To align the list item highlight's left edge with paragraphs (and to include bullets/numbers inside the light box), the left extension from `<li>` must be `1.5 × X + X = 2.5 × X px`. The right extension stays `X px` because `<li>` right edge aligns with paragraph right edge. This asymmetric 8-shadow is injected as a separate `li.astig-focus` rule (higher specificity than the general `.astig-focus` rule).

**Blockquote:**

`border-radius` on an element also rounds the corners of its `border-left`, making the blockquote's left indicator bar look trapezoidal. `border-radius: 0` is set globally on all `.astig-focus` nodes for consistency.

**Footnotes:**

The `tiptap-footnotes` extension introduces three node types with distinct astig considerations:

- **`footnoteReference`** (inline `<sup>`) — sits inside a body paragraph, so the containing paragraph gets `.astig-focus` correctly. However, `a.footnote-ref` has an explicit `color: var(--meta-indication)` rule that overrides inherited color. A dedicated `.astig-focus a.footnote-ref { color: var(--astig-meta-indication) }` rule overrides this.

- **`footnotes`** container (`<ol class="footnotes">`) — registered under the name `'footnotes'`, not `'orderedList'`, even though it extends `OrderedList`. The `isList` check in `AstigFocusExtension` must include `node1.type.name === 'footnotes'` so the plugin takes the depth-2 path and decorates the individual `footnote` (`<li>`) rather than the entire `<ol>`.

- **`footnote`** items (`<li>`) — receive `.astig-focus` via the depth-2 decoration path (same as regular list items). The asymmetric box-shadow from `applyEditorStyle()` (`li.astig-focus` selector) already covers these. Additional CSS rules handle `li.astig-focus` background/color and `li.astig-focus::marker` using `--astig-text-muted`.

- **`--astig-text-muted`** — a fifth astig CSS variable pulled from `text_muted` in the light counterpart palette. Needed for footnote markers and the `ol.footnotes` separator line. Injected by both `astigDocStartJS()` and `setAstigMode(_:)`.
