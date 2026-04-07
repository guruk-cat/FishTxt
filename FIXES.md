# Planned Fixes and New Features

Below are the remaining fixes (or fixes to be re-attempted).

## 1. rich text related

We fixed font formatting (bold, italics, etc.) in blob excerpts; but we forgot to do the same for blobs in the project navigator. I don't think it'd be necessary to include bold, italics, and underlines in the navigator, but we do need to fix the thing where, for example, bold text will appear with extra spaces before and after the word.

## 2. editor auto-scrolling

So, the attempted fix is not exactly what I had in mind.

Currently, the app does in fact vertically center the cursor; but NOT when I run out of space near the end of the blob, and this is precisely where I wanted the app to add extra space, such that, even though there aren't more text lines after the cursor, the line that I am editing can still be centered.

Also, the feature that has been implemented right now is more of a "typewriter" mode, wherein the cursor-line (i.e., the line being edited) is automatically centered no matter what. Thus, even if I scroll away a little bit (so that the line I'm editing is, say, a little closer to the top), whenever I start typing the cursor-line goes right back to the center. This is NOT what I wanted.

Instead, what I wanted is just an automatic scroll *when I hit the bottom of the blob.*

If the user is typing near the bottom end of the editor window, and if a new line appears (through line breaks or through wrapping), the editor should auto scroll such that new lines, when they appear, are vertically centered in the editor window. 

Moreover, this should *feel* like a scroll, with a smooth animation, instead of a choppy "jump," which is more like what we have right now.

When you implement this feature, I suspect that it might cause the footnotes to also appear slightly higher than where it is right now. Prevent this from happening (for example: add a padding above footnotes that adjust according to window size and eidtor size).

### 3. cursor appearance

Currently, the cursor height seems to be matching the line spacing of the text. My reasoning is as follows. In the first line of a body paragraph following a heading, the cursor is the same height as the font; presumably because the gap between the heading and the paragraph is a padding, not a line space variable. But in subsequent lines, the height of the cursor extends above the font to cover the spacing between each line of text. This does not look good, and it is overall inconsistent.

First, I'd like the cursor height to consistently match the height of the font. This was nearly impossible using Apple's built-in NSTextView. Using custom css with TipTap should be easier than that.

Secondly, I'd also like the cursor width to be a little thicker; after all, the cursor is using the `accent` color from the color palette.

### 4. formatting buttons

The formatting button indications are still behaving as they did before.

More specifically, for example, if I press Cmd + B for bold text, the button indication on the toolbar does not toggel until I start typing: that is, until the cursor actually enteres the place where text would appear bold.

I suspect the underlying logic of the bug to be as follows. For instance, in markdown, bold text is indicated by surrounding it with a set of two astericks. Thus, even if I "inserted" a bold text zone next to the cursor, I wouldn't be entering the "bold zone" until I actually move the cursor two spaces down. I suspect that the rich text formatting is working in some similar way.
