local table = table

-- Returns table[key][...]
-- That is, get(t, k1, k2, k3) is another way to write t[k1][k2][k3]
-- but there is no built-in way in Lua to do this in an automated way
function table.get(tab, key, ...)
  if tab == nil then return nil
  elseif select("#", ...) == 0 then
    return tab[key]
  else
    -- apply recursively
    return table.get(tab[key], ...)
  end
end

-- Sets table[key][...] to value
-- That is, _set(t, v, k1, k2, k3) is another way to write t[k1][k2][k3] = v
-- but there is no built-in way in Lua to do this in an automated way
function table.set(tab, value, key, ...)
  if value == nil then return
  elseif select("#", ...) == 0 then
    tab[key] = value
  else
    -- apply recursively
    table.set(tab[key], value, ...)
  end
end

return table