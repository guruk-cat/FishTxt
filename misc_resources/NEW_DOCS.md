# FishTxt - Comprehensive Documentation

> A rich text editor for rapid brainstorming and managing long drafts.

## Overview

### Purpose

FishTxt is a hybrid between a notetaking app and a conventional word document. It is a light-weight rich text editor that supports two distinct kinds of work in a single environment:

1. Rapid brainstorming, piece-wise drafting, and jumping between ideas
2. Careful organization of drafts, and longer sessions of focused writing.

When writing a long article that covers many sources and topics, it is hard to keep everything coherent in a single word document right from the start. Conversely, it is hard to develop a holistic vision only through a form of notetaking, whether it be in a physical notebook, a dedicated notes app, or — the worst but perhaps the simplest — another word document where you just throw everything in. Thus, most people require some combination of the two kinds of tools.

FishTxt was designed to be exactly that kind of combination, a set of tools that you can use from the very beginning of a project all the way to the first or second draft. Of course, you'll likely need at some point an actual, robust document editor like Microsoft Word or Apple Pages. FishTxt does not support print-layout formatting, only a copy-export that allows you to port things over to other apps. But FishTxt was designed specifically for the development phase, for longer projects, for the part of your work where it's still unclear what the finished product should really look like. In that regard, FishTxt is not intended to replace your document editor; but it does make you rethink what each tool is best used for.

### Authors

FishTxt was designed by June Jung, and the codebase was built largely by Claude Sonnet.

### Current Version

This version is the Beta version (build 1), currently being tested in real use (by me, June Jung).

### Repository Map

* `FishTxt/`: source codes, application assets, etc.
  * `Assets.xcassets`
  * `FishTxt.icon`
  * `Resources/`
  * `Sources/`: most of the `.swift` files live here.
  * `FishTxt.entitlements`
  * `info.plist`
* `FishTxt.xcodeproj`: Xcode project file
* `mist_resources`: miscellaneous tools and files for development
  * `FishTxt.icon`: the original icon file is left as a duplicate, so that it can be edited without affecting the app build in Xcode
  * `imgs/`: screenshots for the `READ_ME.md`
  * `welcome-project`: project files for the example project that is saved to `~/Documents/FishTxt` on the app's first launch
  * `color_preview.html`: an html template that simulates different UI elements of FishTxt, with different color themes loaded from `FishTxt/Resources/colors.json`
  * `color_preview.py`: a pythons script that opens a local host for `colors_preview.html` and ensures that any edits to `colors.json` are freshly loaded at `Cmd+R`
  * `DRAG_FEATURE_HELP.md`: There was a reoccuring bug with the drag-and-drop features, so this file exists for reference when trying to fix similar issues.
* `packaging/`: app distribution formats
  * `FishTxt.dmg`
  * `FishTxt.zip`

## Codebase and Main Features

