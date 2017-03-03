local Rectangle = require("Rectangle")
local renderutils = require("Renderutils")
local Layout = require("Layout")
local Frame = {}

local transform = require("transform")

local quads = renderutils.border_quads(48, 0, 16, 16, 128, 128, 2)

Frame.start = function(state, x, y, w, h)
  x = x or state.layout.next_x
  y = y or state.layout.next_y

  w = w or state.layout.max_w
  h = h or state.layout.max_h

  -- Draw border
  love.graphics.setColor(255, 255, 255, 255)
  renderutils.draw_border(state.style.stylesheet, quads, x, y, w, h, 2)

  Layout.start(state, x+2, y+2, w - 4, h - 4)
end

Frame.finish = function(state, w, h)
  state.layout.adv_x = w or state.layout.max_w + 4
  state.layout.adv_y = h or state.layout.max_h + 4
  Layout.finish(state)

end

return Frame