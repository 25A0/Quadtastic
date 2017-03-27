local unpack = unpack or table.unpack

local fun = {}

-- Applies the given function f to each element of the table t in-place
function fun.map(f, t)
  for i,v in ipairs(t) do
    t[i] = f(v)
  end
  return t
end

-- Returns whether one or more of the values in table t pass the given filter
function fun.any(filter, t)
  for _,v in ipairs(t) do
    if filter(v) then return true end
  end
  return false
end

-- Returns whether all of the values in table t pass the given filter
function fun.all(filter, t)
  for _,v in ipairs(t) do
    if not filter(v) then return false end
  end
  return true
end

-- Creates a new table that contains only the values in t that pass the given
-- filter
function fun.filter(filter, t)
  local filtered = {}
  for _,v in ipairs(t) do
    if filter(v) then table.insert(filtered, v) end
  end
  return filtered
end

-- Partially applies the given arguments to the given function
function fun.partial(f, ...)
  -- there is no way around creating a function for the varargs AFAIK
  local partial_args = {...}

  -- Hard-code some options to get faster functions
  local num_args = #partial_args

  if num_args == 0 then
    return f
  elseif num_args == 1 then
    return function(...) return f(partial_args[1], ...) end
  elseif num_args == 2 then
    return function(...)
      return f(partial_args[1], partial_args[2], ...)
    end
  elseif num_args == 3 then
    return function(...)
      return f(partial_args[1], partial_args[2], partial_args[3], ...)
    end
  elseif num_args == 4 then
    return function(...)
      return f(partial_args[1], partial_args[2], partial_args[3],
               partial_args[4], ...)
    end
  elseif num_args == 5 then
    return function(...)
      return f(partial_args[1], partial_args[2], partial_args[3],
               partial_args[4], partial_args[5], ...)
    end
  elseif num_args == 6 then
    return function(...)
      return f(partial_args[1], partial_args[2], partial_args[3],
               partial_args[4], partial_args[5], partial_args[6], ...)
    end
  elseif num_args == 7 then
    return function(...)
      return f(partial_args[1], partial_args[2], partial_args[3],
               partial_args[4], partial_args[5], partial_args[6],
               partial_args[7], ...)
    end
  elseif num_args == 8 then
    return function(...)
      return f(partial_args[1], partial_args[2], partial_args[3],
               partial_args[4], partial_args[5], partial_args[6],
               partial_args[7], partial_args[8], ...)
    end
  else
    return function(...)
      -- Assemble complete list of arguments
      for i,v in ipairs({...}) do
        partial_args[num_args + i] = v
      end
      return f(unpack(partial_args))
    end
  end
end

return fun