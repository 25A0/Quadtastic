local libquadtastic = require("libquadtastic")
local common = require("common")
local utf8 = require("utf8")

local exporter = {}

-- This is the name under which the exporter will be listed in the menu
exporter.name = "JSON"
-- This is the default file extension that will be used when the user does not
-- specify one.
exporter.ext = "json"

local should_escape = {
  [utf8.codepoint("\"")] = true,
  [utf8.codepoint("\\")] = true,
  [utf8.codepoint("/" )] = true,
  [utf8.codepoint("\b")] = true,
  [utf8.codepoint("\f")] = true,
  [utf8.codepoint("\n")] = true,
  [utf8.codepoint("\r")] = true,
  [utf8.codepoint("\t")] = true,
}

local function utf8_encode(str)
  return utf8.char(string.byte(str, 1, string.len(str)))
end

-- Returns a new string in which all special characters of s are escaped,
-- according to the json spec on http://json.org/
local function escape(s)
  local escaped_s = {}
  for p, c in utf8.codes(utf8_encode(s)) do
    if should_escape[c] then table.insert(escaped_s, "\\") end
    table.insert(escaped_s, utf8.char(c))
  end
  return table.concat(escaped_s)
end

local function indent(write, i)
  write(string.rep("  ", i))
end

function exporter.export(write, quads, info, ind)
  if not ind then ind = 0 end

  if libquadtastic.is_quad(quads) then
    write(string.format("{\"x\":%d, \"y\": %d, \"w\": %d, \"h\": %d}",
                        quads.x, quads.y, quads.w, quads.h))
  elseif type(quads) == "table" then
    -- We need to distinguish between JSON arrays and objects. The function
    -- `can_export` made sure that all tables have either string or numeric
    -- indices, so we can determine whether a given table should be an array
    -- or an object by looking at the type of the first key.
    -- Note that the type can be either "string", "number", or "nil". For Lua
    -- tables with "string" keys, a JSON object will be created. For "number"
    -- keys, an array will be created. If the key type is "nil", then the table
    -- is empty. In this case we simply produce an empty array ("[]").
    local keytype = type(next(quads))

    -- Opening token
    if keytype == "string" then -- start a JSON object
      write("{\n")
    else -- start an array
      write("[\n")
    end

    local det_next = common.det_pairs(quads)
    for k,v in det_next, quads do
      indent(write, ind + 1)

      if keytype == "string" then
        write(string.format("\"%s\": ", escape(k)))
      end
      exporter.export(write, v, info, ind + 1)

      -- Check if we need to insert a comma
      if det_next(quads, k) then
        write(",")
      end
      write("\n")
    end
    indent(write, ind)

    -- Closing token
    if keytype == "string" then -- complete a JSON object
      write("}")
    else -- complete an array
      write("]")
    end

  elseif type(quads) == "string" then
    write(string.format("\"%s\"", escape(quads)))
  elseif type(quads) == "number" then
    write(string.format("%d", quads))
  elseif type(quads) == "boolean" then
    write(string.format("%s", quads))
  elseif type(quads) == "nil" then
    write("null")
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

    -- This iterator does not need to be deterministic, so we might as well use
    -- the fast default iterator.
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
