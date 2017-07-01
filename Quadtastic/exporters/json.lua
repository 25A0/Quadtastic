local exporter = {}
local libquadtastic = require("libquadtastic")

-- This is the name under which the exporter will be listed in the menu
exporter.name = "JSON"
-- This is the default file extension that will be used when the user does not
-- specify one.
exporter.ext = "json"

local function indent(write, i)
  write(string.rep("  ", i))
end

function exporter.export(write, quads, ind)
  if not ind then ind = 0 end

  for k,v in pairs(quads) do
    indent(write, ind)
    write(string.format("\"%s\": ", k))
    if libquadtastic.is_quad(v) then
      write(string.format("{\"x\":%d, \"y\": %d, \"w\": %d, \"h\": %d}",
                          v.x, v.y, v.w, v.h))
    elseif type(v) == "table" then
      write("{\n")
      exporter.export(write, v, ind + 1)
      indent(write, ind)
      write("}")
    elseif type(v) == "string" then
      write(string.format("\"%s\"", v))
    elseif type(v) == "number" then
      write(string.format("%d", v))
    end

    -- Check if we need to insert a comma
    if next(quads, k) then
      write(",")
    end
    write("\n")
  end

end

-- Check if there are tables that contain both numeric indices and string keys,
-- or if there is a table that has discontinuous numeric indices. JSON can have
-- either continuous numeric indices in form of an array or string keys in a
-- JSON object, but not both.
function exporter.can_export(quads)
  -- Of course, the quad definitions should always come as a table, but we
  -- call this function recursively with elements of that table, in which case
  -- this check makes sense.
  if type(quads) == "table" then
    -- Check for both numeric and non-numeric keys
    local has_string_keys = false
    local has_numeric_keys = false
    local last_numeric_key

    for k,v in pairs(quads) do

      if type(k) == "number" then
        -- Check whether the numeric indices are continuous
        has_numeric_keys = true
        if last_numeric_key then
          -- check if the numeric keys are continuous
          if not last_numeric_key + 1 == i then
            local range = i - last_numeric_key
            local error_missing_indices
            if range == 2 then
              error_missing_indices = string.format("Your quad definitions miss index %d.",
                                                    last_numeric_key + 1)
            else
              error_missing_indices = string.format("Your quad definitions miss indices %d through %d.",
                                                    last_numeric_key + 1, i - 1)
            end
            return false, string.format("JSON cannot handle discontinuous arrays. %s",
                                        error_missing_indices)
          end
        end
        last_numeric_key = i
      elseif type(k) == "string" then
        has_string_keys = true
      else
        error("Unexpected key of type " .. type(k))
      end
      if has_string_keys and has_numeric_keys then
        return false, "JSON cannot have both, string and numeric keys in the same table."
      end

      -- Check recursively in case the value is also a table.
      if type(v) == "table" then
        local can_export, msg = exporter.can_export(v)
        if not can_export then
          return can_export, msg
        end
      end
    end
  end
  -- If this function didn't return before for a specific reason, we can assume
  -- that this table can be exported.
  return true
end

return exporter
