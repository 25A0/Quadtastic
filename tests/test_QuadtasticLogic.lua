-- stub for love.system.getOS()
love = { system = { getOS = function() return "OS X" end},
         filesystem = { getUserDirectory = function() return "/" end,
                        read = function() return nil end}
       }
local QuadtasticLogic = require("Quadtastic.QuadtasticLogic")
local Selection = require("Quadtastic.Selection")
local History = require("Quadtastic.History")
local testutils = require("tests.testutils")
local S = require("Quadtastic.strings")

local app_stub = function(data, logic)
  local app = {}
  app.quadtastic = setmetatable({},{
      __index = function(_, key)
        local f = logic[key]
        return function(...)
          return f(app, data, ...)
        end
      end,
    })
  return app
end

local function random_quad()
  return {
    x = math.random(0, 100),
    y = math.random(0, 100),
    w = math.random(0, 100),
    h = math.random(0, 100),
  }
end

local function test_data(options)
  local history = History()
  if options and options.saved then history:mark() end
  return {
    quads = {
      foo = {
        bar = random_quad(),
        baz = random_quad(),
      },
    },
    selection = Selection(),
    history = history,
    collapsed_groups = {},
    settings = {recent = {}},
  }
end

local function test_interface()
  return {
    reset_view = function(...) end,
    move_quad_into_view = function(...) end,
    store_settings = function(...) end,
    show_dialog = function(text, options)
      local err_string = string.format("did not expect 'show_dialog'%s%s",
                                       text and (" with text '"..text.."'")
                                            or "",
                                       options and (" with options " ..
                                                    table.concat(options, ", "))
                                               or "")
      error(err_string)
    end,
    query = function(...)
      error("did not expect 'query'")
    end,
    open_file = function(...)
      error("did not expect 'open_file'")
    end,
    save_file = function(...)
      error("did not expect 'save_file'")
    end,
    show_about_dialog = function(...)
      error("did not expect 'show_about_dialog'")
    end,
    show_ack_dialog = function(...)
      error("did not expect 'show_ack_dialog'")
    end,
  }
end

local function test_logic(interface)
  if not interface then interface = test_interface() end
  return QuadtasticLogic.transitions(interface)
end

--[[
 _ __ ___ _ __   __ _ _ __ ___   ___
| '__/ _ \ '_ \ / _` | '_ ` _ \ / _ \
| | |  __/ | | | (_| | | | | | |  __/
|_|  \___|_| |_|\__,_|_| |_| |_|\___|
]]
do
  local data = test_data({saved = true})
  local interface_stub = test_interface()
  interface_stub.query = function(_, existing_key, _)
    assert(existing_key == "foo.bar")
    return "OK", "foo.new"
  end
  local logic = test_logic(interface_stub)
  local app_stub = app_stub(data, logic)
  local quad_ref = data.quads.foo.bar
  logic.rename(app_stub, data, {data.quads.foo.bar})
  assert(not data.history:is_marked())
  assert(not data.quads.foo.bar)
  assert(quad_ref == data.quads.foo.new)
end

do
  local data = test_data({saved = true})
  local interface_stub = test_interface()
  interface_stub.query = function(_, existing_key, _)
    assert(existing_key == "foo.bar")
    return "OK", "foo.baz"
  end
  interface_stub.show_dialog = function(text, options)
    assert(options[1] == "Cancel", text)
    assert(options[2] == "Swap", text)
    assert(options[3] == "Replace", text)
    return "Swap"
  end
  local logic = test_logic(interface_stub)
  local app_stub = app_stub(data, logic)
  local quad_ref_bar = data.quads.foo.bar
  local quad_ref_baz = data.quads.foo.baz
  logic.rename(app_stub, data, {data.quads.foo.bar})
  assert(not data.history:is_marked())
  assert(quad_ref_baz == data.quads.foo.bar)
  assert(quad_ref_bar == data.quads.foo.baz)
end

--[[
                _
 ___  ___  _ __| |_
/ __|/ _ \| '__| __|
\__ \ (_) | |  | |_
|___/\___/|_|   \__|
]]
do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)

  data.quads = {
    {x = 10, y= 20, w= 2, h = 2},
    {x = 20, y= 10, w= 2, h = 2},
    {x = 10, y= 10, w= 2, h = 2},
    {x = 0, y= 22, w= 2, h = 2},
  }
  local original = testutils.clone(data.quads)
  local expected = {
    {x = 10, y= 10, w= 2, h = 2},
    {x = 20, y= 10, w= 2, h = 2},
    {x = 10, y= 20, w= 2, h = 2},
    {x = 0, y= 22, w= 2, h = 2},
  }
  logic.sort(app_stub, data, data.quads)
  assert(testutils.equals(expected, data.quads),
         testutils.expected_vs_actual(expected, data.quads))
  logic.undo(app_stub, data)
  assert(testutils.equals(original, data.quads),
         testutils.expected_vs_actual(original, data.quads))
