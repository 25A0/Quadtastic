--[[
https://www.github.com/25a0/Quadtastic

Copyright (c) 2017 Moritz Neikes

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]



-- -------------------------------------------------------------------------- --
--    MORE DOCUMENTATION IS AVAILABLE ON https://github.com/25a0/Quadtastic   --
-- -------------------------------------------------------------------------- --

local libquadtastic = {}

-- Decides whether the given value is a valid quad.
function libquadtastic.is_quad(quad)
  return type(quad) == "table" and quad.x and type(quad.x) == "number" and
                                   quad.y and type(quad.y) == "number" and
                                   quad.w and type(quad.w) == "number" and
                                   quad.h and type(quad.h) == "number"
end

function libquadtastic.get_metainfo(table)
  return table["_META"] or {}
end

-- Creates LOVE quads from the raw quads that are defined in the given table.
-- width and height are the dimensions of the spritesheet for which the quads
-- are defined.
-- Returns a new table that is structured equally to the input table, but
-- contains Quad objects instead of the raw quads.
function libquadtastic.create_quads(table, width, height)
  local t = {}
  for k,v in pairs(table) do
    if libquadtastic.is_quad(v) then
      t[k] = love.graphics.newQuad(v.x, v.y, v.w, v.h, width, height)
    elseif type(v) == "table" then
      -- Recursively add the quads stored in this table
      t[k] = libquadtastic.create_quads(v, width, height)
    end
  end
  return t
end

-- Creates a color palette from the quads that are defined in the given table.
-- Returns a new table which contains the RGBA value of the upper left corner of
-- each defined quad in the input table.
-- The defined colors are stored as a table, containing the R, G, B and A
-- component of the color at index 1 through 4. Furthermore, each color is
-- "callable", which makes it easier to change the alpha value on the fly.
function libquadtastic.create_palette(table, image)

  local function create_palette(tab, imagedata)
    local palette = {}

    for k,v in pairs(tab) do
      if libquadtastic.is_quad(v) then
        -- Grab the pixel color of the quad's upper left corner
        palette[k] = {imagedata:getPixel(v.x, v.y)}
        -- Make the table callable to easily modify the alpha value
        setmetatable(palette[k], {
          __call = function(t, alpha)
            return {t[1], t[2], t[3], alpha or t[4]}
          end,
        })
      elseif type(v) == "table" then
        -- Recursively add the quads stored in this table
        palette[k] = create_palette(v, imagedata)
      end
    end
    return palette
  end

  local imagedata
  if image:isCompressed() then
    error("Cannot currently handle compressed images")
  else
    imagedata = image:getData()
  end
  return create_palette(table, imagedata)
end

return libquadtastic
