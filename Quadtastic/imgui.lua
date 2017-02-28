local imgui = {}

imgui.init_state = function()
  -- Initialize the state
  local state = {
    mouse = {
      buttons = {}, -- Holds information about which buttons are pressed
      x = 0, -- current mouse x position
      y = 0, -- current mouse y position
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
  }
  return state
end

imgui.begin_frame = function(state) end
imgui.end_frame = function(state)
  -- Reset mouse deltas
  state.mouse.dx = 0
  state.mouse.dy = 0
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


return imgui