end

--[[
 _ __ ___ _ __ ___   _____   _____
| '__/ _ \ '_ ` _ \ / _ \ \ / / _ \
| | |  __/ | | | | | (_) \ V /  __/
|_|  \___|_| |_| |_|\___/ \_/ \___|
]]
do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)
  local old_quads = testutils.clone(data.quads)
  local old_quad = data.quads.foo.bar
  logic.remove(app_stub, data, {data.quads.foo.bar})
  assert(not data.history:is_marked())
  assert(data.quads.foo.bar == nil)
  logic.undo(app_stub, data)
  assert(data.history:is_marked())
  assert(data.quads.foo.bar == old_quad)
  assert(testutils.equals(old_quads, data.quads),
         testutils.expected_vs_actual(old_quads, data.quads))
  logic.redo(app_stub, data)
  assert(data.quads.foo.bar == nil)
  logic.undo(app_stub, data)

  local old_group = data.quads.foo
  logic.remove(app_stub, data, {data.quads.foo})
  assert(not data.history:is_marked())
  assert(data.quads.foo == nil)
  logic.undo(app_stub, data)
  assert(data.history:is_marked())
  assert(data.quads.foo == old_group)
  assert(testutils.equals(old_quads, data.quads),
         testutils.expected_vs_actual(old_quads, data.quads))
end

--[[
                     _
  ___ _ __ ___  __ _| |_ ___
 / __| '__/ _ \/ _` | __/ _ \
| (__| | |  __/ (_| | ||  __/
 \___|_|  \___|\__,_|\__\___|
]]
do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)
  data.quads = {}
  local new_quad = random_quad()
  logic.create(app_stub, data, new_quad)
  assert(not data.history:is_marked())
  assert(data.quads[1] == new_quad)
  logic.undo(app_stub, data)
  assert(data.history:is_marked())
  assert(#data.quads == 0)
  logic.redo(app_stub, data)
  assert(data.quads[1] == new_quad)

  local another_quad = random_quad()
  logic.create(app_stub, data, another_quad)
  assert(data.quads[2] == another_quad)

  data.quads[4] = random_quad()

  -- Test whether index 3 is skipped
  local yet_another_quad = random_quad()
  logic.create(app_stub, data, yet_another_quad)
  assert(data.quads[5] == yet_another_quad)
end

--[[
                                                  _
 _ __ ___   _____   _____    __ _ _   _  __ _  __| |___
| '_ ` _ \ / _ \ \ / / _ \  / _` | | | |/ _` |/ _` / __|
| | | | | | (_) \ V /  __/ | (_| | |_| | (_| | (_| \__ \
|_| |_| |_|\___/ \_/ \___|  \__, |\__,_|\__,_|\__,_|___/
                               |_|
]]
do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)
  data.quads = {
    {x = 10, y = 10, w = 50, h = 50}
  }
  local orig_pos = {{x = 10, y = 10}}
  logic.move_quads(app_stub, data, {data.quads[1]}, orig_pos, 5, 15, 100, 100)
  assert(data.quads[1].x == 15)
  assert(data.quads[1].y == 25)

  -- Now we move the quads again with a different delta. This should apply
  -- the delta to the original position, rather than to the quad's current
  -- position.
  logic.move_quads(app_stub, data, {data.quads[1]}, orig_pos, 10, -5, 100, 100)
  assert(data.quads[1].x == 20)
  assert(data.quads[1].y == 5)

  -- Now we commit the movement, which should not change the quad's position
  logic.commit_movement(app_stub, data, {data.quads[1]}, orig_pos)
  assert(data.quads[1].x == 20)
  assert(data.quads[1].y == 5)

  -- And if we now undo the action, the quad should return to its old position
  logic.undo(app_stub, data)
  assert(data.quads[1].x == orig_pos[1].x)
  assert(data.quads[1].y == orig_pos[1].y)

  -- And redoing restores the new position
  logic.redo(app_stub, data)
  assert(data.quads[1].x == 20)
  assert(data.quads[1].y == 5)
end

-- Test limiting quad movement to image bounds
do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)
  data.quads = {
    {x = 10, y = 10, w = 50, h = 50}
  }
  local orig_pos = {{x = 10, y = 10}}
  logic.move_quads(app_stub, data, {data.quads[1]}, orig_pos, 50, 50, 70, 90)
  -- The quad should not move beyond 20, 40 to stay within the image bounds
  assert(data.quads[1].x == 20)
  assert(data.quads[1].y == 40)

  logic.move_quads(app_stub, data, {data.quads[1]}, orig_pos, -50, -50, 70, 90)
  -- The quad should not move beyond 0, 0 to stay within the image bounds
  assert(data.quads[1].x == 0)
  assert(data.quads[1].y == 0)

  logic.commit_movement(app_stub, data, {data.quads[1]}, orig_pos)
  assert(data.quads[1].x == 0)
  assert(data.quads[1].y == 0)

  -- And if we now undo the action, the quad should return to its old position
  logic.undo(app_stub, data)
  assert(data.quads[1].x == orig_pos[1].x)
  assert(data.quads[1].y == orig_pos[1].y)

  -- And redoing restores the new position
  logic.redo(app_stub, data)
  assert(data.quads[1].x == 0)
  assert(data.quads[1].y == 0)
end

--[[
               _                                 _
 _ __ ___  ___(_)_______    __ _ _   _  __ _  __| |___
| '__/ _ \/ __| |_  / _ \  / _` | | | |/ _` |/ _` / __|
| | |  __/\__ \ |/ /  __/ | (_| | |_| | (_| | (_| \__ \
|_|  \___||___/_/___\___|  \__, |\__,_|\__,_|\__,_|___/
                              |_|
]]
local function quad(x, y, w, h)
  return { x = x, y = y, w = w, h = h }
end

do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)
  data.quads = {
    {x = 10, y = 10, w = 50, h = 50}
  }
  local orig_quad = {{x = 10, y = 10, w = 50, h = 50}}
  local direction = {n = true}
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     10, -5, 100, 100)
  assert(testutils.equals(data.quads[1], quad(10, 5, 50, 55)))

  -- Check that the size cannot exceed the image bounds
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     10, -100, 100, 100)
  assert(testutils.equals(data.quads[1], quad(10, 0, 50, 60)))

  -- Check that the size cannot shrink below 1
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     10, 100, 100, 100)
  assert(testutils.equals(data.quads[1], quad(10, 59, 50, 1)))

  logic.commit_resizing(app_stub, data, {data.quads[1]}, orig_quad)
  assert(testutils.equals(data.quads[1], quad(10, 59, 50, 1)))

  -- And if we now undo the action, the quad should return to its old size
  logic.undo(app_stub, data)
  assert(testutils.equals(data.quads[1], orig_quad[1]))

  -- And redoing restores the new position
  logic.redo(app_stub, data)
  assert(testutils.equals(data.quads[1], quad(10, 59, 50, 1)))
end

do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)
  data.quads = {
    {x = 10, y = 10, w = 50, h = 50}
  }
  local orig_quad = {{x = 10, y = 10, w = 50, h = 50}}
  local direction = {n = true, e = true}
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     10, -5, 100, 100)
  assert(testutils.equals(data.quads[1], quad(10, 5, 60, 55)))

  -- Check that the size cannot exceed the image bounds
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     100, -100, 100, 100)
  assert(testutils.equals(data.quads[1], quad(10, 0, 90, 60)))

  -- Check that the size cannot shrink below 1
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     -100, 100, 100, 100)
  assert(testutils.equals(data.quads[1], quad(10, 59, 1, 1)))

  logic.commit_resizing(app_stub, data, {data.quads[1]}, orig_quad)
  assert(testutils.equals(data.quads[1], quad(10, 59, 1, 1)))

  -- And if we now undo the action, the quad should return to its old size
  logic.undo(app_stub, data)
  assert(testutils.equals(data.quads[1], orig_quad[1]))

  -- And redoing restores the new position
  logic.redo(app_stub, data)
  assert(testutils.equals(data.quads[1], quad(10, 59, 1, 1)))
