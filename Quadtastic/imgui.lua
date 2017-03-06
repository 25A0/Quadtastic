local Rectangle = require("Rectangle")

local imgui = {}

imgui.init_layout_state = function(
  parent_layout, -- the layout that contains this layout
  next_x, -- where the next layout-aware component should be drawn
  next_y,
  max_w, -- the maximum dimensions that this layout should span
  max_h
)
  return {
    next_x = next_x or 0, -- where the next layout-aware component should be drawn
    next_y = next_y or 0,
    max_w = max_w or (parent_layout and parent_layout.max_w),
    max_h = max_h or (parent_layout and parent_layout.max_h),
    adv_x = 0, -- the advance in x and y of the last drawn element
    adv_y = 0,
    acc_adv_x = next_x or 0, -- the accumulative advance in x and y
    acc_adv_y = next_y or 0,
    parent_layout = parent_layout, -- the layout that contains this layout,
                                   -- or nil if this is the root layout.
  }
end

imgui.push_layout_state = function(state, x, y, w, h)
  state.layout = imgui.init_layout_state(state.layout, x, y, w, h)
end

imgui.pop_layout_state = function(state)
  state.layout = state.layout.parent_layout
end

imgui.push_style = function(state, type, new_value)
  if not state.style[type.."_stack"] then
    state.style[type.."_stack"] = {state.style[type]}
  else
    table.insert(state.style[type.."_stack"], state.style[type])
  end
  state.style[type] = new_value
end

imgui.pop_style = function(state, type)
  if not state.style[type.."_stack"] then
    error("There was no push stack for type "..type)
  end
  state.style[type] = table.remove(state.style[type.."_stack"])
end

imgui.init_state = function(transform)
  -- Initialize the state
  local state = {
    mouse = {
      buttons = {}, -- Holds information about which buttons are pressed
      x = 0, -- current mouse x position
      y = 0, -- current mouse y position
      old_x = 0, -- mouse position in the previous frame
      old_y = 0,
      dx = 0, -- mouse movement in x since the last update
      dy = 0, -- mouse movement in y since the last update
      wheel_dx = 0, -- horizontal mouse wheel movement since the last update
      wheel_dy = 0, -- vertical mouse wheel movement since the last update
    },
    keyboard = {
      keys = {}, -- List of all keys. Might not be complete
      scancodes = {}, -- List of all scancodes. Might not be complete
      -- Both lists contain key states for keys that have been pressed.
      -- Each keystate contains whether the key is pressed, and how many
      -- times it has been typed since the last update.
      text = nil, -- Text that has been typed since last update
    },
    input_field = {
      cursor_pos = 0,
      cursor_dt = 0,
    },
    dt = 0, -- Time since last update
    style = {
      font = nil, -- The font that is being used
      stylesheet = nil, -- A texture atlas with gui styles
    },
    layout = imgui.init_layout_state(nil), -- the current layout
    transform = transform, -- the current transform
    tooltip_time = 0, -- the time that the mouse has spent on a widget
  }
  return state
end

local default_cursor = love.mouse.getSystemCursor("arrow")


imgui.begin_frame = function(state)
  love.graphics.origin()
  -- Reset cursor
  love.mouse.setCursor(default_cursor)
end

imgui.end_frame = function(state)
  -- Reset mouse deltas
  state.mouse.dx = 0
  state.mouse.dy = 0
  state.mouse.old_x = state.mouse.x
  state.mouse.old_y = state.mouse.y
  state.mouse.wheel_dx = 0
  state.mouse.wheel_dy = 0
  -- Reset mouse button clicks
  -- We can't use ipairs here since the first index might not be defined
  for button, button_state in pairs(state.mouse.buttons) do
    button_state.presses = 0
    button_state.releases = 0
  end
  -- Reset key type count
  for key, key_state in pairs(state.keyboard.keys) do
    key_state.presses = 0
    key_state.releases = 0
  end
  for scancode, scancode_state in pairs(state.keyboard.scancodes) do
    scancode_state.presses = 0
    scancode_state.releases = 0
  end
  -- Reset typed text
  state.keyboard.text = nil
