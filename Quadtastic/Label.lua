local Rectangle = require("Rectangle")
local renderutils = require("Renderutils")
local Text = require("Text")
local Label = {}

-- Displays the passed in label. Returns, in this order, whether the label
-- is active (i.e. getting clicked on), and whether the mouse is over this
-- label.
Label.draw = function(state, x, y, w, h, label, options)
  x = x or state.layout.next_x
  y = y or state.layout.next_y

  local textwidth = Text.min_width(state, label)
  local margin_x = 4
  w = w or (textwidth + 2 * margin_x)
  h = h or 18

  -- Print label
  local fontcolor = options and options.font_color or {32, 63, 73, 255}
  local margin_y = 2
  Text.draw(state, x + margin_x, y + margin_y, w - 2*margin_x, h - 2*margin_y, label, options)

  local active, hover = false, false
  -- Highlight if mouse is over button
  if state and state.mouse and 
    Rectangle(x, y, w, h):contains(state.transform:unproject(state.mouse.x, state.mouse.y))
  then
    hover = true
    if state.mouse.buttons[1] and state.mouse.buttons[1].pressed then
      active = true
    end
  end

  state.layout.adv_x = w
  state.layout.adv_y = h

  return active, hover
end

return Label