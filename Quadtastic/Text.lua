local Rectangle = require("Rectangle")
local renderutils = require("Renderutils")
local Text = {}

unpack = unpack or table.unpack

Text.min_width = function(state, text)
  return state.style.font and state.style.font:getWidth(text)
end

Text.draw = function(state, x, y, w, h, text, options)
  x = x or state.layout.next_x
  y = y or state.layout.next_y

  local textwidth = Text.min_width(state, text)
  w = w or textwidth
  h = h or 16

  if options then
    -- center alignment
    if options.alignment == ":" then
      x = x + w/2 - textwidth /2

    -- right alignment
    elseif options.alignment == ">" then
      x = x + w - textwidth
    end

  end

  state.layout.adv_x = w
  state.layout.adv_y = h

  -- Print Text
  if options and options.font_color then
    love.graphics.setColor(unpack(options.font_color))
  end
  love.graphics.print(text or "", x, y)
end

return Text