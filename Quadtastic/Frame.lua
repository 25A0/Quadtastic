local Rectangle = require("Rectangle")
local renderutils = require("Renderutils")
local Layout = require("Layout")
local Frame = {}

Frame.start = function(state, x, y, w, h, options)
  x = x or state.layout.next_x
  y = y or state.layout.next_y

  w = w or state.layout.max_w
  h = h or state.layout.max_h

  -- Draw border
  love.graphics.setColor(255, 255, 255, 255)
  local quads = options and options.quads or state.style.quads.frame_border
  local bordersize = options and options.bordersize or 2
  renderutils.draw_border(state.style.stylesheet, quads, x, y, w, h, bordersize)

  local margin = options and options.margin or 2
  Layout.start(state, x+margin, y+margin, w - 2*margin, h - 2*margin)
end

Frame.finish = function(state, w, h, options)
  local margin = options and options.margin or 2
  state.layout.adv_x = w or state.layout.max_w + 2*margin
  state.layout.adv_y = h or state.layout.max_h + 2*margin
  Layout.finish(state)

end

return Frame