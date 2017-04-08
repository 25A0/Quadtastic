local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local libquadtastic = require(current_folder.. ".libquadtastic")

-- Utility functions that don't deserve their own module

local common = {}

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

local function escape(str)
  str = string.gsub(str, "\\", "\\\\")
  str = string.gsub(str, "\"", "\\\"")
  return str
end

local function export_table_content(handle, tab, keys)
  keys = keys or ""
  local numeric_keys = {}
  local string_keys = {}
  for k in pairs(tab) do
    if type(k) == "number" then table.insert(numeric_keys, k)
    elseif type(k) == "string" then table.insert(string_keys, k) end
  end

  table.sort(numeric_keys)
  table.sort(string_keys)

  local function export_pair(k, v)
    local new_keys
    if type(k) == "string" then
      new_keys = keys .. string.format("[\"%s\"]", escape(k))
    elseif type(k) == "number" then
      new_keys = keys .. string.format("[%s]", k)
    else
      error("Cannot handle table keys of type "..type(k))
    end
    handle("t", new_keys, " = ")
    if type(v) == "table" then
      -- Check if it is a quad table, in which case we use a simpler function
      if libquadtastic.is_quad(v) then
        export_quad(handle, v)
      else
        handle("{}\n")
        export_table_content(handle, v, new_keys)
      end
    elseif type(v) == "number" then
      handle(tostring(v))
    elseif type(v) == "string" then
      handle("\"", escape(v), "\"")
    else
      error("Cannot handle table values of type "..type(v))
    end
    handle("\n")
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
  handle("local t = {}\n")
  export_table_content(handle, tab, "")
  handle("return t\n")
end

function common.export_table_to_file(filehandle, tab)
  local function handle(...)
    filehandle:write(...)
  end
  common.export_table_content(handle, tab)
  filehandle:close()
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
