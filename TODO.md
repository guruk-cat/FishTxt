# TO-DO

## 1. Titles of blobs in the blob merge panel

**Current condition:** In the blob merge panel (via the sidebar), blobs without any headings in their content are simply listed as "Untitled." Meanwhile, in the project navigator, blobs without titles use an excerpt (e.g., first several words in the body text) in lieu of a proper title.

**Fix:** Make it so that the blob merge panel exhibits the same feature as the navigator, using a blob excerpt in lieu of a heading-based blob title. However, this excerpt, in the case of blob merging, should be treated as a "placeholder title," and should NOT affect the generated blob that results from the merge. When merging blobs with the "new heading" option toggled, the merge logic demotes all headings within blobs by one level, and puts a new H1 level heading for the final blob. The placeholder title should not be included in the generated (merged) blob; it should only affect the sidebar/panel UI.

## 2. Increase sidebar expansion width

**Current condition:** When expanding the sidebar by triggering a button on the buttons column, the sidebar expands horizontally 220pt.

**Fix:** Add an extra 50pt to the expansion width.

## 3. Update DOCS

**Current condition:** A blob outline view was implemented in the sidebar; this works just like the navigator and the merge view, via a button on the sidebar buttons column. However, `DOCS.md` was not updated after this implementation.

**Fix"** Update `DOCS.md` to include the blob outline view feature.

## 4. Transition away from hiding and archiving

**Current condition:** Blobs and folders can be "hidden" via a right-click context menu either in the dashboard or in the project navigator. This actions makes those items "read-only," and such items can be viewed via a "view hidden items" option in the project's context menu in the project selection level of the sidebar's navigator. Meanwhile, entire projects can be archived, and this is done also via the sidebar's navigator, by right-clicking a project and selecting "archive." This results in the project being read-only and appearing in a separate "archived projects" section in the project selector.

**Fix:** Remove all features related to hiding and archiving. In the future, FishTxt will use git for version control, and this is a step for preparing for that change. Do not worry about preserving data during transition; it has been manually ensured that no blobs, folders, or projects are currently archived or hidden.

## 5. Control font size via keyboard shortcuts

**Current condition:** In the settings panel, there's an option to specify the font size. The editor reacts dynamically to this setting as the user changes it.

**Fix:** Map keystrokes `Cmd +` and `Cmd -` to increasing and decreasing font size.

## 6. Closing window via keyboard shortcuts

**Current condition:** Keystroke `Cmd+W` does not do anything.

**Fix:** Map it to closing the app window (but not qutting).
