# Quadtastic!

This is a little standalone LÖVE tool to manage sprite sheets and color palettes.

![Screenshot of Quadtastic](screenshots/screenshot.png)


## Usage

 - Load an image either by using the file browser or dragging the image onto the
   app's window
 - Define new quads by dragging rectangles on your spritesheet
 - Name your quads to make it easier to access them
 - When you're done, export the generated quads. This will produce a `.lua` file
   that looks something like this:

```lua
	return {
		head = {x = 3, y = 3, w = 16, h = 16},
		body = {x = 2, y = 22, w = 16, h = 32},
		legs = {x = 3, y = 58, w = 16, h = 16},
	}
```

This allows you to import and use the quads like so:

```lua
	 -- do this once in love.load
	local quads = import_quads(require("path-to-quadfile"), 
							   image:getWidth(), image:getHeight())

	 -- do this whenever you want to draw the quads (obviously...)
	love.graphics.draw(image, quads.head, 2, 0)
	love.graphics.draw(image, quads.legs, 2, 47)
	love.graphics.draw(image, quads.body, 0, 15)
```

You can also use this tool to create color palettes. The command
`import_palette` will take the upper left pixel of each defined quad and store
its rgb value.

```lua
	-- do this once in love.load
	local palette = import_palette(require("path-to-quadfile"), image)

	-- then you can use the color like this:
	love.graphics.clear(palette.sky)
	love.graphics.setColor(palette.sun)
	love.graphics.circle("fill", 400, 100, 50)
```

## Roadmap

 - [x] Select a file
 - [x] Load the image
 - [x] Display the image
 - [x] zoom and move the image around
 - [x] Define quads
 - [x] Name quads
 - [x] Delete and modify existing quads
 - [x] Export defined quads as lua code
 - [x] Group quads
 - [x] Highlight selected and hovered quads
 - [x] Display name of quads in ImageEditor
 - [x] Use dot notation in quad names to move them to quad groups
 - [x] Scroll quad list viewport to created or modified quad
 - [x] Scroll image editor viewport to clicked quad
 - [x] Fix scroll bars not displaying in image editor
 - [x] Implement scroll bars
 - [x] Use CTRL+Mousewheel to zoom
 - [x] Use MMB to pan image
 - [ ] Drag and drop quads in the quad list to form groups
 - [x] Selectable text in input fields
 - [x] Select all text when editing quad name
 - [x] Use common keys (Return, ESC) to confirm or cancel dialogs
 - [x] Use Esc to clear selection of text or elements
 - [x] Resize dialogs automatically so that they use up as little space as possible
 - [x] Add About dialog
 - [x] Add menu to help users report bugs easily via GitHub or email
 - [ ] Distribution:
    - [x] Automatically generate change log from checked items
          in README's Roadmap. Most of the time it works every time!
    - [x] Add License (MIT)
    - [x] Licenses of used software
    - [x] Automatically put version and commit hash in plist
    - [x] MacOS
    - [ ] Windows 32 bit
    - [ ] Windows 64 bit
    - [ ] Linux
    - [x] Icon
    - [x] Show Quadtastic in title bar
    - [x] Makefile recipe for tagging releases
 - [x] Detect when an image changed on disk
 - [x] Select newly created quads to speed up workflow
 - [x] Add new quads to currently selected group, or to group of currently
       selected quad
 - [x] Keybindings to rename, delete, open, save etc.
 - [ ] Use custom file extension qua (it's lua but quads)
 - [ ] Let OS know that Quadtastic can open qua files (if that's possible with
       LOVE. <insert cheesy joke that there are no limits to what love can do>)
       (doesn't look like this is possible. At least not on MacOS...)
 - [x] Add metadata to qua file to remember which image was loaded along with it
 - [ ] Make Export button glow when quads have changed since last export
 - [x] Show confirmation dialog when the user would lose changes by loading a
       new image or quad file
 - [ ] Test palette feature in libquadtastic
 - [x] Adjust center of the viewport after zooming
 - [x] Add file browser
 - [x] Add background to text drawn next to mouse cursor for better readability
 - [x] Add "Toast"-like feature for things like successful saving
 - [x] Show a "Saved" toast when the quads were written to disk successfully
 - [x] Show size of currently drawn quad next to mouse cursor
 - [x] Show cursors position in status bar
 - [x] Save recently opened file and show them in menu
 - [x] Add line under image editor to let user know that they can drag images
       onto the window to load it
 - [x] Idle application while not in focus
 - [x] Resize overlay canvas on resize, otherwise things might break subtly
 - [x] Add text area that wraps at layout boundary automatically
 - [x] Outline quads in black and white for better contrast
 - [ ] Add toolbar with tools:
    - [x] The Create tool to create new quads
    - [x] The Select tool to select, move and resize quads
    - [ ] The Border tool to create border quads:
          The border tool creates a list of quads automatically 
    - [ ] The Strip tool to create strips of equally sized quads
 - [x] Undo/Redo history
 - [x] Allow user to drag .qua file onto window
 - [x] Export quads in consistent order. The current export method is somewhat
       random, which causes the output to change even if the quad definitions
       stayed the same
 - [ ] Overhaul dialog texts
 - [x] Move all text to separate module for better readability, easier
       localization, and easy comparison during tests
 - [ ] Fix detection of quads: Currently the application treats all tables as
       quads that have values for x, y, w, and h. This means that you cannot
       have a group that contains the entire alphabet, since that group could
       have quads named x, y, w and h. Solution: Introduce a sneaky key _type
       that identifies the type of element. Unfortunately, we will have to
       include that key in the exported quad file, since we otherwise run into
       the same problem when using the quads.
 - [ ] Make quad list prettier
 - [x] Make quad groups in quad list collapsible and expandable
 - [x] ![Turbo-Workflow](screenshots/turboworkflow.gif)
	 - [x] Automatically reload image when it changes on disk
	 - [x] Automatically export new quad file whenever quads are changed
 - [ ] Custom exporter for people who don't want to export to lua

# Credits and tools used

 - [LÖVE](https://love2d.org/), obviously
 - The [m5x7](https://managore.itch.io/m5x7) and [m3x6](https://managore.itch.io/m3x6)
   fonts by Daniel Linssen
 - [aseprite](https://www.aseprite.org/) by David Kapello.
   Oh, also, the pixelated Quadtastic UI is my lousy attempt to create something
   similar to the gorgeous UI in aseprite.
 - [luafilesystem](https://github.com/keplerproject/luafilesystem)
 - [lovedebug](https://github.com/Ranguna/LOVEDEBUG) by kalle2990, maintained by Ranguna
 - [Nuklear](https://github.com/vurtun/nuklear) for guidance on how to write IMGUI
 - affine for reverse transformation by [Minh Ngo](https://github.com/markandgo/simple-transform)
 - xform by [pgimeno](https://love2d.org/forums/viewtopic.php?p=201884#p201884)
   for practical ideas related to reverse transformation
