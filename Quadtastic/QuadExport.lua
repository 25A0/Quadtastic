local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local common = require(current_folder.. ".common")

local QuadExport = {}

QuadExport.export = function(quads, exporter, filepath_or_filehandle)
  assert(quads and type(quads) == "table")
  assert(exporter and type(exporter) == "table", tostring(type(exporter)))
  assert(exporter.export and type(exporter.export) == "function")
  assert(exporter.ext and type(exporter.ext) == "string")
  assert(exporter.name and type(exporter.name) == "string")


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

  -- Insert version info into quads
  if not quads._META then quads._META = {} end
  quads._META.version = common.get_version()

  local writer = common.get_writer(filehandle)
  local success, more = pcall(exporter.export, writer, quads)
  filehandle:close()

  if not success then error(more, 0) end
end

return QuadExport