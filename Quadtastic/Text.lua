local Text = {}

local unpack = unpack or table.unpack

Text.min_width = function(state, text)
  return state.style.font and state.style.font:getWidth(text)
end

Text.draw = function(state, x, y, w, h, text, options)
  x = x or state.layout.next_x
  y = y or state.layout.next_y

  local textwidth = Text.min_width(state, text)
  local textheight = 16
  w = w or textwidth
  h = h or textheight

  if options then
    -- center alignment
    if options.alignment_h == ":" then
      x = x + w/2 - textwidth /2

    -- right alignment
    elseif options.alignment_h == ">" then
      x = x + w - textwidth
    end

    -- vertically aligned to the center
    if options.alignment_v == "-" then
      y = y + h/2 - textheight/2

    -- aligned to the bottom
    elseif options.alignment_v == "v" then
      y = y + h - textheight
    end
  end

  love.graphics.setFont(state.style.font)
  -- Print Text
  if options and options.font_color then
    love.graphics.setColor(unpack(options.font_color))
  end
  love.graphics.print(text or "", x, y)
end

return Text