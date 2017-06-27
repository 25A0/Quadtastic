local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local S = require(current_folder .. ".strings")
local common = require(current_folder .. ".common")

local exporters = {}

-- Creates the empty exporters directory and copies the Readme file to it.
function exporters.init()
  if not love.filesystem.exists(S.exporters_dirname) then
    love.filesystem.createDirectory(S.exporters_dirname)
  end

  -- Copy the Readme to the exporters directory
  local readme_content = love.filesystem.read("res/exporters-readme.md")
  assert(readme_content)
  local success = love.filesystem.write(S.exporters_dirname .. "/Readme.md",
                                        readme_content)
  assert(success)
end

-- Scans through the files in the exporters directory and returns a list with
-- the found exporters.
function exporters.list()
  local found_exporters = {}
  if love.filesystem.exists(S.exporters_dirname) then
    local files = love.filesystem.getDirectoryItems(S.exporters_dirname)
    for _, file in ipairs(files) do
      local filename, extension = common.split_extension(file)
      if extension == "lua" then
        -- try to load the exporter
        local load_success, more = pcall(love.filesystem.load, S.exporters_dirname .. "/" .. file)
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
            elseif found_exporters[result.name] then
              print(string.format("Exporter in %s declares a name (%s) that already exists.",
                                  file, result.name))
            else
              found_exporters[result.name] = result
            end
          else
            print("Exporter could not be executed: " .. result)
          end
        else
          print("Could not load exporter in file " .. file ..": " .. more)
        end
      end
    end
  end
  return found_exporters
end

return exporters
