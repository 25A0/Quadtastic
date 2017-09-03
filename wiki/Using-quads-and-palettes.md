# Using quads and palettes

If you don't feel like reading a lot, you can also just tinker around with the
[example project](/example/).

The page **[Using Quadtastic](./Using-Quadtastic.md)**
covers how to create quads in Quadtastic and save them as a `.lua` file.
This page covers how you use the defined files in your LÖVE project.

### Accessing quads from LÖVE

Let's say that you have a quadfile in `res/quads.lua` that looks like this:

```lua
  -- Content of res/quads.lua
  return {
    head = {x = 3, y = 3, w = 16, h = 16},
    torso = {x = 2, y = 22, w = 16, h = 32},
    legs = {x = 3, y = 58, w = 16, h = 16},
  }
```

You will first need to load the content of this file. Since the quadfile is
valid Lua code, you can use `require` for that:

```lua
  -- assuming that your quads are saved in "res/quads.lua"
  local raw_quads = require("res/quads")
```

Alternatively you can use the LÖVE filesystem module:

```lua
  -- assuming that your quads are saved in "res/quads.lua"
  -- note the extra parentheses at the end, which are necessary to run the loaded file
  local raw_quads = love.filesystem.load("res/quads.lua")()
```

Or use [Cargo](https://github.com/bjornbytes/cargo):

```lua
  -- assuming that your quads are saved in "res/quads.lua"
  local res = require("cargo").init("res")
  local raw_quads = res.quads
```

Either way, this loads the raw quad definitions:

```lua
  for k, v in pairs(raw_quads) do
    print(k, v.x, v.y, v.w, v.h)
  end
  --[[
  with the example quads above, this prints:
  head  3 3 16  16
  torso  2 22 16  32
  legs  3 58 16  16
  ]]

```

#### A note on security

With all of these methods, the content of the quadfile will be **executed**.
Make sure that you only load quadfiles from trustworthy sources, or inspect
them before loading them. If you create all quadfiles yourself, then you don't
need to worry about this.

### `libquadtastic`

Quadtastic comes with a library called `libquadtastic`, which offers a few
functions that make it easier to use the defined quads and palettes in your
LÖVE project. Details about these functions are explained in the next sections.
Except for some LÖVE functions, this library has no external
dependencies.

You can download `libquadtastic` [here](/Quadtastic/libquadtastic.lua),
or use the help menu in Quadtastic to access the version of `libquadtastic` that
is guaranteed to be compatible with the version of Quadtastic that you are using.

Remember that the quadfile is basically a lua table. So, if you do not want to
use `libquadtastic`, or you need additional functionality, you can just import
the raw quads with `require`, and handle them however you like.

Keep in mind though that Quadtastic is still in development, and the format of
the quadfiles might change without warning until version 1.0 is released.

### Drawing quads

`libquadtastic` contains a function to generate a LÖVE quad object for each
quad in your quadfile:

```lua
  local libquadtastic = require("libquadtastic")

  -- do this once in love.load
  local raw_quads = require("res/quads")
  local image = love.graphics.newImage("path/to/spritesheet")
  local quads = libquadtastic.create_quads(raw_quads,
                                           image:getWidth(), image:getHeight())

   -- do this whenever you want to draw the quads
  love.graphics.draw(image, quads.head, 2, 0)
  love.graphics.draw(image, quads.legs, 2, 47)
  love.graphics.draw(image, quads.torso, 0, 15)
```

You can just as easily use them with a spritebatch:

```lua
  local libquadtastic = require("libquadtastic")

  -- do this once in love.load
  local image = love.graphics.newImage("path/to/spritesheet")
  local quads = libquadtastic.create_quads(require("path/to/quadfile"),
                                           image:getWidth(), image:getHeight())
  local spritebatch = love.graphics.newSpriteBatch(image, 1024)

   -- do this whenever you want to draw the quads
  spritebatch:add(quads.head, 2, 0)
  spritebatch:add(quads.legs, 2, 47)
  spritebatch:add(quads.torso, 0, 15)

  love.graphics.draw(spritebatch)
  spritebatch:clear()
```

### Using Palettes

You can also use this tool to create color palettes. The command
`create_palette` will take the pixel in the center of each defined quad, and
store its RGBA value.

```lua
  local libquadtastic = require("libquadtastic")
  -- do this once in love.load
  local image = love.graphics.newImage("path/to/palettesheet")
  local all_quads = require("path-to-quadfiles")
  -- assuming that the group 'palette' contains your color palette
  local palette = libquadtastic.create_palette(all_quads.palette, image)

  -- then you can use the color like this:
  love.graphics.clear(palette.sky)
  love.graphics.setColor(palette.sun)
  love.graphics.circle("fill", 400, 100, 50)
```

The colors are stored as tables containing the RGBA values in range 0-255.
These tables are callable to make it easy to change the alpha value on the fly.
That means that you can do this

```lua
  love.graphics.setColor(palette.highlight(128))
```

instead of

```lua
  local transparent_highlight = palette.highlight
  transparent_highlight[4] = 128
  love.graphics.setColor(transparent_highlight)
```
