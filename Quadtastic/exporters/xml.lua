local libquadtastic = require("Quadtastic.libquadtastic")
local utf8 = require("utf8")

local exporter = {}

-- This is the name under which the exporter will be listed in the menu
exporter.name = "XML"
-- This is the default file extension that will be used when the user does not
-- specify one.
exporter.ext = "xml"

local should_escape = {
  [utf8.codepoint("\"")] = true,
  [utf8.codepoint("&")] = true,
  [utf8.codepoint("\'" )] = true,
  [utf8.codepoint("<")] = true,
  [utf8.codepoint(">")] = true,
}

local function utf8_encode(str)
  return utf8.char(string.byte(str, 1, string.len(str)))
end

-- Returns a new string in which all special characters of s are escaped,
-- according to the json spec on http://json.org/
local function escape(s)
  local escaped_s = {}
  for p, c in utf8.codes(utf8_encode(s)) do
    if should_escape[c] then
      table.insert(escaped_s, string.format("&#%d;", c))
    else
      table.insert(escaped_s, utf8.char(c))
    end
  end
  return table.concat(escaped_s)
end

local function indent(write, i)
  write(string.rep("  ", i))
end

local function xml_key(key)
  if type(key) == "string" then
    return string.format("\"%s\"", escape(key))
  elseif type(key) == "number" then
    return string.format("%d", escape(key))
  else
    error("Key of unexpected type " .. type(key))
  end
end

local function export_table(write, table, ind)
  if not ind then ind = 0 end

  for k,v in pairs(table) do
    indent(write, ind)
    if libquadtastic.is_quad(v) then
      write(string.format("<quad key=%s, x=%d, y=%d, w=%d, h=%d />",
                          xml_key(k), v.x, v.y, v.w, v.h))
    elseif type(v) == "table" then
      write(string.format("<group key=%s>\n", xml_key(k)))
      export_table(write, v, ind + 1)
      indent(write, ind)
      write("</group>")
    elseif type(v) == "string" then
      write(string.format("<string key=%s>%s</string>", xml_key(k), escape(v)))
    elseif type(v) == "number" then
      write(string.format("<number key=%s>%d</number>", xml_key(k), v))
    end

    write("\n")
  end
end


function exporter.export(write, quads)
  write("<?xml encoding='UTF-8'?>\n")
  write("<quad_definitions>\n")
  export_table(write, quads, 1)
  write("</quad_definitions>\n")
end

return exporter
