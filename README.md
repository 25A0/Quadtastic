<h1 align="center">Quadtastic!</h1>

<p align="center">
  A little standalone tool to manage sprite sheets and color palettes for
  <a href="https://www.love2d.org">LÖVE</a> projects.
</p>

<p align="center">
  <img src="screenshots/screenshot.png" alt="Screenshot of Quadtastic">
</p>

<p align="center">
  <a href="https://25a0.itch.io/quadtastic">
    <img src="res/download.png" alt="Download on itch.io">
  </a>
</p>

<p align="center">
  <a href="https://github.com/25a0/Quadtastic/wiki">
    <img src="http://imgur.com/Kkquk1h.png" alt="Documentation">
  </a>
</p>

## Features

 - Create quads straight on your spritesheet -- no need to ever type out coordinates again
 - Keep your quads neatly organized by giving them descriptive names and grouping them
 - Move and resize existing quads
 - Use the wand tool to create quads from opaque areas automatically
 ![Using the wand tool](screenshots/wand.gif)
 - Use the palette tool to create quads from areas that have the same color
 ![Using the palette tool](screenshots/palette.gif)

## Download

You can find executables of Quadtastic for Windows and OS X [on itch.io](https://25a0.itch.io/quadtastic), as well as a cross-platform `.love` archive.

While the executable versions should run out of the box, **the `.love` version
requires [LuaFileSystem](keplerproject.github.io/luafilesystem/)**.
If you have [luarocks](https://luarocks.org/) installed, you can install LuaFileSystem with
```
  luarocks install luafilesystem
```

## [Changelog](./changelog.md)

## Credits and tools used

 - [LÖVE](https://love2d.org/)
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
