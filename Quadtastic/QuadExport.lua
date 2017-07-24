local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local common = require(current_folder.. ".common")
local Path = require(current_folder.. ".Path")

local QuadExport = {}

QuadExport.export = function(quads, exporter, filepath)
  assert(quads and type(quads) == "table")
  assert(exporter and type(exporter) == "table", tostring(type(exporter)))
  assert(exporter.export and type(exporter.export) == "function")
  assert(exporter.ext and type(exporter.ext) == "string")
  assert(exporter.name and type(exporter.name) == "string")

  -- Use clone of quads table instead of the original one
  quads = common.clone(quads)

  local filehandle, open_err = io.open(filepath, "w")
  if not filehandle then error(open_err) end

  if not quads._META then quads._META = {} end

  -- Insert version info into quads
  quads._META.version = common.get_version()

  -- Replace the path to the image by a path name relative to the parent dir of
  -- `filepath`. We use the parent dir since filepath points to the file that
  -- the quads will be exported to.
  if quads._META.image_path then
    assert(Path.is_absolute_path(filepath))
    local basepath = Path(filepath):parent()
    assert(Path.is_absolute_path(quads._META.image_path))
    local rel_path = Path(quads._META.image_path):get_relative_to(basepath)
    quads._META.image_path = rel_path
  end

  local writer = common.get_writer(filehandle)
  local info = {
    filepath = filepath,
  }
  local success, export_err = pcall(exporter.export, writer, quads, info)
  filehandle:close()

  if not success then error(export_err, 0) end
end

return QuadExport