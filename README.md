# FishTxt

> A rich text editor for rapid brainstorming and longer drafts.

## Order of Contents

* [1. Overview](#1-overview)
* [2. Current Build](#2-current-build)
* [3. Color Themes](#3-color-themes)

## 1. Overview

FishTxt is a hybrid between a notetaking app and a conventional word document. It is a light-weight rich text editor that supports two distinct kinds of work in a single environment:

1. Rapid brainstorming, piece-wise drafting, and jumping between ideas
2. Careful organization of drafts, and longer sessions of focused writing.

When writing a long article that covers many sources and topics, it is hard to keep everything coherent in a single word document right from the start. Conversely, it is hard to develop a holistic vision only through a form of notetaking, whether it be in a physical notebook, a dedicated notes app, or — the worst but perhaps the simplest — another word document where you just throw everything in. Thus, most people require some combination of the two kinds of tools.

FishTxt was designed to be exactly that kind of combination, a set of tools that you can use from the very beginning of a project all the way to the first or second draft. Of course, you'll likely need at some point an actual, robust document editor like Microsoft Word or Apple Pages. FishTxt does not support print-layout formatting, only a copy-export that allows you to port things over to other apps. But FishTxt was designed specifically for the development phase, for longer projects, for the part of your work where it's still unclear what the finished product should really look like. In that regard, FishTxt is not intended to replace your document editor; but it does make you rethink what each tool is best used for.

## 2. Current Build

The app was designed by June Jung, and the codebase was vibe-coded with Claude by Anthropic. The current version is for Beta testing.

Much of FishTxt has been written as a native macOS application, but the actual text editor uses [TipTap](https://tiptap.dev/docs/editor/getting-started/overview), an open-source rich text editor framework. Moreover, the [tiptap-footnoes](https://github.com/buttondown/tiptap-footnotes) extension is used for adding references in the text. The editor runs in a javascript environment that is wrapped inside the app through Apple's `WKWebView` library.

### 2.1. Install

An installation `.dmg` and a compressed `.app` are both available in `packaging/`, and you can use any of the two.

### 2.2. First Launch and Walkthrough

When launching the app for the first time, FishTxt will have a "Welcome" project. This is an example project directory — which functions like any other FishTxt project that a user creates for their own use — and will guide you through the major features of the app. You can safely delete or archive this, if you want, after having been walked through.

### 2.3. File Persistence

Project files are stored in `~/Documents/FishTxt/`, and user settings are stored through `@AppStorage`.

## 3. Color Themes

Four colors themes are provided with the app.

### 3.1. Making your own

If you want to try making your own color theme, you'll have to edit `FishTxt/Resources/colors.json`. You might want to use `misc_resources/color_preview.py`: a python script that launches a html page, which simulates the look and feel of different UI elements in FishTxt. In the html page, you can select different color themes that ship with the app, and `Cmd + R` should reload any changes you make to the color themes. Tinkering with this is pretty fun.

Open your terminal, and enter:

```bash
cd path/to/your/FishTxt/download
python3 misc_resources/color_preview.py
```

### 3.2. Screenshots

(The macOS screenshot app captures the app window's title bar to be transparent against the system wallpaper. My wallpaper happened to be purple when I made these, so the title bar has a purple hue in every single screenshot; this can be ignored.)

**Coast (default)** ![coast_theme](/misc_resources/imgs/coast.png)

**Cherry** ![cherry_theme](/misc_resources/imgs/cherry.png)

**Birch** ![birch_theme](/misc_resources/imgs/birch.png)

**Flora** ![flora_theme](/misc_resources/imgs/flora.png)
