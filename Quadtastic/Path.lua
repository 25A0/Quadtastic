
-- Path is a module to inspect and manipulate absolute file paths.
local Path = {}

local path_sep = "/"
assert(#path_sep == 1, "Cannot use a path separator with more than one character")
local function split(path_string)
  local regex = string.format("([^%s]+)", path_sep)
  return string.gmatch(path_string, regex)
end

local function get_root(path_string)
  return string.match(path_string, "^([A-Za-z]:/)") or
         string.match(path_string, "^(/)")
end

function Path.new(path_string)
  assert(path_string and type(path_string) == "string" and #path_string > 0)

  local path = {
    root = nil, -- "/" on linux-like OSes, drive (eg 'C:/' on Windows)
    elements = {},
  }

  -- The root is either a single "/" or a drive letter, followed by ":/"
  path.root = get_root(path_string)
  if not path.root then
    error("Path string does not describe an absolute path.")
  end

  -- Remove the root from the path string
  path_string = string.sub(path_string, 1 + #path.root)

  -- initialize the path elements by splitting the path_string at the path_seps
  for e in split(path_string) do
    table.insert(path.elements, e)
  end

  setmetatable(path,
               {
                 __index = Path,
                 __tostring = function(tab)
                                return tab.root .. table.concat(tab.elements,
                                                                path_sep)
                              end,
                 __concat = Path.concat,

               })

  path:compact()
  return path
end

-- Compacts the given path by removing redundant elements, and reducing
-- navigation symbols. e.g. "foo/./bar/../baz" is reduced to "foo/baz".
function Path.compact(path)
  local i = 1
  while i <= #path.elements do
    local e = path.elements[i]
    if e == "." then
      -- Remove that element
      table.remove(path.elements, i)
    elseif e == ".." then
      table.remove(path.elements, i)
      -- make sure that "/foo/../.." is handled correctly
      if i > 1 then
        i = i - 1
        table.remove(path.elements, i)
      end
    else
      i = i + 1
    end
  end
  return path
end

local function clone(path)
  local cloned_path = Path.new("/")
  cloned_path.root = path.root
  cloned_path.elements = {}
  for _,v in pairs(path.elements) do
    table.insert(cloned_path.elements, v)
  end
  return cloned_path
end

-- Returns the relative path from base_path to path as a string.
-- It is assumed that base_path points to a directory.
-- Path can only express absolute paths, that's why it is returned as a string.
-- To turn the relative_path into a Path, use
--   local absolute_path = base_path .. relative_path
function Path.get_relative_to(path, base_path)
  -- We can only create a relative path if the two paths have the same root.
  if path.root ~= base_path.root then
    return clone(path)
  else
    local elements = {"."}
    -- Remove the elements that are common to both paths, and join up the
    -- remaining paths via "..".
    local i = 1
    local diverged = false
    while i <= #path.elements and i <= #base_path.elements and not diverged do
      -- The two paths have diverged as soon as the elements don't match any more
      diverged = path.elements[i] ~= base_path.elements[i]
      if not diverged then
        i = i + 1
      end
    end
    if not diverged and #path.elements == #base_path.elements then
      -- The two paths are identical
      return "."
    else
      -- The two paths have diverged at this index
      local diverged_at = i
      while i <= #base_path.elements do
        table.insert(elements, "..")
        i = i + 1
      end

      i = diverged_at
      while i <= #path.elements do
        table.insert(elements, path.elements[i])
        i = i + 1
      end

      return table.concat(elements, path_sep)
    end
  end
end

-- Appends the given string to the end of path.
-- You can also use the .. operator to append a string to a path table.
function Path.concat(path, str)
  assert(str and type(str) == "string", "Can only concatenate path and string")
  local new_path = clone(path)
  for e in split(str) do
    table.insert(new_path.elements, e)
  end
  new_path:compact()
  return new_path
end

-- Returns a new path that points to the parent of the given path.
function Path.parent(path)
  local parent = clone(path)
  -- Remove last element, if possible
  if #parent.elements > 0 then
    table.remove(parent.elements)
  end
  parent:compact()
  return parent
end

-- Returns the filename portion of the given path
function Path.basename(path)
  return path.elements[#path.elements] or ""
end

-- Returns the directory portion of this path.
-- Calling `Path("/foo/bar/code.c"):dirname()` returns "/foo/bar".
-- Calling `Path("/foo/bar/dir"):dirname()` also returns "/foo/bar".
function Path.dirname(path)
  return path.root .. table.concat(path.elements, path_sep, 1, #path.elements - 1)
end

-- Returns as first and second argument the filename without its extension, and
-- the extension, respectively. The extension is considered the string that
-- follows the last period in filename.
-- So, calling `Path.split_extension("/foo/bar/code.c")` returns "code", "c".
-- If filename contains no extension, then the first return value will be
-- filename, and the second return value will be the empty string "".
-- This function expects a filename, not a path. Use basename to extract the
-- filename part of a path.
function Path.split_extension(filename)
  local file, ext = string.gmatch(filename, "(.*)%.([^%.]*)")()
  return file or filename, ext or ""
end

-- Returns whether the given string is an absolute path.
-- An absolute path is anything that begins with a / or [a-zA-Z]:/
function Path.is_absolute_path(path_string)
  -- Explicitly comparing to nil so that this function returns a boolean and
  -- not some weird string value that the caller needs to interpret.
  return get_root(path_string) ~= nil
end

function Path.is_relative_path(path_string)
  return string.match(path_string, "^%./") ~= nil
end

setmetatable(Path,
             {
               __call = function(_, path_string)
                          return Path.new(path_string)
                        end,
             })

return Path