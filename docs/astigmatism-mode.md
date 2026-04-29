# Astigmatism Mode in FishTxt

## Purpose

Astigmatism causes what's known as a "halo" effect around brighter-than-environment light sources. This causes issues with many night mode reading UI, or light-text-on-dark-background UI layouts. The simple solution is to use a "light mode" UI, but someone might still want to avoid the other kind of eye strain accompanied by a bright screen. The astigmatism mode (`astig-mode` henceforth) intends to address this issue.

## Feature scope

`astig-mode` applies only to dark color palettes (i.e., light text on dark background), because the light palettes are largely unaffected by the halo effect described above. Everything described below in this document assumes that the app's settings are set to use a dark color palette. Moreover, `astig-mode` only affects the EditView (text editor) in FishTxt.

## How it works

With `astig-mode` toggled on, the editor shows its content for the most part as it usually would: light text on dark background. However, the `astig-mode` kicks in *specifically for the node block that is focused.* So, this is whatever paragraph, heading, list, block quotation, etc., within which the cursor is placed.

A box-highlight is then activated for that block (kind of like how VS Code works). This box-highlight uses the `surface` color of the respective light palette. For example, if the app is using `paper-dark` palette, while the rest of the editor uses the `surface` color from `paper-dark` to render the editor's background, the box highlight uses the `surface` color from the `paper-light` palette. Accordingly, the text within that context uses either `text_heading` or `text_body` from `paper-light`. The same goes for the cursor, which uses `meta_indication`.

Essentially, `astig-mode` is a selective palette-inversing feature. This feature was implemented with the assumption that color palettes follow the naming convention of `*-dark` and `*-light`.

## How to toggle `astig-mode`

A toggle for "Astigmatism mode" appears under the `editor` section within the app's settings panel. This toggle switch is visually "off" and disabled when a light palette is in use across the app, without destroying the persisting settings state for future uses with dark palettes.