end

do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)
  data.quads = {
    {x = 10, y = 10, w = 50, h = 50}
  }
  local orig_quad = {{x = 10, y = 10, w = 50, h = 50}}
  local direction = {e = true}
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     10, 10, 100, 100)
  assert(testutils.equals(data.quads[1], quad(10, 10, 60, 50)))

  -- Check that the size cannot exceed the image bounds
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     100, 10, 100, 100)
  assert(testutils.equals(data.quads[1], quad(10, 10, 90, 50)))

  -- Check that the size cannot shrink below 1
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     -100, 10, 100, 100)
  assert(testutils.equals(data.quads[1], quad(10, 10, 1, 50)))

  logic.commit_resizing(app_stub, data, {data.quads[1]}, orig_quad)
  assert(testutils.equals(data.quads[1], quad(10, 10, 1, 50)))

  -- And if we now undo the action, the quad should return to its old size
  logic.undo(app_stub, data)
  assert(testutils.equals(data.quads[1], orig_quad[1]))

  -- And redoing restores the new position
  logic.redo(app_stub, data)
  assert(testutils.equals(data.quads[1], quad(10, 10, 1, 50)))
end

do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)
  data.quads = {
    {x = 10, y = 10, w = 50, h = 50}
  }
  local orig_quad = {{x = 10, y = 10, w = 50, h = 50}}
  local direction = {s = true, e = true}
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     10, 10, 100, 100)
  assert(testutils.equals(data.quads[1], quad(10, 10, 60, 60)))

  -- Check that the size cannot exceed the image bounds
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     100, 100, 100, 100)
  assert(testutils.equals(data.quads[1], quad(10, 10, 90, 90)))

  -- Check that the size cannot shrink below 1
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     -100, -100, 100, 100)
  assert(testutils.equals(data.quads[1], quad(10, 10, 1, 1)))

  logic.commit_resizing(app_stub, data, {data.quads[1]}, orig_quad)
  assert(testutils.equals(data.quads[1], quad(10, 10, 1, 1)))

  -- And if we now undo the action, the quad should return to its old size
  logic.undo(app_stub, data)
  assert(testutils.equals(data.quads[1], orig_quad[1]))

  -- And redoing restores the new position
  logic.redo(app_stub, data)
  assert(testutils.equals(data.quads[1], quad(10, 10, 1, 1)))
