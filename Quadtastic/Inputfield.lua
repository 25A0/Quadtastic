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
  x = x or state.layout.next_x
  y = y or state.layout.next_y

  local margin_x = 4
  local textwidth = state.style.font and state.style.font:getWidth(content)
  w = w or math.max(32, 2*margin_x + (textwidth or 32))
  h = h or 18

  state.layout.adv_x = w
  state.layout.adv_y = h

  -- Draw border
  love.graphics.setColor(255, 255, 255, 255)
  renderutils.draw_border(stylesprite, quads, x, y, w, h, 3)

  -- Push state
  love.graphics.push("all")

  -- Restrict printing to the encolsed area
  love.graphics.setScissor((x + 2) * 2, (y + 2) * 2, (w - 2) * 2, (h - 2) * 2)

  -- Print label
  local margin_y = (h - 16) / 2

  -- Move text start to the left if text width is larger than field width
  local text_x = x + margin_x
  if textwidth + 20 > w - 6 then
    text_x = text_x - (textwidth + 20 - (w-6))
  end

  love.graphics.print(content, text_x, y + margin_y)

  -- Highlight if mouse is over button
  if state and state.mouse and 
    Rectangle(x, y, w, h):contains(state.mouse.x, state.mouse.y)
  then
    love.graphics.setColor(255, 255, 255, 70)
    love.graphics.rectangle("fill", x + 2, y + 2, w - 4, h - 4)
  end
  content = content .. (state.keyboard.text or "")
  -- Restore state
  love.graphics.pop()
  return content
end

return Inputfield