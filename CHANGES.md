# Bugs and New Features

## 1. Bugs

### 1.1. Navigator reset on re-open

- **Condition:** Project (or folder therein) selected. Sidebar has been collapsed by user.
- **Bug:** When re-opening project navigator via the sidebar, the navigator shows the project selection level.
- **Fix:** The navigator should show whatever project/folder level is used in the dashboard or editor.

### 1.2. Blob order when creating new blob

- **Bug:** When creating a new blob, the blob is generated *after* the first blob in the context's order.
- **Fix:** Append new blob at the beginning of order.
- **While we're at it:** Folders are currently appended at the end of order. Make folder consistent with blobs; append at beginning.

### 1.3. Cursor location when opening editor

- **Bug:** When opening a blob and thus launching the editor, the cursor is automatically placed at the *beginning* of text.
- **What to remember:** By default, the editor does not place the cursor automatically; the user has to click on the text field before the cursor appears. We had implemented an automatic cursor appearance feature in the past.
- **Fix:** IF blob is empty, preserve current behavior. IF NOT, do not place cursor automatically.

## 2. New Features

### 2.1. Drag from dashboard to navigator

- **Current behavior:** Only blobs in the navigator can be dragged into folders in the navigator.
- **Issue:** (1) When viewing inside a folder in the dashboard, in order to move a blob into a different folder, the user has to first send it to root, find the blob back in the root dashboard, and then move it to the desired folder. (2) When organizing blobs at the project root, when the user has to move many blobs into a folder, they have to select the blob, drag it all the way to the top to find the folders, and repeat this task.
- **New feature:** The user can drag a blob card from the dashboard into a folder row in the project navigator.

### 2.2. Open last project inhabited on app launch

- **Current behavior:** When opening the app after having quit, the app defaults to the "select a project" page, with the navigator showing the project selection level.
- **New feature:** If last window had been closed while working on a specific project, the app reopens in that project.