end

do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)
  data.quads = {
    {x = 10, y = 10, w = 50, h = 50}
  }
  local orig_quad = {{x = 10, y = 10, w = 50, h = 50}}
  local direction = {s = true}
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     10, 10, 100, 100)
  assert(testutils.equals(data.quads[1], quad(10, 10, 50, 60)))

  -- Check that the size cannot exceed the image bounds
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     10, 100, 100, 100)
  assert(testutils.equals(data.quads[1], quad(10, 10, 50, 90)))

  -- Check that the size cannot shrink below 1
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     10, -100, 100, 100)
  assert(testutils.equals(data.quads[1], quad(10, 10, 50, 1)))

  logic.commit_resizing(app_stub, data, {data.quads[1]}, orig_quad)
  assert(testutils.equals(data.quads[1], quad(10, 10, 50, 1)))

  -- And if we now undo the action, the quad should return to its old size
  logic.undo(app_stub, data)
  assert(testutils.equals(data.quads[1], orig_quad[1]))

  -- And redoing restores the new position
  logic.redo(app_stub, data)
  assert(testutils.equals(data.quads[1], quad(10, 10, 50, 1)))
end

do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)
  data.quads = {
    {x = 10, y = 10, w = 50, h = 50}
  }
  local orig_quad = {{x = 10, y = 10, w = 50, h = 50}}
  local direction = {s = true, w = true}
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     -5, 10, 100, 100)
  assert(testutils.equals(data.quads[1], quad(5, 10, 55, 60)))

  -- Check that the size cannot exceed the image bounds
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     -100, 100, 100, 100)
  assert(testutils.equals(data.quads[1], quad(0, 10, 60, 90)))

  -- Check that the size cannot shrink below 1
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     100, -100, 100, 100)
  assert(testutils.equals(data.quads[1], quad(59, 10, 1, 1)))

  logic.commit_resizing(app_stub, data, {data.quads[1]}, orig_quad)
  assert(testutils.equals(data.quads[1], quad(59, 10, 1, 1)))

  -- And if we now undo the action, the quad should return to its old size
  logic.undo(app_stub, data)
  assert(testutils.equals(data.quads[1], orig_quad[1]))

  -- And redoing restores the new position
  logic.redo(app_stub, data)
  assert(testutils.equals(data.quads[1], quad(59, 10, 1, 1)))
