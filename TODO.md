# FishTxt Features and Bugs To-Do's

## 1. Images in editor

**New feature:** Be able to add images in between text in the editor, and ensure that printing works seamlessly.

**UI elements:** Add "Image" to the editor toolbar (after Quote, Ref., List). Clicking on "Image" should open a finder window to select an image. Selected image is inserted into the editor, wherever the cursor sits. Text paragraphs or headings should wrap above and below the inserted image.

**Image captioning:** Right-clicking the image after it has been inserted brings up a context menu, depending on the situation. See below for details:

1. If image has no caption, yet: "Add image caption."
2. If image already has a caption: "Edit image caption" and "Remove image caption."

Image caption should be a text field just beneath the image. The paragraph width should be smaller than the editor's text width, and also the font size recognizably smaller but legible.

**Image highlight:** Clicking on an image that has been inserted into the editor should highlight the image around its edges (but not overlaying on top of its content). In this condition, keystrokes for regular text, such as `backspace` and `Cmd+C`, should work also for the image.

**Image size:** If image file is large enough, it should be fitted to the "max image width" specified through app setttings. If image file is smaller than that, it should be fitted to its size. Either way, the image should be centered.

In the settings panel, under the "editor" section, there should be a new switch toggle for "Limit image width to half." Having this OFF should set the aforementioned "max image width" variable to be the same as the editor's text width. Having it ON should make the max image width half of the text width.

**Printing:** When printing a blob, images should be included in the output, and text should wrap above and below the image, just like in the editor. If caption is present, image and caption should be treated as a single entity when it comes to page breaks.

## 2. Remap autoscroll setting UI

**Current condition:** In the settings panel, the option for autoscroll is a drop-down menu that has "on" and "off."

**Change:** Redesign this part such that is has a switch toggle for on and off.
