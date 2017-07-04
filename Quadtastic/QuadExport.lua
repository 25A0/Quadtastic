local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local common = require(current_folder.. ".common")

local QuadExport = {}

QuadExport.export = function(quads, exporter, filepath)
  assert(quads and type(quads) == "table")
  assert(exporter and type(exporter) == "table", tostring(type(exporter)))
  assert(exporter.export and type(exporter.export) == "function")
  assert(exporter.ext and type(exporter.ext) == "string")
  assert(exporter.name and type(exporter.name) == "string")


  local filehandle, open_err = io.open(filepath, "w")
  if not filehandle then error(open_err) end

  -- Insert version info into quads
  if not quads._META then quads._META = {} end
  quads._META.version = common.get_version()

  local writer = common.get_writer(filehandle)
  local info = {
    filepath = filepath,
  }
  local success, export_err = pcall(exporter.export, writer, quads, info)
  filehandle:close()

  if not success then error(export_err, 0) end
end

return QuadExport