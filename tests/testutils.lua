local table = require("Quadtastic/tableplus")

local testutils = {}

-- Returns a stub function and a function that returns how often the stub
-- function was called. If a function is given, then that function will be
-- wrapped by the stub function
function testutils.call_spy(f)
  local n = 0 -- the number of times the function was called
  local function stub(...)
    n = n + 1
    if f then return f(...) end
  end
  local function num_calls()
    return n
  end
  return stub, num_calls
end

-- Returns whether the two values are similar by value
function testutils.equals(a, b)
  if type(a) ~= type(b) then return false end
  local t = type(a)
  if not t then return true -- in case a and b are nil
  elseif t == "number" or t == "string" or t == "function" then
    return a == b
  elseif t == "table" then
    local all_keys = table.union(table.keys(a), table.keys(b))
    for _,key in ipairs(all_keys) do
      if not a[key] or not b[key] then return false end
      return testutils.equals(a[key], b[key])
    end
  else
    error("Cannot compare values of type " .. t)
  end
end

function testutils.clone(thing)
  local t = type(thing)
  if t == "table" then
    local c = {}
    for k,v in pairs(thing) do
      c[k] = testutils.clone(v)
    end
    return c
  elseif t == "thread" then
    error("Cannot clone a thread")
  elseif t == "function" then
    error("Cannot clone a function")
  else -- all other types are immutable
    return thing
  end
end

return testutils