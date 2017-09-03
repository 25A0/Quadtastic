
## Quick start

 - Load an image either by dragging the image into the app's window, or via the
   menu: "Image" -> "Open Image..."
 - Define new quads by dragging rectangles on your spritesheet, using the "Create" tool
 - Name your quads to make it easier to access them
 - Select, move and resize existing quads using the "Select" tool
 - Create groups of quads to organize them hierarchically
 - When you're done, export or save the generated quads. Saving will produce a
   quadfile; a `.lua` file containing the generated quads.
   It looks something like this:
    ```lua
    return {
      _META = {
        image_path = "./sheet.png",
      },
      base = {x = 16, y = 27, w = 16, h = 8},
      bubbles = {
        {x = 2, y = 18, w = 5, h = 5},
        {x = 1, y = 25, w = 3, h = 4},
        {x = 10, y = 18, w = 5, h = 3},
        {x = 7, y = 24, w = 7, h = 6},
        {x = 3, y = 8, w = 5, h = 4},
        {x = 10, y = 11, w = 4, h = 3},
        {x = 7, y = 3, w = 6, h = 4},
      },
      lid = {x = 16, y = 7, w = 16, h = 15},
      liquid = {x = 0, y = 32, w = 3, h = 3},
      stand = {x = 32, y = 32, w = 16, h = 16},
    }
    ```
   As you expand your spritesheet, you can re-open this quadfile in Quadtastic
   to add or modify quads
 - For non-LOVE projects, you can use one of the [existing exporters](/Exporter/README.md) (e.g. JSON, XML), or you
   can also [define your own exporter](./Exporters.md). But you will need to save your project, too, if you want to
   load it again later.
 - Enable ![Turbo-Workflow](http://imgur.com/uYNOhGl.gif) to reload the
   spritesheet whenever it changes on disk, and to save and re-export the quads
   whenever you change them

---

![](http://imgur.com/VzhjLoG.png)

### Quad editor

The quad editor shows your sprite sheet and the defined quads.

 - **Move** the view vertically with your scroll wheel, and use <kbd>shift</kbd> and
   your scroll wheel to move the view horizontally.
   Two-dimensional scroll wheels, like the trackpad on your laptop, can also be
   used to move around in the editor. Alternatively, you can press and hold the
   middle mouse button to move around in the quad editor.

 - **Zoom** in and out with your scroll wheel while holding <kbd>ctrl</kbd>.

 - Quads are outlined with a white line.

 - Hovering over a quad with your mouse pointer will highlight it in the quad
   list. It will also show the name of the quad next to your mouse pointer.

### Quad list

The quad list shows the details of the defined sprites. Clicking on a quad will
focus the quad editor on this quad. Hovering over a quad will highlight its
outline in the quad editor.

 - Grouped quads are shown hierarchically. Groups can be collapsed and expanded
   by clicking the arrow next to the group name.
 - **Select** a quad by clicking on it.
 - **Select** a range of quads or groups by clicking on a quad while holding
   <kbd>shift</kbd>. This will select all quads between the clicked element and
   the previously selected element.
 - **Toggle** the selection of a quad by clicking on it while holding <kbd>ctrl</kbd>.

### Actions

#### ![](http://i.imgur.com/zUvh4j5.png) Rename
Rename the selected quad or group.

If the selected element is part of a group, you will see the group's name
prefixed to the element's name, separated by a dot.

For example, if the quad "chair" is part of the group "furniture", then you will
see "furniture.chair" in the rename dialog. When you change "furniture.chair"
to "chair" in the rename dialog, the quad "chair" will be removed from the
"furniture" group and placed at the top level of the quad hierarchy.
When you change "furniture.chair" to "dining_set.chair", then the "chair"
quad will be moved to the group "dinign_set". This group will be created if it
does not exist yet.

Numbers will be converted to numeric indices.

#### ![](http://i.imgur.com/OwKOU7V.png) Delete
Deletes the selected quad(s) or group(s). When deleting a group, all the quads
and groups inside that group will also be deleted.

#### ![](http://i.imgur.com/ps4Ju3Y.png) Sort
Sorts all of the selected quads that have a numeric index.
Those quads are sorted by their y-coordinate first and then by their x-coordinate,
so that the quad furthest to the top left will have the smallest index, and the
quad furthest to the top right will have the highest index.

#### ![](http://i.imgur.com/2jDU2WT.png) Group
Creates a new group and moves all selected quads and groups into that group.

#### ![](http://i.imgur.com/Gf88UyJ.png) Ungroup
Breaks up the selected group and moves all the elements in this group to the
next higher layer in the hierarchy. The (then) empty group is removed
afterwards.

### Tools

#### ![](http://i.imgur.com/bzg7yki.png) Select and manipulate existing quads

 - Click on a quad with the left mouse button to select it. When you hover over
   a quad, it will be displayed with a rotating dashed outline to indicate that
   this quad will be selected when you click on it.

 - You can also drag a box around the quads you want to select, using the left
   mouse button.
   A blue highlight will indicate which quads will be selected when you release
   the left mouse button.

 - By default, the currently selected quads will be deselected when you select
   new quads. Hold <kbd>shift</kbd> to add to your existing selection instead
   of replacing it.

 - Selected quads are shown with a rotating dashed outline, and are highlighted
   in the quad list.

 - Drag with the left mouse button one or more _selected_ quads to move them
   around.

 - Resize one or more _selected_ quads by dragging form their edges with the
   left mouse button. This will resize all selected quads by the same number of
   pixels.

 - Hovering over an existing quad will show its name next to your mouse pointer.

#### ![](http://i.imgur.com/5q2z1Sv.png) Create new quads

 - A white square indicates the pixel closest to your mouse pointer.

 - Drag the outline of the quad with the left mouse button.
   The current size of the new quad is displayed next to your mouse pointer.
   Release to create the quad. The newly created quad is selected and
   highlighted in the quad list.

 - Hovering over an existing quad will show its name next to your mouse pointer.

#### ![](http://i.imgur.com/rWV1Pf6.png) Automatically create quads from opaque areas

This tool detects continuous opaque areas. Starting from the pixel under your
mouse pointer, it searches for horizontally or vertically adjacent opaque pixels.
Pixels are considered opaque if they have an alpha value that is not 0.

 - A white square indicates the pixel closest to your mouse pointer.

 - Hover over an opaque area of your sprite sheet. A rotating dashed outline
   will show the detected opaque area, and its size is displayed next to your
   mouse pointer.

 - Click on an opaque area with the left mouse button to create a quad with the
   outlined dimensions. The newly created quad is selected and
   highlighted in the quad list.

#### ![](http://i.imgur.com/gJE7zv2.png) Automatically create quads by color

This tool detects continuous areas of the same color in a given rectangle, and
creates a quad for each of them. This is useful if your sprite sheet contains
a color palette.

 - A white square indicates the pixel closest to your mouse pointer.

 - Drag a rectangle using the left mouse button. A white line shows the outline
   of the dragged area. In addition to that, a dashed rotating outline is shown
   for each continuous area of the same color that was found in the dragged rectangle.
   The number of discovered areas in the dragged rectangle is shown next to your
   mouse cursor.
   Release the left mouse button to create the quads.

This tool works best if your color blobs are rectangular.

Keep in mind that lossy image compression (e.g. `jpg`) can alter colors. If this
tool detects different colors in areas you expected to have only a single color,
try using a lossless image format like `png`.

## Grid

Quadtastic draws a grid behind your sprite sheet. By default, each cell in this
grid is 8 pixels wide and 8 pixels high. This grid does not only work as a
visual guide; you can also snap quads to the grid.

 - Press and hold <kbd>alt</kbd> to snap things to the grid. In this mode,
   creating and changing quads works differently:
    - New quads created in this mode will always occupy entire grid cells.
      Their position will be a grid point, and their size will be a multiple
      of the grid size.
    - When moving quads with the select tool, their position will be set to
      the closest grid point.
    - When resizing quads with the select tool, their size will be set to
      the closest multiple of the grid size.
 - With "Edit" -> "Grid" -> "Always snap to grid", you can control whether new
   quads should always snap to the grid. While this is enabled, holding
   <kbd>alt</kbd> will temporarily disable snapping to the grid.
 - To change the grid size, go to "Edit" -> "Grid" -> "Grid size". Use one of
   the presets, or use a custom size. Quadtastic remembers your ten most
   recently used grid sizes.

## Key bindings

|                         | Windows | macOS | Linux |
| ----------------------- |:-------:|:-----:|:-----:|
  Delete selected quad(s) |  <kbd>backspace</kbd>  |  <kbd>backspace</kbd>  |  <kbd>backspace</kbd>
  Rename selected quad    |  <kbd>F2</kbd>  |  <kbd>return</kbd>  |  <kbd>F2</kbd>
  Group selected quads    |  <kbd>ctrl+g</kbd>  |  <kbd>cmd+g</kbd>  |  <kbd>ctrl+g</kbd>
  Break up selected group |  <kbd>ctrl+shift+g</kbd>  |  <kbd>cmd+shift+g</kbd>  |  <kbd>ctrl+shift+g</kbd>
  Undo                    |  <kbd>ctrl+z</kbd>  |  <kbd>cmd+z</kbd>  |  <kbd>ctrl+z</kbd>
  Redo                    |  <kbd>ctrl+shift+z</kbd>  |  <kbd>cmd+shift+z</kbd>  |  <kbd>ctrl+shift+z</kbd>
  Open                    |  <kbd>ctrl+o</kbd>  |  <kbd>cmd+o</kbd>  |  <kbd>ctrl+o</kbd>
  Save                    |  <kbd>ctrl+s</kbd>  |  <kbd>cmd+s</kbd>  |  <kbd>ctrl+s</kbd>
  Save as                 |  <kbd>ctrl+shift+s</kbd>  |  <kbd>cmd+shift+s</kbd>  |  <kbd>ctrl+shift+s</kbd>
  Export                  |  <kbd>ctrl+e</kbd>  |  <kbd>cmd+e</kbd>  |  <kbd>ctrl+e</kbd>
  New file                |  <kbd>ctrl+n</kbd>  |  <kbd>cmd+n</kbd>  |  <kbd>ctrl+n</kbd>
  Quit                    |  <kbd>alt+F4</kbd>  |  <kbd>cmd+q</kbd>  |  <kbd>ctrl+q</kbd>

 - When selecting quads in the editor, hold <kbd>shift</kbd> to add to the
   existing collection instead of replacing the selection.
 - When selecting quads in the quad list, hold <kbd>ctrl</kbd> to toggle
   the selection of the quad or group under the mouse pointer.
 - When selecting quads in the quad list, hold <kbd>shift</kbd> to create a
   range of quads in the current group.
 - Press and hold <kbd>alt</kbd> to temporarily toggle snapping to grid
