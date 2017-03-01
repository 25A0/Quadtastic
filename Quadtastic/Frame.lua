local Rectangle = require("Rectangle")
local renderutils = require("Renderutils")
local Frame = {}

local quads = renderutils.border_quads(48, 0, 16, 16, 128, 128, 2)

Frame.start = function(state, x, y, w, h)
  x = x or state.layout.next_x
  y = y or state.layout.next_y

  state.layout.adv_x = w
  state.layout.adv_y = h

  -- Draw border
  love.graphics.setColor(255, 255, 255, 255)
  renderutils.draw_border(stylesprite, quads, x, y, w, h, 2)

  -- Push state
  love.graphics.push("all")

  -- Restrict printing to the encolsed area
  love.graphics.setScissor((x + 2) * 2, (y + 2) * 2, (w - 4) * 2, (h - 4) * 2)

  -- Translate so that 0, 0 will be at the upper left corner of the inside of
  -- the frame. The +2 corrects for the border.
  love.graphics.translate(x + 2, y + 2)

end

Frame.finish = function(state)
  -- Restore state
  love.graphics.pop()
end

return Frame