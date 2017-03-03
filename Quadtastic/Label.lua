local Rectangle = require("Rectangle")
local renderutils = require("Renderutils")
local Label = {}

-- Displays the passed in label. Returns, in this order, whether the label
-- is active (i.e. getting clicked on), and whether the mouse is over this
-- label.
Label.draw = function(state, x, y, w, h, label, options)
  x = x or state.layout.next_x
  y = y or state.layout.next_y

  local margin_x = 4
  local textwidth = state.style.font and state.style.font:getWidth(label)
  w = w or math.max(32, 2*margin_x + (textwidth or 32))
  h = h or 18

  if options then
    -- center alignment
    if options.alignment == ":" then
      x = x + w/2 - textwidth /2 - margin_x

    -- right alignment
    elseif options.alignment == ">" then
      x = x + w - textwidth - 2 * margin_x

    end

  end

  state.layout.adv_x = w
  state.layout.adv_y = h

  -- Print label
  love.graphics.setColor(32, 63, 73, 255)
  local margin_y = (h - 16) / 2
  love.graphics.print(label or "", x + margin_x, y + margin_y)

  local active, hover = false, false
  -- Highlight if mouse is over button
  if state and state.mouse and 
    Rectangle(x, y, w, h):contains(state.transform.unproject(state.mouse.x, state.mouse.y))
  then
    hover = true
    if state.mouse.buttons[1] and state.mouse.buttons[1].pressed then
      active = true
    end
  end
  return active, hover
end

return Label