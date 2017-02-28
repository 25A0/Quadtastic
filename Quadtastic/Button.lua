local Rectangle = require("Rectangle")

local Button = {}

local buttonquads = {
  ul = love.graphics.newQuad( 0,  0, 3, 3, 128, 128),
   l = love.graphics.newQuad( 0,  3, 3, 1, 128, 128),
  ll = love.graphics.newQuad( 0, 13, 3, 3, 128, 128),
   b = love.graphics.newQuad( 3, 13, 1, 3, 128, 128),
  lr = love.graphics.newQuad(29, 13, 3, 3, 128, 128),
   r = love.graphics.newQuad(29,  3, 3, 1, 128, 128),
  ur = love.graphics.newQuad(29,  0, 3, 3, 128, 128),
   t = love.graphics.newQuad( 3,  0, 1, 3, 128, 128),
   c = love.graphics.newQuad( 3,  3, 1, 1, 128, 128),
}

local draw_border = function(sprite, x, y, w, h)
  -- corners
  love.graphics.draw(sprite, buttonquads.ul, x        , y        )
  love.graphics.draw(sprite, buttonquads.ll, x        , y + h - 3)
  love.graphics.draw(sprite, buttonquads.ur, x + w - 3, y        )
  love.graphics.draw(sprite, buttonquads.lr, x + w - 3, y + h - 3)

  -- borders
  love.graphics.draw(sprite, buttonquads.l, x        , y + 3   , 0, 1  , h-6)
  love.graphics.draw(sprite, buttonquads.r, x + w - 3, y + 3   , 0, 1  , h-6)
  love.graphics.draw(sprite, buttonquads.t, x + 3    , y       , 0, w-6, 1  )
  love.graphics.draw(sprite, buttonquads.b, x + 3    , y + h -3, 0, w-6, 1  )

  -- center
  love.graphics.draw(sprite, buttonquads.c, x + 3, y + 3, 0, w - 6, h - 6)
end

-- Draws a button at the indicated position. Returns, in this, order, whether
-- it was just triggered, whether it is active, and whether the mouse is inside
-- the button's bounding box.
Button.draw = function(state, x, y, w, h, label)
  w = w or 70
  h = h or 18

  -- Draw border
  love.graphics.setColor(255, 255, 255, 255)
  draw_border(stylesprite, x, y, w, h)

  -- Print label
  local margin_x = 4
  local margin_y = (h - 16) / 2
  love.graphics.print(label, x + margin_x, y + margin_y)

  -- Highlight if mouse is over button
  if state and state.mouse and 
    Rectangle(x, y, w, h):contains(state.mouse.x, state.mouse.y)
  then
    local active
    if state.mouse.buttons[1] and state.mouse.buttons[1].pressed then
      love.graphics.setColor(0, 0, 0, 70)
      active = true
    else
      love.graphics.setColor(255, 255, 255, 70)
      active = false
    end
    love.graphics.rectangle("fill", x + 2, y + 2, w - 4, h - 4)
    -- We consider this button clicked when the mouse is in the button's area
    -- and the left mouse button was just clicked
    return state.mouse.buttons[1] and state.mouse.buttons[1].presses > 0,
      active, true
  end
  return false
end

setmetatable(Button, {
  __call = Button.new
})

return Button