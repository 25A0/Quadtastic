local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local imgui = require(current_folder .. ".imgui")

local Checkbox = {}

local function handle_input(state, x, y, w, h)
  assert(state.input)
  local button = state.input.mouse.buttons[1]
  if imgui.is_mouse_in_rect(state, x, y, w, h) and button then
    -- We consider this button clicked when the mouse is in the button's area
    -- and the left mouse button was just clicked, or released
    local at_x, at_y = button.at_x, button.at_y
    return button.releases > 0 and
           imgui.is_mouse_in_rect(state, x, y, w, h, at_x, at_y)
  end
end

function Checkbox.draw(gui_state, x, y, w, h, checked)
  x = x or gui_state.layout.next_x
  y = y or gui_state.layout.next_y

  local quads = gui_state.style.quads.checkbox
  local raw_quads = gui_state.style.raw_quads.checkbox

  w = w or raw_quads.unchecked.w
  h = h or raw_quads.unchecked.h

  -- Add margins to center the sprite inside the available area
  local margin_x = (w - raw_quads.unchecked.w) / 2
  local margin_y = (h - raw_quads.unchecked.h) / 2

  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(gui_state.style.stylesheet,
                     quads[checked and "checked" or "unchecked"],
                     x + margin_x, y + margin_y)

  local clicked
  if gui_state.input then
    clicked = handle_input(gui_state, x, y, w, h)
  end
  if clicked then checked = not checked end

  gui_state.layout.adv_x = w
  gui_state.layout.adv_y = h

  return checked
end

return Checkbox