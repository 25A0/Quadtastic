local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local Rectangle = require(current_folder .. ".Rectangle")

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

local function init_input()
  return { -- all data related to input. will be hidden on inactive windows
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
  }
end

imgui.reset_input = function(gui_state)
  gui_state.input = init_input()
end

imgui.init_state = function(transform)
  -- Initialize the state
  local state = {
    input = init_input(),
    input_field = {
      cursor_pos = 0,
      cursor_dt = 0,
      selection_end = nil, -- If there is a selection then it ranges from the
                           -- current cursor position to selection_end.
    },
    dt = 0, -- Time since last update
    t = 0, -- Total time since app was started
    second = 0, -- Accumulative timer that counts up to a second
    style = {
      font = nil, -- The font that is being used
      stylesheet = nil, -- A texture atlas with gui styles
      default_cursor = love.mouse.getSystemCursor("arrow"),
      text_cursor = love.mouse.getSystemCursor("ibeam"),
    },
    layout = imgui.init_layout_state(nil), -- the current layout
    transform = transform, -- the current transform
    tooltip_time = 0, -- the time that the mouse has spent on a widget
    menu_depth = 0, -- The menu depth will be used by menus to decide how to render
    current_menus = {}, -- List of currently selected menu entries
    menu_bounds = {}, -- Dimensions of menus on each menu level
    toasts = {}, -- The list of toasts
  }
  return state
end

-- Will start to show a toast with the given label in the given bounds for the
-- given duration (in seconds). This function cannot be used for toasts that
-- should be displayed every frame. Draw the toast directly in those cases.
-- This is intended for toasts that are triggered once on events.
function imgui.show_toast(gui_state, label, bounds, duration)
  bounds = bounds and gui_state.transform:project_bounds(bounds) or nil
  table.insert(gui_state.toasts, {
    label = label,
    bounds = bounds,
    start = gui_state.t,
    duration = duration,
    remaining = duration,
  })
end

imgui.cover_input = function(state)
  if not state.cover_count or state.cover_count == 0 then
    -- cover input field
    state._input = state.input
    state.input = nil
    state.cover_count = 1
  else
    -- cover the input deeper.
    state.cover_count = state.cover_count + 1
  end
end

imgui.uncover_input = function(state)
  if not state.cover_count or state.cover_count == 0 then
    error("Cannot uncover input if it's not covered")
  elseif state.cover_count == 1 then
    -- actually uncover input
    assert(state._input)
    state.input = state._input
    state._input = nil
    state.cover_count = 0
  else
    -- decrease cover count
    state.cover_count = state.cover_count - 1
  end
end

imgui.begin_frame = function(state)
  love.graphics.origin()
  -- Reset cursor
  love.mouse.setCursor(state.style.default_cursor)
end

imgui.end_frame = function(state)
  assert(state.menu_depth == 0, "One or more menus were not finished")
  state.menu_bounds = {}

  -- Reset mouse deltas
  state.input.mouse.dx = 0
  state.input.mouse.dy = 0
  state.input.mouse.old_x = state.input.mouse.x
  state.input.mouse.old_y = state.input.mouse.y
  state.input.mouse.wheel_dx = 0
  state.input.mouse.wheel_dy = 0
  -- Reset mouse button clicks
  -- We can't use ipairs here since the first index might not be defined
  for _, button_state in pairs(state.input.mouse.buttons) do
    button_state.presses = 0
    button_state.releases = 0
  end
  -- Reset key type count
  for _, key_state in pairs(state.input.keyboard.keys) do
    key_state.presses = 0
    key_state.releases = 0
  end
  for _, scancode_state in pairs(state.input.keyboard.scancodes) do
    scancode_state.presses = 0
    scancode_state.releases = 0
  end
  -- Reset typed text
  state.input.keyboard.text = nil
end

