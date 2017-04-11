## Changelog

### Planned

 - Add palette tool that creates a quad for each unique color in the
   selected region, and then asks for a palette name
 - Use relative paths in quadfile's metadata if possible
 - Show overview of keybindings

### Unreleased

 - Quadfiles are saved with a neat, compact layout again where possible

### Release 0.4.2, 2017-04-10

[Download](https://github.com/25A0/Quadtastic/releases/tag/0.4.2)

 - Update README
 - Make sure that importing palettes will still work in LOVE 0.11
 - Add Makefile target to push builds to itch.io
 - Add license to libquadtastic since it will likely be used separately from
   the rest of the codebase
 - Add menu item to copy current libquadtastic version to clipboard
 - Add example project
 - Add libquadtastic as distribution target

### Release 0.4.1, 2017-04-08

[Download](https://github.com/25A0/Quadtastic/releases/tag/0.4.1)

 - Remove roadmap from README and keep track of changes in changelog.md

### Release 0.4.0, 2017-04-08

[Download](https://github.com/25A0/Quadtastic/releases/tag/0.4.0)

 - Distribution:
    - Windows 32 bit
    - Linux (works if lfs is installed with luarocks)
 - Outline quads in black and white for better contrast
 - Fix detection of quads: Currently the application treats all tables as
   quads that have values for x, y, w, and h. This means that you cannot
   have a group that contains the entire alphabet, since that group could
   have quads named x, y, w and h. Solution: Make sure that the values of
   the x, y, w and h attributes are numeric.
 - Fix error handling when image cannot be loaded
 - Colors in Palette are callable tables to easily change the alpha values
 - Improve hitbox size to make it easier to move small quads around
 - When saving, add a default extension when the user doesn't specify one
 - When renaming quads, treat numbers as numeric indices
 - When saving for the first time, open file browser at location of loaded image

### Release 0.3.0, 2017-04-06

[Download](https://github.com/25A0/Quadtastic/releases/tag/0.3.0)

 - Add About dialog
 - Add menu to help users report bugs easily via GitHub or email
 - Add License (MIT)
 - Add acknowledgement dialog with licenses of used software
 - Show confirmation dialog when the user would lose changes by loading a
   new image or quad file
 - Add line under image editor to let user know that they can drag images
   onto the window to load it
 - Undo/Redo history
 - Allow user to drag .qua file onto window
 - Move all text to separate module for better readability, easier
   localization, and easy comparison during tests
 - Turbo-Workflow
     - Automatically reload image when it changes on disk
     - Automatically export new quad file whenever quads are changed

### Release 0.2.0, 2017-03-29

[Download](https://github.com/25A0/Quadtastic/releases/tag/0.2.0)

 - Selectable text in input fields
 - Select all text when editing quad name
 - Use common keys (Return, ESC) to confirm or cancel dialogs
 - Use Esc to clear selection of text or elements
 - Resize dialogs automatically so that they use up as little space as possible
 - Automatically generate change log from checked items
   in README's Roadmap. Most of the time it works every time!
 - Automatically put version and commit hash in plist
 - Icon
 - Show Quadtastic in title bar
 - Makefile recipe for tagging releases
 - Detect when an image changed on disk
 - Select newly created quads to speed up workflow
 - Add new quads to currently selected group, or to group of currently
 - Keybindings to rename, delete, open, save etc.
 - Add metadata to qua file to remember which image was loaded along with it
 - Adjust center of the viewport after zooming
 - Add file browser
 - Add background to text drawn next to mouse cursor for better readability
 - Add "Toast"-like feature for things like successful saving
 - Show a "Saved" toast when the quads were written to disk successfully
 - Show size of currently drawn quad next to mouse cursor
 - Show cursors position in status bar
 - Save recently opened file and show them in menu
 - Idle application while not in focus
 - Resize overlay canvas on resize, otherwise things might break subtly
 - Add text area that wraps at layout boundary automatically
 - The Create tool to create new quads
 - The Select tool to select, move and resize quads
 - Export quads in consistent order. The previous export method was somewhat
   random, which causes the output to change even if the quad definitions
   stayed the same

### Release 0.1.0, 2017-03-20

First versioned commit.

[Download](https://github.com/25A0/Quadtastic/releases/tag/0.1.0)

Features implemented so far:

 - Select a file
 - Load the image
 - Display the image
 - zoom and move the image around
 - Define quads
 - Name quads
 - Delete and modify existing quads
 - Export defined quads as lua code
 - Detect and import existing quad definitions
 - Group quads
 - Highlight selected and hovered quads
 - Display name of quads in ImageEditor
 - Use dot notation in quad names to move them to quad groups
 - Scroll quad list viewport to created or modified quad
 - Scroll image editor viewport to clicked quad
 - Fix scroll bars not displaying in image editor
 - Implement scroll bars
 - Use CTRL+Mousewheel to zoom
 - Use MMB to pan image
 - Make quad groups in quad list collapsible and expandable
