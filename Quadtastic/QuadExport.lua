local QuadExport = {}

local function export_quad(filehandle, quadtable)
  filehandle:write(string.format(
    "{x = %d, y = %d, w = %d, h = %d}",
    quadtable.x, quadtable.y, quadtable.w, quadtable.h))
end

local function export_table_content(filehandle, table, indentation)
  for k, v in pairs(table) do
    filehandle:write(string.rep("  ", indentation))
    if type(k) == "string" then
      filehandle:write(string.format("%s = ", k))
    elseif type(k) ~= "number" then
      error("Cannot handle table keys of type "..type(k))
    end
    if type(v) == "table" then
      -- Check if it is a quad table, in which case we use a simpler function
      if v.x and v.y and v.w and v.h then
        export_quad(filehandle, v)
      else
        filehandle:write("{\n")
        export_table_content(filehandle, v, indentation+1)
        filehandle:write(string.rep("  ", indentation))
        filehandle:write("}")
      end
    elseif type(v) == "number" or type(v) == "string" then
      -- Not sure why this is here, but sure, let's export it
      filehandle:write(tostring(v))
    else
      error("Cannot handle table values of type "..type(v))
    end
    filehandle:write(",\n")
  end
end

QuadExport.export = function(quads, filepath_or_filehandle)
  assert(quads and type(quads) == "table")

  local filehandle
  -- Errors need to be handled upstream
  if io.type(filepath_or_filehandle) == "file" then
    filehandle = filepath_or_filehandle
  elseif io.type(filepath_or_filehandle) == nil and
    type(filepath_or_filehandle) == "string"
  then
    filehandle, more = io.open(filepath_or_filehandle, "w")
    if not filehandle then error(more) end
  else
    error("Cannot access filepath or filehandle")
  end

  filehandle:write("return {\n")
  export_table_content(filehandle, quads, 1)
  filehandle:write("}\n")
  filehandle:close()
end

return QuadExport