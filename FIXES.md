# Planned Fixes and New Features

Version tested: Beta (1)

## 1. rich text related

The following two items are not necessarily related from the user's perspective, but I imagine that they would be related in implementation.

### A: formatted paragraphs in blob excerpts

Let's say a blob contains in its first non-heading content some words that are bold. Like: "This is a **blob**, which is some text." In the blob excerpt in the dashbaord, the formatting is lost. Moreover, it looks like: "This is a   blob   which is some text," wherein the formatting characters (like astericks) are possibly relpaced with spaces. This needs fixing.

### B: copying with rich text

When using the copy feature (either via the dashboard or via the editor), i'd like it if the copied text retained the rich text formatting to a reasonable extent. Copying formatted text from external source (like Word or Pages) into FishTxt seems to work, but not the other way around.

## 2. editor behavior

### A: auto scrolling

If the user is typing near the bottom end of the editor window, and if a new line appears (through line breaks or through wrapping), the editor does in fact automatically scroll a line so the new lines keep appearing. However, I'd like an option wherein the auto scroll centers the last line of the text to the middle of the screen, so that new lines, when they appear, are vertically centered in the editor window.

When you implement this feature, I suspect that it will cause the footnotes to also appear slightly higher than where it is right now. Prevent this from happening (for example: add a padding above footnotes that adjust according to window size and eidtor size).

Moreover, a toggle for this feature should be present in the settings panel. Add it in the "appearance" group. The toggle should be named "Auto scroll," and the two switch options should be named "Regular" and "Centered," where "Regular" is default on the first launch of the app.

### B: cursor appearance

Currently, the cursor height seems to be matching the line spacing of the text. My reasoning is as follows. In the first line of a body paragraph following a heading, the cursor is the same height as the font; presumably because the gap between the heading and the paragraph is a padding, not a line space variable. But in subsequent lines, the height of the cursor extends above the font to cover the spacing between each line of text. This does not look good, and it is overall inconsistent.

First, I'd like the cursor height to consistently match the height of the font. This was nearly impossible using Apple's built-in NSTextView. Using custom css with TipTap should be easier than that.

Secondly, I'd also like the cursor width to be a little thicker; after all, the cursor is using the `accent` color from the color palette.

### C: formatting buttons

The formatting buttons (B, I, U) in the editor toolbar has indications built in (through color changes). However, when toggling a format option (either through a keyboard shortcut or clicking a button) the indication is not toggled until the user starts typing into place.

Example. I've written: "This is some," and then I toggle the bold button. The button does not change. I then start typing more: "This is some te..." the button is now properly indicated as active. I suspect that this has something to do with the way TipTap stores rich text data, and the way our custom css (or the bridge) is parsing through that data.

Moreover, attempting to toggle a format (e.g., cmd+I or clicking the I button), pressing space, and then typing results in the formatting request being completely ignored (no italics, and no indication on the button).

Putting the cursor inside a region of text that has already been formatted (with bold, italics, etc.) does properly change any toolbar indications.

## 3. Sidebar

### navigator nesting

Right now, in the file navigator, folders appear more indented than root blobs. Folder-contained blobs appear with the same indentation as folders. I suspect that this has to do with the chevron (expand/collapse) appearing next to folder names in the sidebar. Because project directories use different font settings than folders, I don't think it's necessary to differntiate the two in the sidebar with indents. Only indent folder-level blobs.

### navigator highlights

**Bug fix:** When selecting a folder or blob in the navigator, the respective item is highlighted (so far correct behavior). The bug: when selecting a folder (thus highlighting that folder), then selecting a blob (thus highlighting the blob), the highlight on the folder persists instead of being toggled off. This happens regardless of whether the blob belongs to the previously selected folder. This does NOT happen when selecting a folder after having selected previously a different folder. Fix the code such that only one item in the navigator is highlighted at a given time (the item that is mainly being displayed, whether it be the project root dashboard, folder dashboard, or a blob editor).

**New rule:** The dashboard or editor context should be the only determining factor when it comes to highlighting navigator items. Examples:

* Project root dashboard shown = project highlighted in navigator.
* Folder dashboard shown = corresponding folder highlighted.
* Blob editor open = corresponding blob highlighted.

Selected item in the navigator, regardless of kind, should be displayed in `content_secondary` as its font color. Otherwise, they should all be `content_primary` as their font color.

### icon buttons

The sidebar buttons (icons) should default to `content_tertiary`. When mouse is hovering over one of them, it should light up as `content_primary`, and return to `content_tertiary` afterwards.

For sidebar buttons that bring up expandables or panels (i.e., file navigator, settings, and in the future, git control), they should stay in `content_primary` when they are active.

For sidebar buttons with one-time actions (new folder, new blob), they should light up in `confirmation` when clicked, and fade away to normal. In this case, "normal" means whatever the the mouse-hovering condition would dictate the color to be. Thus, for example, clicking the new blob button, and leaving the mouse hovering over it, should result in the button briefling glowing in `confirmation` and returning to `content_primary`; when the mouse is no longer hovering, that is when the button should return to `content_tertiary`. When the mouse is not hovering by the time `confirmation` glow duration is over, it should return immediately to `content_tertiary`.