end

-- -------------------------------------------------------------------------- --
-- MOUSE INPUT
-- -------------------------------------------------------------------------- --
local function init_mouse_state(state, button)
  if not state.mouse.buttons[button] then
    state.mouse.buttons[button] = {
      pressed = false, -- whether the button is currently being pressed
      at_x = 0, -- the x coordinate where the button was pressed
      at_y = 0, -- the y coordinate where the button was pressed
      presses = 0, -- how many times the button was pressed since the last update
      releases = 0, -- how many times the button was released since the last update
    }
  end
end

imgui.mousepressed = function(state, x, y, button)
  -- We can't know in advance how many buttons there will be, so we might
  -- need to initialize this table.
  init_mouse_state(state, button)
  local button_state = state.mouse.buttons[button]
  -- Track that this button was pressed
  button_state.pressed = true
  -- and where it was pressed
  button_state.at_x, button_state.at_y = x, y
  -- Increment the number of clicks that happened since the last update
  button_state.presses = button_state.presses + 1
end

imgui.mousereleased = function(state, x, y, button)
  -- We can't know in advance how many buttons there will be, so we might
  -- need to initialize this table.
  init_mouse_state(state, button)
  local button_state = state.mouse.buttons[button]
  -- Track that this button was released
  button_state.pressed = false
  -- Increment the number of clicks that happened since the last update
  button_state.releases = button_state.releases + 1
end

imgui.mousemoved = function(state, x, y, dx, dy)
  state.mouse.x,  state.mouse.y  = x, y
  state.mouse.dx, state.mouse.dy = dx, dy

end

imgui.wheelmoved = function(state, x, y)
  state.mouse.wheel_dx = x
  state.mouse.wheel_dy = y
end

-- -------------------------------------------------------------------------- --
-- KEYBOARD INPUT
-- -------------------------------------------------------------------------- --
local function init_key_state(state, key)
  if not state.keyboard.keys[key] then
    state.keyboard.keys[key] = {
      pressed = false,
      presses = 0, -- how many times the key was pressed since the last update
      releases = 0, -- how many times the key was released since the last update
    }
  end
end

local function init_scancode_state(state, key)
  if not state.keyboard.scancodes[key] then
    state.keyboard.scancodes[key] = {
      pressed = false,
      presses = 0, -- how many times the scancode was pressed since the last update
      releases = 0, -- how many times the scancode was released since the last update
    }
  end
end

imgui.keypressed = function(state, key, scancode, isrepeat)
  init_key_state(state, key)
  init_scancode_state(state, scancode)
  state.keyboard.keys[key].pressed = true
  state.keyboard.keys[key].presses = state.keyboard.keys[key].presses + 1
  state.keyboard.scancodes[scancode].pressed = true
  state.keyboard.scancodes[scancode].presses = state.keyboard.keys[key].presses + 1
end

imgui.keyreleased = function(state, key, scancode)
  init_key_state(state, key)
  init_scancode_state(state, scancode)
  state.keyboard.keys[key].pressed = false
  state.keyboard.keys[key].releases = state.keyboard.keys[key].releases + 1
  state.keyboard.scancodes[scancode].pressed = false
  state.keyboard.scancodes[scancode].releases = state.keyboard.keys[key].releases + 1
end

imgui.textinput = function(state, text)
  state.keyboard.text = text
end

imgui.update = function(state, dt)
  state.dt = dt
end

-- -------------------------------------------------------------------------- --
-- Helper functions
-- -------------------------------------------------------------------------- --

-- Returns whether the given mouse coordinates were in the given rectangle.
-- If no mouse coordinates are given then the current mouse position is used.
imgui.is_mouse_in_rect = function(state, x, y, w, h, mx, my, transform)
  mx = mx or state.mouse.x
  my = my or state.mouse.y
  transform = transform or state.transform
  return Rectangle.contains({x = x, y = y, w = w, h = h}, 
                            transform:unproject(mx, my))
end

imgui.was_key_pressed = function(state, key)
  return state.keyboard.keys[key] and state.keyboard.keys[key].presses > 0
end

return imgui