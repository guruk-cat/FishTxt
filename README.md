# FishTxt

> A rich text editor for rapid brainstorming and managing long drafts.

## Overview

FishTxt is a hybrid between a notetaking app and a conventional word document. It is a light-weight rich text editor that supports two kinds of work in a single environment: (1) rapid brainstorming, piece-wise drafting, and jumping between ideas; (2) careful organization of drafts, and longer sessions of focused writing.

When writing a long article that covers many sources and topics, it is hard to keep everything coherent in a single word document right from the start. Conversely, it is hard to develop a holistic vision only through a form of notetaking, whether it be in a physical notebook, a dedicated notes app, or — the worst but perhaps the simplest — another word document where you just throw everything in. Thus, most people require some combination of the two kinds of tools.

FishTxt was designed to be exactly that kind of combination, a set of tools that you can use from the very beginning of a project all the way to the first or second draft. Of course, you'll likely need at some point an actual, robust document editor like Microsoft Word or Apple Pages. FishTxt does not support print-layout formatting, only a copy-export that allows you to port things over to other apps. But FishTxt was designed specifically for the development phase, for longer projects, for the part of your work where it's still unclear what the finished product should really look like. In that regard, FishTxt is not intended to replace your document editor; but it does make you rethink what each tool is best used for.

## Current Build

The app was designed by June Jung, and the codebase was vibe-coded with Claude by Anthropic. The current version is for Beta testing.

Much of FishTxt has been written as a native macOS application, but the actual text editor uses [TipTap](https://tiptap.dev/docs/editor/getting-started/overview), an open-source rich text editor framework. Moreover, the [tiptap-footnoes](https://github.com/buttondown/tiptap-footnotes) extension is used for adding footnotes in the text. The editor runs in a javascript environment that is wrapped inside the app through Apple's `WKWebView` library.

## Install

An installation `.dmg` and a compressed file `.app` are both available in `Packaging/`, and you can use any of the two.

## First Launch

When launching the app for the first time, FishTxt will have a "Welcome" project. This is an example project directory — which functions like any other FishTxt project that a user creates for their own use — that will guide you through the major features of the app. You can safely delete or archive this, if you want, after having been walked through.

## File Persistence

Project files are stored in `~/Documents/FishTxt/`, while user settings are stored through `@AppStorage`.

## Miscellaneous Files

The folder `misc_resources` contain some stuff that's not part of the packaged application. These are:

* `FishTxt.icon`: the app icon that you can edit with Apple's icon composer.
* `welcome-project/`: contains the project data for the "welcome" project mentioned earlier.
* `color_preview.py`: a python script that launches a html page that simulates the look and feel of different UI elements in FishTxt. In the html page, you can select different color themes that ship with the app, and `Cmd + R` should reload any changes you make to the color themes, which are stored in `FishTxt/Resources/colors.json`. Tinkering with this is pretty fun.
* `DRAG_FEATURE_HELP.md`: There was a reoccuring bug with the drag-and-drop features, so this file exists for reference when trying to fix similar issues.
* `OLD_DOCS.md`: a comprehensive-ish planning documentation describing the app's features and build. (This is what I fed into Claude Code at some point.)
