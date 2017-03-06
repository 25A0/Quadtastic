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