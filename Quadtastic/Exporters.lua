local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local common = require(current_folder .. ".common")

local exporters = {}

-- Creates the empty exporters directory and copies the Readme file to it.
function exporters.init(dirname)
  if not love.filesystem.exists(dirname) then
    love.filesystem.createDirectory(dirname)
  end

  -- Copy the Readme to the exporters directory
  local readme_content = love.filesystem.read("res/exporters-readme.md")
  assert(readme_content)
  local success = love.filesystem.write(dirname .. "/Readme.md",
                                        readme_content)
  assert(success)
end

-- Tries to load an exporter from the given file name. Makes sure that the
-- exporter defines the mandatory functions and fields.
-- Returns the exporter if it was loaded successfully, returns nil otherwise.
function exporters.load(file)
  local filename, extension = common.split_extension(file)
  if extension == "lua" then
    -- try to load the exporter
    local load_success, more = pcall(love.filesystem.load, file)
    if load_success then
      -- try to run the loaded chunk
      local run_success, result = pcall(more)
      if run_success then
        if not result.name then
          print(string.format("Exporter in %s misses name attribute.", file))
        elseif not result.ext then
          print(string.format("Exporter in %s misses extension.", file))
        elseif not result.export then
          print(string.format("Exporter in %s misses export function.", file))
        else
          return result
        end
      else
        print("Exporter could not be executed: " .. result)
      end
    else
      print("Could not load exporter in file " .. file ..": " .. more)
    end
  end
end

-- Scans through the files in the exporters directory and returns a list with
-- the found exporters.
function exporters.list(dirname)
  local found_exporters = {}
  local num_found = 0
  if love.filesystem.exists(dirname) then
    local files = love.filesystem.getDirectoryItems(dirname)
    for _, file in ipairs(files) do
      local result = exporters.load(dirname .. "/" .. file)
      if result then
        if found_exporters[result.name] then
          print(string.format("Exporter in %s declares a name (%s) that already exists.",
                              file, result.name))
        else
          found_exporters[result.name] = result
          num_found = num_found + 1
        end
      end
    end -- for file in dir
  end -- if is dir
  return found_exporters, num_found
end

return exporters
