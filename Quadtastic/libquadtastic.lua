local libquadtastic = {}

function libquadtastic.is_quad(quad)
  return type(quad) == "table" and quad.x and quad.y and quad.w and quad.h
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