end

do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)
  data.quads = {
    {x = 10, y = 10, w = 50, h = 50}
  }
  local orig_quad = {{x = 10, y = 10, w = 50, h = 50}}
  local direction = {w = true}
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     -5, 10, 100, 100)
  assert(testutils.equals(data.quads[1], quad(5, 10, 55, 50)))

  -- Check that the size cannot exceed the image bounds
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     -100, 10, 100, 100)
  assert(testutils.equals(data.quads[1], quad(0, 10, 60, 50)))

  -- Check that the size cannot shrink below 1
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     100, 10, 100, 100)
  assert(testutils.equals(data.quads[1], quad(59, 10, 1, 50)))

  logic.commit_resizing(app_stub, data, {data.quads[1]}, orig_quad)
  assert(testutils.equals(data.quads[1], quad(59, 10, 1, 50)))

  -- And if we now undo the action, the quad should return to its old size
  logic.undo(app_stub, data)
  assert(testutils.equals(data.quads[1], orig_quad[1]))

  -- And redoing restores the new position
  logic.redo(app_stub, data)
  assert(testutils.equals(data.quads[1], quad(59, 10, 1, 50)))
end

do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)
  data.quads = {
    {x = 10, y = 10, w = 50, h = 50}
  }
  local orig_quad = {{x = 10, y = 10, w = 50, h = 50}}
  local direction = {n = true, w = true}
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     -5, -5, 100, 100)
  assert(testutils.equals(data.quads[1], quad(5, 5, 55, 55)))

  -- Check that the size cannot exceed the image bounds
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     -100, -100, 100, 100)
  assert(testutils.equals(data.quads[1], quad(0, 0, 60, 60)))

  -- Check that the size cannot shrink below 1
  logic.resize_quads(app_stub, data, {data.quads[1]}, orig_quad, direction,
                     100, 100, 100, 100)
  assert(testutils.equals(data.quads[1], quad(59, 59, 1, 1)))

  logic.commit_resizing(app_stub, data, {data.quads[1]}, orig_quad)
  assert(testutils.equals(data.quads[1], quad(59, 59, 1, 1)))

  -- And if we now undo the action, the quad should return to its old size
  logic.undo(app_stub, data)
  assert(testutils.equals(data.quads[1], orig_quad[1]))

  -- And redoing restores the new position
  logic.redo(app_stub, data)
  assert(testutils.equals(data.quads[1], quad(59, 59, 1, 1)))
