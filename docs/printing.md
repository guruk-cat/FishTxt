# Printing

## UX Overview

Blobs can be printed to a physical printer or saved as PDF. The print sheet is the standard macOS system print dialog, which includes "Save as PDF." Users select a print profile in Settings (under Appearance); profiles control the full visual presentation of the printed document — fonts, margins, heading styles, etc.

## Print Flow (`ProjectStore.printBlob`)

`printBlob(blobID:in:)` drives the full print pipeline:

1. Generate HTML from blob's TipTap JSON using `loadBlobHTML()` (preserves headings, lists, bold/italic/underline, blockquotes, and footnotes with two-way linking)
2. Load the active print profile CSS from `Resources/print-profiles/`
3. Wrap HTML fragment in a minimal `<html>` document with the profile CSS injected
4. Create a temporary off-screen `WKWebView`, load the document, and invoke `printOperation(with:)` on macOS 13+
5. Show the system print sheet (which includes "Save as PDF")

**Image support**: `image` nodes → `<figure><img src="..." alt="..."></figure>`. The `src` is a base64 data URL stored directly in the blob JSON. Print output respects the `imageLimitHalfWidth` setting by injecting `--ft-print-img-max-width: 50%|100%` as a CSS variable before the profile CSS, which print profiles consume via `max-width: var(--ft-print-img-max-width, 100%)` on `figure`.

## Print Profiles

Print profiles are self-contained CSS files stored in `Resources/print-profiles/`. Each profile:

- Is named `<profileName>.css` (e.g., `palatino_basic.css`, `monospace.css`)
- Owns all styling: fonts, sizes, margins, headings, lists, blockquotes, footnotes, figures, etc.
- Is injected into the `<style>` block of the print document, preceded by a `:root { --ft-print-img-max-width: ... }` declaration injected by `printBlob` based on the `imageLimitHalfWidth` setting
- Profiles consume `--ft-print-img-max-width` via `figure { max-width: var(--ft-print-img-max-width, 100%); }`

Selection is persisted via `@AppStorage("printProfile")` (defaults to first available profile if not set).

**To add a new profile:**

1. Create a `.css` file in `FishTxt/Resources/print-profiles/`
2. Add it to the Xcode target's "Copy Bundle Resources" build phase (already configured for the folder)
3. Restart the app; the profile appears in Settings automatically

## Footnote HTML Rendering

`ProjectStore.renderNodeHTML()` handles footnote-related TipTap node types when generating print HTML:

- `footnoteReference` nodes → `<sup><a href="#fn:1" id="ref:1">[1]</a></sup>` (clickable links both ways)
- `footnotes` / `footnote` nodes → `<ol class="footnotes"><li id="fn:1">...content... <a href="#ref:1">↑</a></li></ol>` (with backlinks)

Print-specific CSS can style footnotes appropriately (e.g., smaller font, page break handling).
