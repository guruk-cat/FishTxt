# Drag-and-Drop in SwiftUI — The "Stuck in Air" Bug

## The Bug

When implementing drag-and-drop with `DragGesture`, items visually "stick" to the cursor and never drop. The floating drag overlay stays on screen indefinitely after the user releases the mouse.

**Root cause:** `DragGesture.onEnded` never fires.

## Why It Happens

SwiftUI ties a `DragGesture` to the specific view it is attached to. If that view is **removed from the view hierarchy** while the drag is in progress, SwiftUI silently cancels the gesture — but it does **not** call `.onEnded`. Any state you intended to clear in `.onEnded` (e.g. `draggedItemID`, `dragLocation`) is left dirty, and the overlay stays visible.

The most common way to accidentally remove the view mid-gesture:

```swift
// BAD — this removes the dragged item from the list,
// which destroys its view, which kills the gesture.
var displayItems: [Item] {
    var all = items
    all.removeAll { $0.id == draggedItemID }  // ← gesture dies here
    all.insert(ghost, at: ghostIndex)
    return all
}
```

When the `ForEach` keyed on `item.id` no longer finds the dragged item in the data, it tears down that cell's view tree, including the `DragGesture` modifier.

## The Fix

**Never remove the dragged item from its source list while a drag is active.**

Instead:
1. Keep the dragged item in the list so its view (and gesture) stays alive.
2. Insert a `.ghost` placeholder at the target position to show where the drop will land.
3. At the call site, render the dragged item at `height: 0 / opacity: 0` so it is invisible without being removed.

```swift
// GOOD
var displayItems: [Item] {
    guard let draggedID, let dragPos = all.firstIndex(where: { $0.id == draggedID }),
          let ghostIdx else { return all }
    var result = all                          // dragged item still present
    let insertAt = ghostIdx <= dragPos ? ghostIdx : ghostIdx + 1
    result.insert(.ghost, at: insertAt)       // ghost at target position
    return result
}

// In the view:
ForEach(displayItems) { item in
    if case .ghost = item {
        GhostView()
    } else {
        let isDragged = item.id == draggedItemID
        ItemView(item: item)
            .frame(height: isDragged ? 0 : nil)   // collapse, don't remove
            .clipped()
            .opacity(isDragged ? 0 : 1)
            .simultaneousGesture(dragGesture(for: item))
    }
}
```

The dragged item occupies 0 pixels of space, so it is invisible, but its view node exists in SwiftUI's tree and the gesture keeps firing.

## The Special Case: Cross-Context Drops

When a drag can move an item to a *different* list (e.g. blob from folder → root), you need the item to "visually leave" its source list while the gesture is still live. The same rule applies:

- Source list: keep the dragged item, render it `height: 0 / opacity: 0`.
- Destination list: insert a ghost to show the landing position.
- Only on `.onEnded`: actually mutate the data.

```swift
// Folder blob being dragged to root — show ghost in root list
private func displayRootBlobs(for project: Project) -> [DashboardItem] {
    var all = rootBlobs(project)
    if dragSourceFolderID != nil, let ghostIdx = ghostRootBlobIndex {
        // Show ghost in root; dragged blob stays in its folder list at height 0
        all.insert(.ghost, at: max(0, min(ghostIdx, all.count)))
    }
    return all
}

// Source folder list: dragged item stays but collapses to 0 height
private func displayFolderBlobs(folder: BlobFolder, project: Project) -> [DashboardItem] {
    let all = folderBlobs(folder, project)
    guard dragSourceFolderID == folder.id else { return all }
    // Leaving for root or another folder: keep item but don't insert a ghost here
    if hoveredFolderID != nil || ghostRootBlobIndex != nil { return all }
    // Reordering within folder: insert ghost
    ...
}
```

## Ghost Index Math

The ghost index returned by the hit-test helper is computed against the **reduced list** (items without the dragged item). This index maps directly to the `toIndex` argument of `store.moveItem`, because `moveItem` removes the source item first before inserting at `toIndex` — so the post-removal array is identical to the reduced list.

When inserting the ghost into the **full list** (which still contains the dragged item), offset by +1 if the ghost falls after the dragged item's current position:

```swift
let insertAt = ghostIdx <= dragPos ? ghostIdx : ghostIdx + 1
```

This places the ghost at the correct visual slot relative to all items.

## Coordinate Space

Always use a named coordinate space that sits **outside** the `ScrollView`. Both the `DragGesture` and the `GeometryReader` frame trackers must reference the same space. Because `geo.frame(in: .named(...))` accounts for scroll offset, the cursor position and card frames stay consistent even while the user scrolls.

```swift
VStack { ScrollView { ... } }
    .coordinateSpace(name: "myDragSpace")
    .onPreferenceChange(CardFrameKey.self) { cardFrames = $0 }
    .overlay(dragOverlay)               // rendered outside ScrollView so it's not clipped

// Inside items:
.background(
    GeometryReader { geo in
        Color.clear.preference(
            key: CardFrameKey.self,
            value: [item.id: geo.frame(in: .named("myDragSpace"))]
        )
    }
)
.simultaneousGesture(
    DragGesture(minimumDistance: 8, coordinateSpace: .named("myDragSpace"))
    ...
)
```

## Summary Checklist

Before shipping any drag feature:

- [ ] Dragged item is **never removed** from its source `ForEach` data while dragging
- [ ] Dragged item is rendered `height: 0, opacity: 0` (not `isHidden`, not removed)
- [ ] Ghost placeholder is inserted at the computed target position
- [ ] `clearDragState()` is called via `defer` in `.onEnded` so it always runs
- [ ] Named coordinate space is applied to a container **outside** the `ScrollView`
- [ ] `DragGesture` uses the same named coordinate space as the frame trackers
- [ ] Cross-context drags show a ghost in the destination list, not the source