end

--[[
  __ _ _ __ ___  _   _ _ __
 / _` | '__/ _ \| | | | '_ \
| (_| | | | (_) | |_| | |_) |
 \__, |_|  \___/ \__,_| .__/
 |___/                |_|
]]
do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)
  local quads = {
    random_quad(), random_quad(), random_quad(),
    random_quad(), random_quad(), random_quad(),
  }
  data.quads = {
    quads[1],
    quads[2],
    quads[3],
    {
      quads[4], quads[5], quads[6]
    }
  }
  local old_quads = testutils.clone(data.quads)
  logic.group(app_stub, data, {quads[2], quads[3]})
  assert(not data.history:is_marked())

  local expected = {
    [1] = quads[1],
    [4] = {
      quads[4], quads[5], quads[6]
    },
    [5] = {
      quads[2],
      quads[3],
    },
  }
  assert(testutils.equals(data.quads, expected),
         testutils.expected_vs_actual(expected, data.quads))

  logic.undo(app_stub, data)
  assert(data.history:is_marked())
  assert(testutils.equals(data.quads, old_quads),
         testutils.expected_vs_actual(old_quads, data.quads))
end

-- Test that group preserves order
do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)
  local quads = {
    random_quad(), random_quad(), random_quad(),
    random_quad(), random_quad(), random_quad(),
  }
  data.quads = {
    quads[1],
    quads[2],
    quads[3],
    quads[4],
    quads[5],
    quads[6]
  }
  local old_quads = testutils.clone(data.quads)
  logic.group(app_stub, data, {quads[2], quads[4], quads[5]})
  assert(not data.history:is_marked())

  local expected = {
    [1] = quads[1],
    [3] = quads[3],
    [6] = quads[6],
    [7] = {
      quads[2], quads[4], quads[5]
    },
  }
  assert(testutils.equals(data.quads, expected),
         testutils.expected_vs_actual(expected, data.quads))

  logic.undo(app_stub, data)
  assert(data.history:is_marked())
  assert(testutils.equals(data.quads, old_quads),
         testutils.expected_vs_actual(old_quads, data.quads))
end

--[[
 _   _ _ __   __ _ _ __ ___  _   _ _ __
| | | | '_ \ / _` | '__/ _ \| | | | '_ \
| |_| | | | | (_| | | | (_) | |_| | |_) |
 \__,_|_| |_|\__, |_|  \___/ \__,_| .__/
             |___/                |_|
]]
do
  local data = test_data({saved = true})
  local interface_stub = test_interface()
  -- A dialog should pop up, asking whether it's okay that some of the indices
  -- will change while sorting the quads
  interface_stub.show_dialog = function(text, options)
    return "Yes"
  end
  local logic = test_logic(interface_stub)
  local app_stub = app_stub(data, logic)
  local quads = {
    random_quad(), random_quad(), random_quad(),
    random_quad(), random_quad(), random_quad(),
  }
  data.quads = {
    quads[1],
    quads[2],
    quads[3],
    {
      quads[4], quads[5], quads[6]
    }
  }
  local old_quads = testutils.clone(data.quads)
  logic.ungroup(app_stub, data, {data.quads[4]})
  assert(not data.history:is_marked())
  assert(data.quads[4] == quads[4])
  assert(data.quads[5] == quads[5])
  assert(data.quads[6] == quads[6])

  logic.undo(app_stub, data)
  assert(testutils.equals(data.quads, old_quads),
         testutils.expected_vs_actual(old_quads, data.quads))
end

-- offer_reload
do
  -- Not sure what to test here...
end

