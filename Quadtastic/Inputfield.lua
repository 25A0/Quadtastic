local Rectangle = require("Rectangle")
local renderutils = require("Renderutils")
local Inputfield = {}

local quads = {
  ul = love.graphics.newQuad( 0, 16, 3, 3, 128, 128),
   l = love.graphics.newQuad( 0, 19, 3, 1, 128, 128),
  ll = love.graphics.newQuad( 0, 29, 3, 3, 128, 128),
   b = love.graphics.newQuad( 3, 29, 1, 3, 128, 128),
  lr = love.graphics.newQuad(29, 29, 3, 3, 128, 128),
   r = love.graphics.newQuad(29, 19, 3, 1, 128, 128),
  ur = love.graphics.newQuad(29, 16, 3, 3, 128, 128),
   t = love.graphics.newQuad( 3, 16, 1, 3, 128, 128),
   c = love.graphics.newQuad( 3, 19, 1, 1, 128, 128),
}

Inputfield.draw = function(state, x, y, w, h, content)
  w = w or 70
  h = h or 18

  -- Draw border
  love.graphics.setColor(255, 255, 255, 255)
  renderutils.draw_border(stylesprite, quads, x, y, w, h)

  -- Print label
  local margin_x = 4
  local margin_y = (h - 16) / 2
  love.graphics.print(content, x + margin_x, y + margin_y)

  -- Highlight if mouse is over button
  if state and state.mouse and 
    Rectangle(x, y, w, h):contains(state.mouse.x, state.mouse.y)
  then
    love.graphics.setColor(255, 255, 255, 70)
    love.graphics.rectangle("fill", x + 2, y + 2, w - 4, h - 4)
  end
  content = content .. (state.keyboard.text or "")
  return content
end

return Inputfield