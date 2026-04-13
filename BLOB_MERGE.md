# New Feature — Merging Blobs

## Feature Overview

In a given context, be it the project root or a folder within a project, there may be many blobs containing different fragments of a draft. At some point, I might want to consolidate these blobs — perform a **blob merge**. Let's implement a way to easily do this in the app.

## Access

The sidebar has two states: collapsed and expanded. Clicking on certain buttons will *expand* the sidebar. Right now, only the **project navigator** does this. Blob merging will be implemented similarly to the navigator:

- A new button on the sidebar, permanently displayed.
- Clicking this button expands the sidebar. Clicking on the button while the sidebar is expanded collapses the sidebar.
- This new button, for the blob merging, should be mutually exclusive with the navigator; trying to expand one feature while the other one is open should close the already open feature.
- The blob merge view (the part of the sidebar that expands) should occupy the same dimensions as the navigator, and it should be visually consistent to the navigator's typography.

## Merge modes

The blob merge has two modes: (a) Basic merge & (b) Merge with new heading. The latter should be the default, as it is more useful.

### A: Basic merge

This creates a new blob, with all the selected blobs copied and pasted one after another.

### B: Merge with new heading.

This also creates a new blob. However, a few things are different:

- The user will be asked to specify a new "heading," or the title of the blob. This will be the `H1` level heading for the new blob.
- All the other headings that already existed in the blobs being merged (including the `H1` headings in the individual blobs) will be demoted by one level, such that there is only one `H1` heading present in the new blob.
- Other than that, the blobs will be copied and pasted one after another.

## Reordering & selecting

When merging blobs, the user can specify the order in which blobs should be merged. By default, blobs will be presented in whatever their `sortOrder` dictates. But the user will be presented with a list of blobs that belong to the current context, and will be able to drag and drop to reorder them.

Moreover, the user can specify *which* blobs to include and exclude in the merge; within the list of blobs, each blob will have a checkbox indicating whether it is included. 

## Merge view layout

The part of the sidebar that expands out to accomodate this new feature will have the following layout, in this order:

- Heading ("MERGE BLOBS")
- "select all" button that toggles to "deselect all" when all blobs are selected.
- A draggable list for selecting and re-ordering blobs.
- A switch to toggle between the two modes. ("New heading" & "Simple merge," the former as the default)
- A text field for the new `H1` heading (disabled if simple merge being performed)
- A checkbox for optionally deleting all merged blobs after the consolidated blob is created.
- A "Merge" button that finalizes the action

## Visual consistency

The new feature should be visually consistent to comparable features that already exist. For typography, consider the following:

- Section headings in the navigator (font style and size, all caps, `contentSecondary` color, semibold)
- Blob list also in the navigator (`contentPrimary` color)

For other parts of the feature, consider:

- Overall button behaviors in the app, wherein a clickable button's icon or font is displayed in `contentTertiary` until a mouse hovers, at which point it glows in `contentPrimary`.
- Paddings used in the navigator should also be ported over to the merge panel. Same with the background color (`sidebarBackground`).
- Drag-and-drop behavior. The project-level navigator and the dashboard has very similar drag-and-drop features, and you should stay consistent to this paradigm. For common bugs that have occured relating to drag-and-drop, see `misc_resources/DRAG_FEATURE_HELP.md` for warnings, fixes, and caveats.