--[[
                 _                         _                _
 _   _ _ __   __| | ___     __ _ _ __   __| |  _ __ ___  __| | ___
| | | | '_ \ / _` |/ _ \   / _` | '_ \ / _` | | '__/ _ \/ _` |/ _ \
| |_| | | | | (_| | (_) | | (_| | | | | (_| | | | |  __/ (_| | (_) |
 \__,_|_| |_|\__,_|\___/   \__,_|_| |_|\__,_| |_|  \___|\__,_|\___/
]]
do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)
  local do_function, do_spy = testutils.call_spy()
  local undo_function, undo_spy = testutils.call_spy()
  data.history:add(do_function, undo_function)
  assert(not data.history:is_marked())
  logic.undo(app_stub, data)
  assert(undo_spy() == 1) --check that the undo function was called once
  assert(data.history:is_marked())
  logic.redo(app_stub, data)
  assert(do_spy() == 1) --check that the redo function was called once
  assert(not data.history:is_marked())
end

--[[
 _ __   _____      __
| '_ \ / _ \ \ /\ / /
| | | |  __/\ V  V /
|_| |_|\___| \_/\_/
]]
do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)
  logic.new(app_stub, data)
  assert(data.history:is_marked())
end

--[[
 ___  __ ___   _____
/ __|/ _` \ \ / / _ \
\__ \ (_| |\ V /  __/
|___/\__,_| \_/ \___|
]]
do
  local data = test_data()
  local interface = test_interface()
  -- Create a stub function that returns yes
  local save_as_stub, save_as_spy = testutils.call_spy(function() return "Save", '/dev/null' end)
  local store_settings_stub, store_settings_spy = testutils.call_spy()
  interface.save_file = save_as_stub
  interface.store_settings = store_settings_stub
  local logic = test_logic(interface)
  local app_stub = app_stub(data, logic)
  logic.save(app_stub, data)
  assert(data.history:is_marked())
  assert(save_as_spy() == 1) -- check that these functions were each called once
  assert(store_settings_spy() == 1)

  -- When we now save again, it should not ask for a filename a second time.
  logic.save(app_stub, data)
  assert(data.history:is_marked())
  assert(save_as_spy() == 1) -- check that the counter didn't change on both functions
  assert(store_settings_spy() == 1)
end

--[[
 ___  __ ___   _____    __ _ ___
/ __|/ _` \ \ / / _ \  / _` / __|
\__ \ (_| |\ V /  __/ | (_| \__ \
|___/\__,_| \_/ \___|  \__,_|___/
]]
do
  local data = test_data()
  local interface = test_interface()
  -- Create a stub function that returns yes
  local save_as_stub, save_as_spy = testutils.call_spy(function() return "Save", '/dev/null' end)
  local store_settings_stub, store_settings_spy = testutils.call_spy()
  interface.save_file = save_as_stub
  interface.store_settings = store_settings_stub
  local logic = test_logic(interface)
  local app_stub = app_stub(data, logic)
  logic.save_as(app_stub, data)
  assert(data.history:is_marked())
  assert(save_as_spy() == 1) -- check that these functions were each called once
  assert(store_settings_spy() == 1)

  -- When we now save again, it should again ask for a filename.
  logic.save_as(app_stub, data)
  assert(data.history:is_marked())
  assert(save_as_spy() == 2) -- check that the counter was incremented on both functions
  assert(store_settings_spy() == 2)
end

-- choose_quad
do
  -- NYI
end

--[[
                                   _        _                 _ _                                              _         _
 _ __  _ __ ___   ___ ___  ___  __| |    __| | ___  ___ _ __ (_) |_ ___    _   _ _ __  ___  __ ___   _____  __| |    ___| |__   __ _ _ __   __ _  ___  ___
| '_ \| '__/ _ \ / __/ _ \/ _ \/ _` |   / _` |/ _ \/ __| '_ \| | __/ _ \  | | | | '_ \/ __|/ _` \ \ / / _ \/ _` |   / __| '_ \ / _` | '_ \ / _` |/ _ \/ __|
| |_) | | | (_) | (_|  __/  __/ (_| |  | (_| |  __/\__ \ |_) | | ||  __/  | |_| | | | \__ \ (_| |\ V /  __/ (_| |  | (__| | | | (_| | | | | (_| |  __/\__ \
| .__/|_|  \___/ \___\___|\___|\__,_|___\__,_|\___||___/ .__/|_|\__\___|___\__,_|_| |_|___/\__,_| \_/ \___|\__,_|___\___|_| |_|\__,_|_| |_|\__, |\___||___/
|_|                                |_____|             |_|            |_____|                                  |_____|                     |___/
proceed_despite_unsaved_changes
]]

-- make sure that the opened dialog contains the buttons we expect in these tests
do
  local show_dialog_stub, show_dialog_spy = testutils.call_spy(function(text, options)
    assert(text == S.dialogs.save_changes, text)
    assert(options[1] == S.buttons.cancel, options[1])
    assert(options[2] == S.buttons.discard, options[2])
    assert(options[3] == S.buttons.save, options[3])
    return S.buttons.discard
  end)

  local data = test_data()
  local interface = test_interface()
  interface.show_dialog = show_dialog_stub
  local logic = test_logic(interface)
  local app_stub = app_stub(data, logic)
  -- since the data is not saved, the dialog should open
  logic.proceed_despite_unsaved_changes(app_stub, data)
  assert(show_dialog_spy() == 1)
end

-- if the project contains no unsaved changes, then proceed_despite_unsaved_changes
-- should return true immediately
do
  local data = test_data({saved = true})
  local logic = test_logic()
  local app_stub = app_stub(data, logic)
  -- since the data is not saved, the dialog should open
  assert(logic.proceed_despite_unsaved_changes(app_stub, data),
         "Should return true if project contains no unsaved changes")
end

-- if the project contains unsaved changes, then proceed_despite_unsaved_changes
-- should return true if the user clicks either the save or the discard button,
-- and false otherwise
do
  local data = test_data()
  local interface = test_interface()
  local logic = test_logic(interface)
  local app_stub = app_stub(data, logic)

  -- when the user clicks 'save', then save_file will be called
  local save_file_stub, save_file_spy
  interface.save_file, save_file_spy = testutils.call_spy()

  local discard_stub, discard_spy = testutils.call_spy(function(text, options)
    return S.buttons.discard
  end)

  interface.show_dialog = discard_stub
  assert(logic.proceed_despite_unsaved_changes(app_stub, data),
         "Should return true when user clicks 'discard'")
  assert(discard_spy() == 1)
  assert(save_file_spy() == 0)

  local save_stub, save_spy = testutils.call_spy(function(text, options)
    return S.buttons.save
  end)

  local cancel_stub, cancel_spy = testutils.call_spy(function(text, options)
    return S.buttons.cancel
  end)

  interface.show_dialog = cancel_stub
  assert(not logic.proceed_despite_unsaved_changes(app_stub, data),
         "Should return false when user clicks 'cancel'")
  assert(cancel_spy() == 1)
  assert(save_file_spy() == 0)

  interface.show_dialog = save_stub
  assert(logic.proceed_despite_unsaved_changes(app_stub, data),
         "Should return true when user clicks 'save'")
  assert(save_spy() == 1)
  assert(save_file_spy() == 1)
end

-- Now check that proceed_despite_unsaved_changes is called whenever the user
-- would lose unsaved changes.
do
  local data = test_data()
  local interface = test_interface()
  local logic = test_logic(interface)
  local app_stub = app_stub(data, logic)

  -- Create a call stub and spy for proceed_despite_unsaved_changes that returns
  -- false, so that none of the actions actually proceed.
  local proceed_stub, proceed_spy
  logic.proceed_despite_unsaved_changes, proceed_spy =
    testutils.call_spy(function() return false end)

  -- load_quad
  logic.load_quad(app_stub, data, "some/path.lua")
  assert(proceed_spy() == 1)

  -- new
  logic.new(app_stub, data)
  assert(proceed_spy() == 2)

  -- quit
  logic.quit(app_stub, data)
  assert(proceed_spy() == 3)

end

-- load_quad
do
  -- NYI
end

-- choose_image
do
  -- NYI
end

-- load_image
do
  -- NYI
end

-- load_dropped_file
do
  -- NYI
end

-- show_about_dialog
do
  -- NYI
end

-- show_ack_dialog
do
  -- NYI
end