-- -------------------------------------------------------------------------- --
-- MOUSE INPUT
-- -------------------------------------------------------------------------- --
local function init_mouse_state(state, button)
  if not state.input.mouse.buttons[button] then
    state.input.mouse.buttons[button] = {
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
  local button_state = state.input.mouse.buttons[button]
  -- Track that this button was pressed
  button_state.pressed = true
  -- and where it was pressed
  button_state.at_x, button_state.at_y = x, y
  -- Increment the number of clicks that happened since the last update
  button_state.presses = button_state.presses + 1
end

imgui.mousereleased = function(state, _, _, button)
  -- We can't know in advance how many buttons there will be, so we might
  -- need to initialize this table.
  init_mouse_state(state, button)
  local button_state = state.input.mouse.buttons[button]
  -- Track that this button was released
  button_state.pressed = false
  -- Increment the number of clicks that happened since the last update
  button_state.releases = button_state.releases + 1
end

imgui.mousemoved = function(state, x, y, dx, dy)
  state.input.mouse.x,  state.input.mouse.y  = x, y
  state.input.mouse.dx, state.input.mouse.dy = dx, dy

end

imgui.wheelmoved = function(state, x, y)
  state.input.mouse.wheel_dx = x
  state.input.mouse.wheel_dy = y
end

-- -------------------------------------------------------------------------- --
-- KEYBOARD INPUT
-- -------------------------------------------------------------------------- --
local function init_key_state(state, key)
  if not state.input.keyboard.keys[key] then
    state.input.keyboard.keys[key] = {
      pressed = false,
      presses = 0, -- how many times the key was pressed since the last update
      releases = 0, -- how many times the key was released since the last update
    }
  end
end

local function init_scancode_state(state, key)
  if not state.input.keyboard.scancodes[key] then
    state.input.keyboard.scancodes[key] = {
      pressed = false,
      presses = 0, -- how many times the scancode was pressed since the last update
      releases = 0, -- how many times the scancode was released since the last update
    }
  end
end

imgui.keypressed = function(state, key, scancode)
  init_key_state(state, key)
  init_scancode_state(state, scancode)
  state.input.keyboard.keys[key].pressed = true
  state.input.keyboard.keys[key].presses = state.input.keyboard.keys[key].presses + 1
  state.input.keyboard.scancodes[scancode].pressed = true
  state.input.keyboard.scancodes[scancode].presses = state.input.keyboard.keys[key].presses + 1
end

imgui.keyreleased = function(state, key, scancode)
  init_key_state(state, key)
  init_scancode_state(state, scancode)
  state.input.keyboard.keys[key].pressed = false
  state.input.keyboard.keys[key].releases = state.input.keyboard.keys[key].releases + 1
  state.input.keyboard.scancodes[scancode].pressed = false
  state.input.keyboard.scancodes[scancode].releases = state.input.keyboard.keys[key].releases + 1
end

imgui.textinput = function(state, text)
  state.input.keyboard.text = text
end

imgui.update = function(state, dt)
  state.frames = 1 + (state.frames or 0)
  state.dt = dt
  state.t = state.t + dt
  local fullsecond
  fullsecond, state.second = math.modf(state.second + dt)
  if fullsecond >= 1 then
    state.fps = state.frames
    state.frames = 0
  end
  state.second_mark = fullsecond >= 1
end

-- -------------------------------------------------------------------------- --
-- Helper functions
-- -------------------------------------------------------------------------- --

-- Returns whether the given mouse coordinates were in the given rectangle.
-- If no mouse coordinates are given then the current mouse position is used.
imgui.is_mouse_in_rect = function(state, x, y, w, h, mx, my, transform)
  if not state.input then return false end
  mx = mx or state.input.mouse.x
  my = my or state.input.mouse.y
  transform = transform or state.transform
  return Rectangle.contains({x = x, y = y, w = w, h = h},
                            transform:unproject(mx, my))
end

imgui.was_mouse_pressed = function(state, x, y, w, h, button)
  if not state.input then return false end
  local button_state
  if button then
    button_state = state.input.mouse.buttons[button]
  else
    button_state = state.input.mouse.buttons[1]
  end
  if not button_state then return false end
  if button_state.presses < 1 then return false end
  local mx, my = button_state.at_x, button_state.at_y
  local transform = state.transform
  return Rectangle.contains({x = x, y = y, w = w, h = h},
                            transform:unproject(mx, my))
end

imgui.is_mouse_pressed = function(state, x, y, w, h, button)
  if not state.input then return false end
  local button_state
  if button then
    button_state = state.input.mouse.buttons[button]
  else
    button_state = state.input.mouse.buttons[1]
  end
  if not button_state then return false end
  if button_state.presses < 1 then return false end
  local mx, my = button_state.at_x, button_state.at_y
  local transform = state.transform
  return button_state.pressed and
         Rectangle.contains({x = x, y = y, w = w, h = h},
                            transform:unproject(mx, my))
end

imgui.was_key_pressed = function(state, key)
  if not state.input then return false end
  return state.input.keyboard.keys[key] and state.input.keyboard.keys[key].presses > 0
end

imgui.is_key_pressed = function(state, key)
  if not state.input then return false end
  return state.input.keyboard.keys[key] and state.input.keyboard.keys[key].pressed
end

local all_modifiers = {"numlock", "capslock", "scrolllock", "rshift", "lshift",
                       "rctrl", "lctrl", "ralt", "lalt", "rgui", "lgui", "mode"}

imgui.are_exact_modifiers_pressed = function(gui_state, modifiers)
  if not modifiers then return true end
  local wanted_modifiers = {}
  -- First check if all wanted modifiers are present
  local pressed = true
  for _, modifier in ipairs(modifiers) do
    if not pressed then break end
    -- Check for group modifiers like *shift
    local group = string.gmatch(modifier, "%*(.+)")()
    if group ~= "" then
      pressed = pressed and (
        imgui.is_key_pressed(gui_state, "l"..group) or
        imgui.is_key_pressed(gui_state, "r"..group))
      wanted_modifiers["l"..group] = true
      wanted_modifiers["r"..group] = true
    else
      pressed = pressed and imgui.is_key_pressed(gui_state, modifier)
      wanted_modifiers[modifier] = true
    end
  end
  if not pressed then return false end
  -- Now check if any of the other modifiers is pressed, but not desired.
  -- This is necessary to prevent that CTRL-s triggers when CTRL-shift-s is
  -- pressed
  for _, v in ipairs(all_modifiers) do
    if not wanted_modifiers[v] then
      if imgui.is_key_pressed(gui_state, v) then return false end
    end
  end
  return pressed
end

imgui.consume_key_press = function(state, key)
  if not state.input or not state.input.keyboard.keys[key] then return end
  state.input.keyboard.keys[key].presses = math.max(0, state.input.keyboard.keys[key].presses - 1)
end

-- Menu handling

-- Toggles the 'open' state of the menu with the given label.
-- The imgui state knows the current menu depth, so as long as there are no
-- two open menus with the same label on the same level, clashing menu labels
-- should not be a problem
function imgui.toggle_menu(state, label)
  -- Erase all menus on deeper level, no matter if we open or close the menu
  -- on the current level
  for i=state.menu_depth + 2,#state.current_menus do
    state.current_menus[i] = nil
  end

  if imgui.is_menu_open(state, label) then
    -- Close the menu
    state.current_menus[state.menu_depth + 1] = nil
  else
    -- Open the menu
    state.current_menus[state.menu_depth + 1] = label
  end
end

function imgui.is_menu_open(state, label)
  return state.current_menus[state.menu_depth + 1] == label
end

function imgui.is_any_menu_open(state)
  return #state.current_menus > 0
end

function imgui.close_menus(state, from_level)
  if not from_level or from_level == 0 then state.current_menus = {}
  else
    for i=from_level,#state.current_menus - 1 do
      state.current_menus[i + 1] = nil
    end
  end
end

-- Periodic functions

-- This function is run approximately once per second
function imgui.every_second(state, f, ...)
  if not state.second_mark then return end
  f(...)
end

return imgui