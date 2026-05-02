# Astigmatism Mode in FishTxt

## Purpose

Astigmatism causes what's known as a "halo" effect around brighter-than-environment light sources. This causes issues with many night mode reading UI, or light-text-on-dark-background UI layouts. The simple solution is to use a "light mode" UI, but someone might still want to avoid the other kind of eye strain accompanied by a bright screen. The astigmatism mode (`astig-mode` henceforth) intends to address this issue.

## How it works

With `astig-mode` toggled on, two different palettes are in use, which can be specified in user settings. The main palette will be a dark palette, and the "astigmatism palette" will be a light-toned palette. Each color palette in FishTxt has a key named "type," of which the value is either "dark" or "light." The app uses this to distinguish between the two kinds of palettes.

The editor shows its content for the most part with the dark palette: light text on dark background. However, the `astig-mode` kicks in *specifically for the node block that is focused.* So, this is whatever paragraph, heading, list, block quotation, etc., within which the cursor is placed. A box-highlight is then activated for that block (kind of like how VS Code works). This box-highlight uses the `surface` color of the light palette. For example, if the app is using `paper-dark` palette, while the rest of the editor uses the `surface` color from `paper-dark` to render the editor's background, the box highlight uses the `surface` color from the `paper-light` palette. Accordingly, the text within that context uses either `text_heading` or `text_body` from `paper-light`. The same goes for the cursor, which uses `meta_indication`. Essentially, `astig-mode` is a selective palette-inversing feature.

## How to toggle `astig-mode`

A toggle for "Astigmatism mode" appears within the app's settings panel. With this toggle off, the settings UI only allows selection of one color palette. With the toggle on, an additional selection appears for the astigmatism palette.
