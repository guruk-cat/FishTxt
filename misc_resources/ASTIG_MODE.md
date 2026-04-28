# Astigmatism Mode in FishTxt

## Purpose

Astigmatism causes what's known as a "halo" effect around brighter-than-environment light sources. This causes issues with many night mode reading UI, or light-text-on-dark-background UI layouts. The simple solution is to use a "light mode" UI, but someone might still want to avoid the other kind of eye strain accompanied by a bright screen. The astigmatism mode (`astig-mode` henceforth) intends to address this issue.

## Feature scope

`astig-mode` applies to dark color palettes, or light-text-on-dark-background palettes, because the light palettes are largely unaffected by the halo effect described above. Everything described below in this document assumes that the app's settings are set to use a dark color palette.

`astig-mode` also only applies to the EditView in FishTxt.

## How it works

By default, the editor shows its content as it usually would: light text on dark background. However, the `astig-mode` kicks in *specifically for the paragraph or heading context that is focused.* A box-highlight is activated for that context (kind of like how VS Code works); this box-highlight uses the `surface` color of the respective light palette. For example, if the app is using `paper-dark` palette, while the rest of the editor uses the `surface` color from that palette for the editor's background, the box highlight for the focused context uses the `surface` color from the `paper-light` palette. Accordingly, the text within that context uses either `text_heading` or `text_body` from the opposite palette within the family. Again, e.g., `paper-dark` borrows colors from `paper-light`. Because the cursor will appear within the focused context (this is tautological), the cursor also borrow colors from the opposite, light palette.

## How to toggle `astig-mode`.

The toggle appears under the `editor` section within the app's settings panel.
