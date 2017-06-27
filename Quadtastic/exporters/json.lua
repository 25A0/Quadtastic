local exporter = {}
local libquadtastic = require("libquadtastic")

-- This is the name under which the exporter will be listed in the menu
exporter.name = "JSON"
-- This is the default file extension that will be used when the user does not
-- specify one.
exporter.ext = "json"

local function indent(write, i)
  write(string.rep("  ", i))
end

function exporter.export(write, quads, ind)
  if not ind then ind = 0 end

  for k,v in pairs(quads) do
    indent(write, ind)
    write(string.format("\"%s\": ", k))
    if libquadtastic.is_quad(v) then
      write(string.format("{\"x\":%d, \"y\": %d, \"w\": %d, \"h\": %d}",
                          v.x, v.y, v.w, v.h))
    elseif type(v) == "table" then
      write("{\n")
      exporter.export(write, v, ind + 1)
      indent(write, ind)
      write("}")
    elseif type(v) == "string" then
      write(string.format("\"%s\"", v))
    elseif type(v) == "number" then
      write(string.format("%d", v))
    end

    -- Check if we need to insert a comma
    if next(quads, k) then
      write(",")
    end
    write("\n")
  end

end

return exporter
