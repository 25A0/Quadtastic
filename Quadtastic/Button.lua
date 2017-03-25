local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local renderutils = require(current_folder .. ".Renderutils")
local Text = require(current_folder .. ".Text")
local imgui = require(current_folder .. ".imgui")

local Button = {}

-- Returns, in this order, if the button was just pressed, if the button is still
-- being pressed, and if the button is hovered.
local function handle_input(state, x, y, w, h, options)
  assert(state.input)
  if imgui.is_mouse_in_rect(state, x, y, w, h) then
    local pressed
    if state.input.mouse.buttons[1] and state.input.mouse.buttons[1].pressed then
      pressed = true
    else
      pressed = false
    end
    -- We consider this button clicked when the mouse is in the button's area
    -- and the left mouse button was just clicked, or released
    local clicked = state.input.mouse.buttons[1]
    if options and options.trigger_on_release then
      clicked = clicked and state.input.mouse.buttons[1].releases > 0
    else
      clicked = clicked and state.input.mouse.buttons[1].presses > 0
    end

    return clicked, pressed, true
  end
end

-- Draws a button at the indicated position. Returns, in this, order, whether
-- it was just triggered, whether it is active, and whether the mouse is inside
-- the button's bounding box.
Button.draw = function(state, x, y, w, h, label, iconquad, options)
  x = x or state.layout.next_x
  y = y or state.layout.next_y

  local _, _, iconwidth, iconheight = unpack(iconquad and {iconquad:getViewport()} or {})
  local labelwidth, labelheight = label and Text.min_width(state, label) or nil, label and 16 or nil

  local margin_x = 4
  if not w then
    w = (label and (labelwidth + margin_x) or 0) +
        (iconquad and iconwidth + 3 or 0) +
        (not label and 3 or not iconquad and margin_x or 0)
  end
  if not h then
    h = math.max(label and labelheight + 2 or 0, iconquad and iconheight + 6 or 0)
  end
  -- Also, the button cannot be smaller than the area covered by the border
  w = math.max(w, 6)
  h = math.max(h, 6)

  -- Draw border
  love.graphics.setColor(255, 255, 255, 255)
  local quads
  if options and options.disabled then
    quads = state.style.quads.button_border_disabled
  else
    quads = state.style.quads.button_border
  end

  renderutils.draw_border(state.style.stylesheet, quads, x, y, w, h, 3)

  -- Print label
  if not options then options = {} end
  if not options.font_color then
    options.font_color = {255, 255, 255, 255}
  end
  local next_x = x
  if iconquad then
    love.graphics.setColor(255, 255, 255, 255)
    local margin_y = (h - iconheight) / 2
    love.graphics.draw(state.style.stylesheet, iconquad, x + 3, y + margin_y)
    next_x = next_x + iconwidth
  end
  if label then
    local margin_y = (h - labelheight) / 2
    Text.draw(state, next_x + margin_x, y + margin_y, w - 2*margin_x, h - 2*margin_y, label, options)
  end

  state.layout.adv_x = w
  state.layout.adv_y = h

  -- Highlight if mouse is over button
  if state and state.input and not (options and options.disabled) then
    local clicked, pressed, hovered = handle_input(state, x, y, w, h, options)
    if pressed then
      love.graphics.setColor(0, 0, 0, 70)
    elseif hovered then
      love.graphics.setColor(255, 255, 255, 70)
    end
    if pressed or hovered then
      love.graphics.rectangle("fill", x + 2, y + 2, w - 4, h - 4)
    end
    love.graphics.setColor(255, 255, 255, 255)
    return clicked, pressed, hovered
  else
    return false
  end
end

-- Draws a borderless button. Here, icons needs to be a table containing quads
-- for keys "default", "hovered" and "pressed".
Button.draw_flat = function(state, x, y, w, h, label, icons, options)
  x = x or state.layout.next_x
  y = y or state.layout.next_y

  assert(not icons or icons.default and icons.hovered and icons.pressed)
  local _, _, iconwidth, iconheight = unpack(icons and {icons.default:getViewport()} or {})
  local labelwidth, labelheight = label and Text.min_width(state, label) or nil, label and 16 or nil

  if not w then
    w = (label and labelwidth+2 or 0) +
        (icons and iconwidth or 0)
  end
  if not h then
    h = math.max(label and labelheight or 0, icons and iconheight or 0)
  end

  love.graphics.setColor(255, 255, 255, 255)

  -- Handle input before drawing so that we can decide which quad should be drawn
  local clicked, pressed, hovered
  if state and state.input and not (options and options.disabled) then
    clicked, pressed, hovered = handle_input(state, x, y, w, h, options)
    if pressed then
      local pressed_color = options and options.bg_color_pressed or {0, 0, 0, 90}
      love.graphics.setColor(pressed_color)
    elseif hovered then
      local hovered_color = options and options.bg_color_hovered or {202, 222, 227}
      love.graphics.setColor(hovered_color)
    elseif options and options.bg_color_default then
      love.graphics.setColor(options.bg_color_default)
    end
    if label and (pressed or hovered) and not (options and options.disabled) or
      options and options.bg_color_default
    then
      love.graphics.rectangle("fill", x, y, w, h)
    end
    love.graphics.setColor(255, 255, 255, 255)
  else
    clicked, pressed, hovered = false, false, false
  end

  -- Print label
  if not options then options = {} end
  if not options.font_color then
    options.font_color = {255, 255, 255, 255}
  end
  local next_x = x
  if icons then

    local quad
    if pressed then
      quad = icons.pressed
    elseif hovered then
      quad = icons.hovered
    else
      quad = icons.default
    end

    love.graphics.setColor(255, 255, 255, 255)
    local margin_y = (h - iconheight) / 2
    love.graphics.draw(state.style.stylesheet, quad, x, y + margin_y)
    next_x = next_x + iconwidth + 2 -- small margin between icon and label
  end
  if label then
    local margin_y = (h - labelheight) / 2
    Text.draw(state, next_x + 1, y + margin_y, w, h, label, options)
  end

  state.layout.adv_x = w
  state.layout.adv_y = h

  return clicked, pressed, hovered
end

setmetatable(Button, {
  __call = Button.new
})

return Button