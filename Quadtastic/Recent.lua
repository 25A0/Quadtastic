local Recent = {}

function Recent.remove(list, entry, comparator)
  -- If no comparator is specified, use default comparator
  comparator = comparator or function(a, b) return a == b end

  -- Iterate over all other elements and remove any other instances of entry
  for i,v in ipairs(list) do
    if comparator(entry, v) then
      table.remove(list, i)
    end
  end
  return list
end

-- Promote the given `entry` in the `list` of recent elements. The function
-- `comparator` compares `entry` to the elements of `list` to determine if
-- the new `entry` matches an existing element of `list`.
-- If no comparator is given, Lua's `==` is used. If `comparator` is given,
-- it should accept two arguments and return whether they are equal.
-- When the function returns, `entry` is the first element of `list`, and
-- no other element of `list` equals this `entry`, according to the `comparator`.
-- For example:
-- local list = {'A', 'B', 'C', 'D', 'E'}
-- Recent.promote(list, 'D'),
-- Now `list` contains {'D', 'A', 'B', 'C', 'E'}
function Recent.promote(list, entry, comparator)
  Recent.remove(list, entry, comparator)
  -- Now insert entry at the start of list, and shift all other elements back
  table.insert(list, 1, entry)
end

-- Truncates the given list to the given length.
-- The given list is manipulated in-place, but also returned for convenience.
function Recent.truncate(list, length)

  local len = #list
  for i = len, length + 1, -1 do
    list[len] = nil
  end

  return list
end

return Recent
