local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local Path = require(current_folder .. ".Path")

local exporters = {}

-- Creates the empty exporters directory and copies the Readme file to it.
function exporters.init(dirname)
  if not love.filesystem.exists(dirname) then
    local success = love.filesystem.createDirectory(dirname)
    assert(success)
  end

  -- Copy the template to the exporters directory
  local template_content = love.filesystem.read("res/exporter-template.lua")
  assert(template_content)
  local success = love.filesystem.write(dirname .. "/exporter-template.lua",
                                        template_content)
  assert(success)
end

-- Checks whether the given module conforms to the requirements of an exporter.
-- That is, the module needs to define the mandatory functions and fields.
function exporters.is_exporter(module)
  if not module or type(module) ~= "table" then
    return false, "No module returned."
  elseif not module.name then
    return false, "Module misses name attribute."
  elseif not module.ext then
    return false, "Module misses extension attribute."
  elseif not module.export then
    return false, "Module misses export function."
  else
    return true
  end
end

-- Scans through the files in the exporters directory and returns a list with
-- the found exporters.
function exporters.list(dirnames)
  local found_exporters = {}
  local num_found = 0
  for _,dirname in pairs(dirnames) do
    if love.filesystem.exists(dirname) then

      local files = love.filesystem.getDirectoryItems(dirname)
      for _, file in ipairs(files) do

        local _, extension = Path.split_extension(file)
        if extension == "lua" then

          -- try to load the exporter
          local load_success, more = pcall(love.filesystem.load, dirname .. "/" .. file)
          if load_success then

            -- try to run the loaded chunk
            local run_success, result = pcall(more)
            if run_success then

              local is_exporter, reason = exporters.is_exporter(result)
              if is_exporter then

                -- Check for naming conflicts
                if found_exporters[result.name] then
                  print(string.format("Exporter in %s declares a name (%s) that already exists.",
                                      file, result.name))
                else --if has no name conflict
                  found_exporters[result.name] = result
                  num_found = num_found + 1
                end

              else
                print(string.format("Module in file %s is not an exporter: %s",
                                    file, reason))
              end -- if is exporter

            else
              print("Exporter could not be executed: " .. result)
            end -- if can run

          else
            print("Could not load exporter in file " .. file ..": " .. more)
          end -- if can load

        end -- if has .lua extension
      end -- for file in dir
    else
      print("No such dir: ", dirname)
    end -- if is dir
  end -- for dirname in dirnames
  return found_exporters, num_found
end

return exporters
