local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local common = require(current_folder.. ".common")

local QuadExport = {}

QuadExport.export = function(quads, filepath_or_filehandle)
  assert(quads and type(quads) == "table")

  local filehandle, more
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

  common.export_table_to_file(filehandle, quads)
end

return QuadExport