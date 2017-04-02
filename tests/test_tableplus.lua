local table = require("Quadtastic.tableplus")

do
  local t = {
    foo = {
      bar = {
        boo = {
          fud = 42
        }
      }
    }
  }
  -- Get existing value
  assert(table.get(t, "foo", "bar", "boo", "fud") == 42)
  -- Set new value
  table.set(t, 3.14, "foo", "bar", "pi")
  assert(table.get(t, "foo", "bar", "pi") == 3.14)
  -- Replace existing value
  table.set(t, 43, "foo", "bar", "boo", "fud")
  assert(table.get(t, "foo", "bar", "boo", "fud") == 43)
end

do
  local t = {
    foo = {
      bar = {
        {
          deadend = 1234
        },
        boo = {
          fud = 42,
        }
      }
    }
  }
  local expected = {"foo", "bar", "boo", "fud"}
  local found = {table.find_key(t, 42)}
  assert(#expected == #found)
  for i=1,#expected do
    assert(expected[i] == found[i])
  end
  assert(table.get(t, table.find_key(t, 42)) == 42)
end

-- Test mixed numeric and string keys
do
  local t = {
    foo = {
      {
        boo = {
          fud = 43,
        }
      },
      {
        boo = {
          fud = 42,
        }
      }
    }
  }
  local expected = {"foo", 2, "boo", "fud"}
  local found = {table.find_key(t, 42)}
  assert(#expected == #found)
  for i=1,#expected do
    assert(expected[i] == found[i])
  end
  table.set(t, 45, table.find_key(t, 43))
  assert(table.get(t, table.find_key(t, 45)) == 45)
end


-- Test keys
do
  local k = {"this is a", "table"}
  local t = {
    foo = 42,
    3,
    16,
  }
  t[k] = "foo"
  local expected = {"foo", 1, 2, k}
  local found = table.keys(t)
  assert(#expected == #found)
  -- We cannot make assumptions about the order in which they are returned
  local function equal_content(t1, t2)
    for _,v1 in pairs(t1) do
      local found = false
      for _,v2 in pairs(t2) do
        if v1 == v2 then found = true; break end
      end
      if not found then return false end
    end
    return true
  end

  assert(equal_content(expected, found))
end

-- Test values
do
  local k = {"this is a", "table"}
  local t = {
    foo = 42,
    3,
    16,
    bar = k,
  }
  t[k] = "foo"
  local expected = {42, 3, 16, "foo", k}
  local found = table.values(t)
  assert(#expected == #found)
  -- We cannot make assumptions about the order in which they are returned
  local function equal_content(t1, t2)
    for _,v1 in pairs(t1) do
      local found = false
      for _,v2 in pairs(t2) do
        if v1 == v2 then found = true; break end
      end
      if not found then return false end
    end
    return true
  end

  assert(equal_content(expected, found))
end

-- Test union
do
  local a = {1, 2, 3}
  local b = {2, 3, 4}
  local union = table.union(a, b)
  assert(#union == 4)
  local seen = {}
  for _,v in pairs(union) do
    seen[v] = (seen[v] or 0) + 1
  end
  assert(seen[1] == 1)
  assert(seen[2] == 1)
  assert(seen[3] == 1)
  assert(seen[4] == 1)
end
