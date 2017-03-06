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
