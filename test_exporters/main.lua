local default_test_cases = require("export_test_cases")
local common = require("Quadtastic.common")
local exporters = require("Quadtastic.exporters")
local libquadtastic = require("Quadtastic.libquadtastic")

local test_exporter = {}

-- Test whether the exporter declares that it can export the specified
-- project, and in that case test that it can in fact export the project.
-- If expected is not null, check that the produced output matches expected.
local function test(exporter, project, expected)
  -- Check whether the exporter declares can_export. If not, assume that it
  -- can export all projects.
  if exporter.can_export then
    local success, more = pcall(exporter.can_export, project)
    if success then
      if not more then
        -- The exporter declared that it cannot export this project, and
        -- that's okay. It is honest and it knows its limits.
        -- Good job, little exporter :)
        return true
      end
    else
      -- The exporter's can_export function crashed while handling that test
      -- case.
      print("The function can_export could not handle the following test case:")
      print(common.serialize_table(project))
      print("The following error was encountered:")
      print(more)
      return false
    end
  end

  -- The produced output will be accumulated in this table
  local output = {}
  local function writer(...)
    for _,v in ipairs({...}) do
      table.insert(output, v)
    end
  end

  -- At this point we know that the exporter is supposedly able to handle the
  -- project.
  local success, more = pcall(exporter.export, writer, project)
  if success then
    if expected then
      local concatenated_output = table.concat(output)
      -- Check that the produced output matches what was expected
      local matches = expected == concatenated_output
      if matches then return true
      else
        print("The generated output did not match the expected output.")
        print("Generated:")
        print(concatenated_output)
        print("Expected:")
        print(expected)
        print("The project that was passed to the exporter:")
        print(common.serialize_table(project))
        return false
      end
    else
      -- The fact that the exporter didn't crash while handling this project
      -- is enough to make this count as a passed test.
      return true
    end
  else
    -- The exporter's export function crashed while handling that test case.
    print("The function export could not handle the following test case:")
    print(common.serialize_table(project))
    print("The following error was encountered:")
    print(more)
    return false
  end
  assert(false) -- Should be unreachable
end

-- Test the given exporter by letting it export the default test cases and
-- the test cases specifically provided by that exporter.
function test_exporter.test_exporter(exporter)
  -- Test the default test cases
  for k,v in pairs(default_test_cases) do
    print(string.format("Testing test case %s.", k))
    test(exporter, v[1], v[2])
  end

  if exporter.test_cases then
    -- Test the test cases provided by the exporter
    for k,v in pairs(exporter.test_cases) do
      print(string.format("Testing test case %s.", k))
      test(exporter, v[1], v[2])
    end
  end

end

function love.load(arg)
  local function print_usage()
    print(string.format("Usage: %s <path-to-exporter> [...]", arg[0]))
  end

  -- Check if called from command line with exporter as argument
  if arg then
    -- If no command line arguments are given, print some usage information
    if not arg[2] then
      print_usage()
    else
      for i,file in ipairs(arg) do
        if i > 1 then -- this skips special fields in arg that we don't want

          -- Load the file
          local chunk, more = loadfile(file)
          if chunk then

            -- Run the chunk
            local run_success, result = pcall(chunk)
            if run_success then

              -- Check that the module is a valid exporter
              local is_exporter, reason = exporters.is_exporter(result)
              if is_exporter then
                print(string.format("Testing exporter %s in file %s",
                                    result.name, file))
                test_exporter.test_exporter(result)
              else
                print(string.format("The module in file %s is not a valid exporter:\n%s",
                                    file, reason))
              end -- if is exporter

            else
              print(string.format("Could not run file %s:\n%s", file, result))
            end -- if could run

          else
            print(string.format("Could not load file %s:\n%s", file, more))
          end -- if could load

        end -- if i > 0
      end -- for each arg
    end -- if not arg[1]
  end -- if arg
  os.exit(0)
end
