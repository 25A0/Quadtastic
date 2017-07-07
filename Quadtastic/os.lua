local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local common = require(current_folder.. ".common")

-- OS-specific code

local os = {}

local os_string = love.system.getOS()
os.mac = os_string == "OS X"
os.win = os_string == "Windows"
os.linux = os_string == "Linux"

os.os = os.mac and "mac" or os.win and "win" or os.linux and "linux"

function os.cursors()
  local cursors = {
    arrow = love.mouse.getSystemCursor("arrow"),
    ibeam = love.mouse.getSystemCursor("ibeam"),
    move_cursor = love.mouse.getSystemCursor("sizeall"),
    hand_cursor = love.mouse.getSystemCursor("hand"),
    sizens = love.mouse.getSystemCursor("sizens"),
    sizewe = love.mouse.getSystemCursor("sizewe"),
    sizenesw = love.mouse.getSystemCursor("sizenesw"),
    sizenwse = love.mouse.getSystemCursor("sizenwse"),
  }

  if os.mac then
    -- LOVE doesn't seem to support all system cursors on MacOS.
    -- So we try to load additional cursors manually (found on
    -- http://einserver.de/blog/resources-for-cursors-in-mac-os-x)
    local basepath =
      "/System/Library/Frameworks/ApplicationServices.framework/Versions/A/"..
      "Frameworks/HIServices.framework/Versions/A/Resources/cursors/"
    local special_cursors = {
      sizenesw = {
        dict = "resizenortheastsouthwest",
        hotx = 9,
        hoty = 9,
      },
      sizenwse = {
        dict = "resizenorthwestsoutheast",
        hotx = 9,
        hoty = 9,
      },
    }
    for name,specs in pairs(special_cursors) do
      local path = basepath .. specs.dict .. "/cursor_1only_.png"
      local success, more = pcall(common.load_imagedata, path)
      if success then
        cursors[name] = love.mouse.newCursor(more, specs.hotx, specs.hoty)
      else
        print("Warning: Could not load extra cursor icon for cursor " .. name)
      end
    end
  end

  return cursors
end

-- on windows, replaces backslashes in path by slashes and removes trailing slashes
-- to work around a bug in LFS
function os.path(path)
  if os.win then
    path = string.gsub(path, "\\", "/") -- replace path separators by slashes
    path = string.gsub(path, "([^:])/$", "%1") -- remove trailing slash, except it's something like D:/
  end
  return path
end

os.pathsep = os.win and "\\" or "/"

return os