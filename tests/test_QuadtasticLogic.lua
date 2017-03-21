local QuadtasticLogic = require("Quadtastic.QuadtasticLogic")
local Selection = require("Quadtastic.Selection")

local app_stub = function(data)
  return {
    quadtastic = setmetatable({},{
      __index = function(_, key)
        local f = QuadtasticLogic.key
        return function(...)
          f(data, ...)
        end
      end,
    })
  }
end

local interface_stub = {
  reset_view = function(...) end,
  move_quad_into_view = function(...) end,
}

local function random_quad()
  return {
    x = math.random(0, 100),
    y = math.random(0, 100),
    w = math.random(0, 100),
    h = math.random(0, 100),
  }
end

local function test_data()
  return {
    quads = {
      foo = {
        bar = random_quad(),
        baz = random_quad(),
      },
    },
    selection = Selection(),
  }
end

-- Test rename
do
  local data = test_data()
  local logic = QuadtasticLogic.transitions(interface_stub)
  QuadtasticLogic.query = function(_, existing_key, _)
    assert(existing_key == "foo.bar")
    return "OK", "foo.new"
  end
  local quad_ref = data.quads.foo.bar
  logic.rename(app_stub, data, {data.quads.foo.bar})
  assert(not data.quads.foo.bar)
  assert(quad_ref == data.quads.foo.new)
end