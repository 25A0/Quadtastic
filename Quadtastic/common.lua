local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local libquadtastic = require(current_folder.. ".libquadtastic")

-- Utility functions that don't deserve their own module

local common = {}

function common.trim_whitespace(s)
  -- Trim leading whitespace
  s = string.gmatch(s, "%s*(%S[%s%S]*)")()
  -- Trim trailing whitespace
  s = string.gmatch(s, "([%s%S]*%S)%s*")()
  return s
end

function common.get_version()
  local version_info = love.filesystem.read("res/version.txt")
  if version_info then
    return common.trim_whitespace(version_info)
  else
    return "Unknown version"
  end
end

function common.get_edition()
  local edition_info = love.filesystem.read("res/edition.txt")
  if edition_info then
    return common.trim_whitespace(edition_info)
  end
end

-- Load imagedata from outside the game's source and save folder
function common.load_imagedata(filepath)
  local filehandle, err = io.open(filepath, "rb")
  if err then
    error(err, 0)
  end
  local filecontent = filehandle:read("*a")
  filehandle:close()
  return love.image.newImageData(
    love.filesystem.newFileData(filecontent, 'img', 'file'))
end

-- Load an image from outside the game's source and save folder
function common.load_image(filepath)
  local imagedata = common.load_imagedata(filepath)
  return love.graphics.newImage(imagedata)
end

-- Split a filepath into the path of the containing directory and a filename.
-- Note that a trailing slash will result in an empty filename
function common.split(filepath)
  local dirname, basename = string.gmatch(filepath, "(.*/)([^/]*)")()
  return dirname, basename
end

-- Returns the filename without extension as the first return value, and the
-- extension as the second return value
function common.split_extension(filename)
  return string.gmatch(filename, "(.*)%.([^%.]*)")()
end

local function export_quad(handle, quadtable)
  handle(string.format(
    "{x = %d, y = %d, w = %d, h = %d}",
    quadtable.x, quadtable.y, quadtable.w, quadtable.h))
end

-- Checks if a given string qualifies as a Lua Name, see "Lexical Conventions"
function common.is_lua_Name(str)
  -- Names (also called identifiers) in Lua can be any string of letters,
  -- digits, and underscores, not beginning with a digit.
  -- http://www.lua.org/manual/5.1/manual.html#2.1
  return str and str == string.gmatch(str, "[A-Za-z_][A-Za-z0-9_]*")()
end

local function escape(str)
  str = string.gsub(str, "\\", "\\\\")
  str = string.gsub(str, "\"", "\\\"")
  return str
end

local function export_table_content(handle, tab, indentation)
  local numeric_keys = {}
  local string_keys = {}
  for k in pairs(tab) do
    if type(k) == "number" then table.insert(numeric_keys, k)
    elseif type(k) == "string" then table.insert(string_keys, k) end
  end

  table.sort(numeric_keys)
  table.sort(string_keys)

  local function export_pair(k, v)
    handle(string.rep("  ", indentation))
    if type(k) == "string" then
      if common.is_lua_Name(k) then
        handle(string.format("%s = ", k))
      else
        handle(string.format("[\"%s\"] = ", escape(k)))
      end
    elseif type(k) ~= "number" then
      error("Cannot handle table keys of type "..type(k))
    end
    if type(v) == "table" then
      -- Check if it is a quad table, in which case we use a simpler function
      if libquadtastic.is_quad(v) then
        export_quad(handle, v)
      else
        handle("{\n")
        export_table_content(handle, v, indentation+1)
        handle(string.rep("  ", indentation))
        handle("}")
      end
    elseif type(v) == "number" then
      handle(tostring(v))
    elseif type(v) == "string" then
      handle("\"", v, "\"")
    elseif type(v) == "boolean" then
      handle(tostring(v))
    else
      error("Cannot handle table values of type "..type(v))
    end
    handle(",\n")
  end

  for _, k in ipairs(numeric_keys) do
    local v = tab[k]
    export_pair(k, v)
  end

  for _, k in ipairs(string_keys) do
    local v = tab[k]
    export_pair(k, v)
  end
end

function common.export_table_content(handle, tab)
  handle("return {\n")
  export_table_content(handle, tab, 1)
  handle("}\n")
end

function common.export_table_to_file(filehandle, tab)
  local writer = common.get_writer(filehandle)
  common.export_table_content(writer, tab)
  filehandle:close()
end

-- The name of the "exporter" that exports the quads as a quadfile.
common.reserved_name_save = "Quadtastic quadfile"

-- This is a table that exposes the default exporter in a way that is compatible
-- with custom exporters.
common.exporter_table = {
  name = common.reserved_name_save,
  ext = "lua",
  export = common.export_table_content,
}

function common.get_writer(filehandle)
  return function(...)
    filehandle:write(...)
  end
end

function common.serialize_table(tab)
  local strings = {}
  local function handle(...)
    for _,string in ipairs({...}) do
      table.insert(strings, string)
    end
  end
  common.export_table_content(handle, tab)
  return table.concat(strings)
end

return common
