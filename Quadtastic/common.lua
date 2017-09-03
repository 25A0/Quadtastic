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

local function export_quad(handle, quadtable)
  handle(string.format(
    "{x = %d, y = %d, w = %d, h = %d}",
    quadtable.x, quadtable.y, quadtable.w, quadtable.h))
end

-- Checks if a given string qualifies as a Lua Name, see "Lexical Conventions"
function common.is_lua_Name(str)
  local reserved = { ["and"] = true, ["break"] = true, ["do"] = true,
    ["else"] = true, ["elseif"] = true, ["end"] = true, ["false"] = true,
    ["for"] = true, ["function"] = true, ["if"] = true, ["in"] = true,
    ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true,
    ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true,
    ["until"] = true, ["while"] = true,
  }

  -- Names (also called identifiers) in Lua can be any string of letters,
  -- digits, and underscores, not beginning with a digit.
  -- Any reserved keywords are not valid Lua names.
  -- http://www.lua.org/manual/5.1/manual.html#2.1
  return str and not reserved[str] and
         str == string.gmatch(str, "[A-Za-z_][A-Za-z0-9_]*")()
end

-- A slow but deterministic table iterator. Can only handle string and number
-- keys.
function common.det_pairs(tab)
  local numeric_keys = {}
  local string_keys = {}

  -- Collect keys
  for k in pairs(tab) do
    if type(k) == "number" then table.insert(numeric_keys, k)
    elseif type(k) == "string" then table.insert(string_keys, k) end
  end

  -- Sort keys separately. Note that this will lead to a deterministic order
  -- even though sort is not stable; since we sort the keys of a table, we know
  -- that there are no duplicates, since each key is necessarily unique.
  table.sort(numeric_keys)
  table.sort(string_keys)

  -- So, this is going to be a bit complicated. I want det_pairs to work the
  -- same way pairs works, so the function should return the next index and the
  -- associated value each time it is called with the current index.
  -- We have the two tables above with the numeric and string keys, but that
  -- alone isn't enough to quickly find index i+1, given index i. Instead, we
  -- can build a sort of linked list. Say we have the following indices that we
  -- want to encounter in exactly this order:
  -- indices = {1, 4, "a", "c", "ce", "f", "z"}
  -- We can build a table that, under each index, contains the next index:
  --
  -- first_index = 1
  -- next_index = {
  --   [1] = 4,
  --   [4] = "a",
  --   a = "c",
  --   c = "ce",
  --   ce = "f",
  --   f = "z",
  -- }
  --
  -- Note that there is no value for key "z", since "z" is the last index. Note
  -- also that it is easy to mix number and string indices. However, we do need
  -- to store the first index separately since the table itself does not tell us
  -- where to start.

  -- By choice, we iterate over numeric keys first, and then move on to string
  -- keys.
  local first_index
  local next_index = {}
  do
    local prev_index

    for _,v in ipairs(numeric_keys) do
      if not first_index then
        first_index = v
      else
        next_index[prev_index] = v
      end
      prev_index = v
    end

    for _,v in ipairs(string_keys) do
      if not first_index then
        first_index = v
      else
        next_index[prev_index] = v
      end
      prev_index = v
    end
  end

  -- We ignore the table that is passed to this function. This function will
  -- not work with any other function anyway.
  local det_next = function(_, index)
    if not index then
      return first_index, tab[first_index]
    else
      local i = next_index[index]
      return i, tab[i]
    end
  end

  -- Return the same things pairs() would return
  return det_next, tab, nil
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

-- Clones table tab.
-- Values are deeply cloned. Can handle string and number keys.
function common.clone(tab)
  assert(type(tab) == "table")
  local clone = {}

  for k,v in pairs(tab) do
    if type(v) == "table" then
      clone[k] = common.clone(v)
    else
      clone[k] = v
    end
  end

  return clone
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
