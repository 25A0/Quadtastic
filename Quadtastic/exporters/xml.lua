local exporter = {}
local libquadtastic = require("Quadtastic.libquadtastic")

-- This is the name under which the exporter will be listed in the menu
exporter.name = "XML"
-- This is the default file extension that will be used when the user does not
-- specify one.
exporter.ext = "xml"

local function indent(write, i)
  write(string.rep("  ", i))
end

local function export_table(write, table, ind)
  if not ind then ind = 0 end

  for k,v in pairs(table) do
    indent(write, ind)
    if libquadtastic.is_quad(v) then
      write(string.format("<quad name=\"%s\", x=%d, y=%d, w=%d, h=%d />",
                          k, v.x, v.y, v.w, v.h))
    elseif type(v) == "table" then
      write(string.format("<group name=\"%s\">\n", k))
      export_table(write, v, ind + 1)
      indent(write, ind)
      write("</group>")
    elseif type(v) == "string" then
      write(string.format("<%s>%s</%s>", k, v, k))
    elseif type(v) == "number" then
      write(string.format("<%s>%d</%s>", k, v, k))
    end

    write("\n")
  end
end


function exporter.export(write, quads)
  write("<quad_definitions>\n")
  export_table(write, quads, 1)
  write("</quad_definitions>\n")
end

return exporter
