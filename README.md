# Quadtastic!

This is a little LÖVE tool to handle sprite atlases while keeping your sanity.


## Usage

 - Load an image either by using the file browser or dragging the image onto the
   app's window
 - Define new quads by dragging rectangles on your spritesheet
 - Name your quads to make it easier to access them
 - When you're done, export the generated quads. This will produce a `.lua` file
   that looks something like this:

```lua
	return {
		"head" = {x = 3, y = 3, w = 16, h = 16},
		"body" = {x = 2, y = 22, w = 16, h = 32},
		"legs" = {x = 3, y = 58, w = 16, h = 16},
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
 - [ ] Name quads
 - [ ] Delete and modify existing quads
 - [ ] Name quads
 - [ ] Export defined quads as lua code
 - [ ] Detect and import existing quad definitions
 - [ ] Group quads
 - [ ] >>>>>>> TURBO-WorkflOw >>>>>
	 - [ ] Automatically reload image when it changes on disk
	 - [ ] Automatically export new quad file whenever quads are changed

# Credits and tool used

 - [m5x7](https://managore.itch.io/m5x7) and [m3x6](https://managore.itch.io/m3x6) fonts by Daniel Linssen 
 - aseprite by David Kapello https://www.aseprite.org/.
   Oh, also, the pixelated Quadtastic UI is my lousy attempt to mimic the gorgeous UI in aseprite.
 - lovedebug by kalle2990, maintained by Ranguna https://github.com/Ranguna/LOVEDEBUG
 - Nuklear for guidance on how to write IMGUI https://github.com/vurtun/nuklear
 - inspect.lua by kikito http://github.com/kikito/inspect.lua
 - affine for reverse transformation by [Minh Ngo](https://github.com/markandgo/simple-transform)
 - xform for practical ideas related to reverse transformation [pgimeno](https://love2d.org/forums/viewtopic.php?p=201884#p201884)
