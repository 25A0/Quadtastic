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
local libquadtastic = {}

function libquadtastic.is_quad(quad)
  return type(quad) == "table" and quad.x and type(quad.x) == "number" and
                                   quad.y and type(quad.y) == "number" and
                                   quad.w and type(quad.w) == "number" and
                                   quad.h and type(quad.h) == "number"
end

function libquadtastic.get_metainfo(table)
  return table["_META"] or {}
end

function libquadtastic.import_quads(table, width, height)
  local t = {}
  for k,v in pairs(table) do
    if libquadtastic.is_quad(v) then
      t[k] = love.graphics.newQuad(v.x, v.y, v.w, v.h, width, height)
    elseif type(v) == "table" then
      -- Recursively add the quads stored in this table
      t[k] = libquadtastic.import_quads(v, width, height)
    end
  end
  return t
end

local function create_palette(table, imagedata)
  local t = {}

  for k,v in pairs(table) do
    if libquadtastic.is_quad(v) then
      -- Grab the pixel color of the quad's upper left corner
      t[k] = {imagedata:getPixel(v.x, v.y)}
      -- Make the table callable to easily modify the alpha value
      setmetatable(t[k], {
        __call = function(tab, alpha)
          return {tab[1], tab[2], tab[3], alpha or tab[4]}
        end,
      })
    elseif type(v) == "table" then
      -- Recursively add the quads stored in this table
      t[k] = create_palette(v, imagedata)
    end
  end
  return t
end

function libquadtastic.import_palette(table, image)
  local imagedata
  if image:isCompressed() then
    error("Cannot currently handle compressed images")
  else
    imagedata = image:getData()
  end
  return create_palette(table, imagedata)
end

return libquadtastic
