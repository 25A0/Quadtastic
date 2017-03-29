-- Utility functions that don't deserve their own module

local common = {}

-- Load imagedata from outside the game's source and save folder
function common.load_imagedata(filepath)
  local filehandle, err = io.open(filepath, "rb")
  if err then
    error(err)
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
      handle(string.format("%s = ", k))
    elseif type(k) ~= "number" then
      error("Cannot handle table keys of type "..type(k))
    end
    if type(v) == "table" then
      -- Check if it is a quad table, in which case we use a simpler function
      if v.x and v.y and v.w and v.h then
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
