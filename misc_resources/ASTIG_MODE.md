# Astigmatism Mode in FishTxt

## Purpose

Astigmatism causes what's known as a "halo" effect around brighter-than-environment light sources. This causes issues with many night mode reading UI, or light-text-on-dark-background UI layouts. The simple solution is to use a "light mode" UI, but someone might still want to avoid the other kind of eye strain accompanied by a bright screen. The astigmatism mode (`astig-mode` henceforth) intends to address this issue.

## Feature scope

`astig-mode` applies to dark color palettes, or light-text-on-dark-background palettes, because the light palettes are largely unaffected by the halo effect described above. Everything described below in this document assumes that the app's settings are set to use a dark color palette.

`astig-mode` also only applies to the EditView in FishTxt.

## How it works

By default, the editor shows its content as it usually would: light text on dark background. However, the `astig-mode` kicks in *specifically for the text block that is focused.* A box-highlight is activated for that block (kind of like how VS Code works). This box-highlight uses the `surface` color of the respective light palette. For example, if the app is using `paper-dark` palette, while the rest of the editor uses the `surface` color from the `paper-dark` palette for the editor's background, the box highlight for the focused context uses the `surface` color from the `paper-light` palette. Accordingly, the text within that context uses either `text_heading` or `text_body` from the `paper-light`. The same goes for the cursor, which currently uses `meta_indication`. Essentially, it's a selective palette-inversing feature.

## How to toggle `astig-mode`

The toggle for "Astigmatism mode" appears under the `editor` section within the app's settings panel. This toggle switch is visually "off" and disabled when a light palette is in use across the app, without destroying the persisting settings state for future uses with dark palettes.

## Notes for implementation

1. Assume that color palettes follow the naming convention of `*-dark` and `*-light`.
2. Ensure that the box-highlight spans the full width of the *text width*, not the whole *editor width*, as the minimum, and then some extra space for visual margins. This should be the case even when the line is technically "empty" or only partially filled.
3. Font size is dynamically set by the user in settings. This will affect the line spacing and the pagraph spacing. Meanwhile, the box-highlight should also have some vertical paddings to the edges. The size of these paddings should dynamically adapt to font size and page formatting just described above.
4. Note that font size will also affect the text body width. You should check how the margins or body width in the *editor level* is calculated, and figure out a reliable way to determine the dimensions of the box-highlight.
5. The formatting toolbar at the top of EditView should not be affected by `astig-mode`.
