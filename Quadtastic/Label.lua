local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local Rectangle = require(current_folder .. ".Rectangle")
local Text = require(current_folder .. ".Text")
local Label = {}

local function handle_input(state, x, y, w, h)
  assert(state.input)

  local active, hover = false, false
  -- Highlight if mouse is over button
  if Rectangle(x, y, w, h):contains(state.transform:unproject(state.input.mouse.x, state.input.mouse.y))
  then
    hover = true
    if state.input.mouse.buttons[1] and state.input.mouse.buttons[1].pressed then
      active = true
    end
  end
  return active, hover
end

-- Displays the passed in label. Returns, in this order, whether the label
-- is active (i.e. getting clicked on), and whether the mouse is over this
-- label.
Label.draw = function(state, x, y, w, h, label, options)
  x = x or state.layout.next_x
  y = y or state.layout.next_y
  local margin_x = 2
  w = w or state.layout.max_w

  local lines = Text.break_at(state, label, w - 2*margin_x)
  local max_textwidth = 0
  local textwidths = {}
  for i, line in ipairs(lines) do
    textwidths[i] = Text.min_width(state, line)
    if textwidths[i] > max_textwidth then
      max_textwidth = textwidths[i]
    end
  end

  local line_height = 14
  w = w or (max_textwidth + 2 * margin_x)
  h = h or 2 + #lines * line_height

  -- Print label
  local fontcolor = options and options.font_color or {32, 63, 73, 255}
  local total_text_height = line_height * #lines
  local margin_y = (h - total_text_height) / 2
  love.graphics.setColor(fontcolor)
  y = y + margin_y

  if options and options.alignment_v == "-" then
    y = y + (h- 2*margin_y - total_text_height) / 2
  elseif options and options.alignment_v == "v" then
    y = y + h - total_text_height
  end

  for _, line in ipairs(lines) do
    Text.draw(state, x + margin_x, y, w - 2*margin_x, line_height, line, options)
    y = y + line_height
  end

  state.layout.adv_x = (max_textwidth + 2 * margin_x)
  state.layout.adv_y = h + 2 * margin_y

  if state and state.input then
    return handle_input(state, x, y, w, h)
  else return false, false
  end
end

return Label