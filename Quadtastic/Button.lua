local Rectangle = require("Rectangle")

local Button = {}

local buttonquads = {
  ul = love.graphics.newQuad( 0,  0, 3, 3, 32, 32),
   l = love.graphics.newQuad( 0,  3, 3, 1, 32, 32),
  ll = love.graphics.newQuad( 0, 13, 3, 3, 32, 32),
   b = love.graphics.newQuad( 3, 13, 1, 3, 32, 32),
  lr = love.graphics.newQuad(29, 13, 3, 3, 32, 32),
   r = love.graphics.newQuad(29,  3, 3, 1, 32, 32),
  ur = love.graphics.newQuad(29,  0, 3, 3, 32, 32),
   t = love.graphics.newQuad( 3,  0, 1, 3, 32, 32),
   c = love.graphics.newQuad( 3,  3, 1, 1, 32, 32),
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

Button.draw = function(state, x, y, w, h, label)
  w = w or 70
  h = h or 18

  -- Draw border
  love.graphics.setColor(255, 255, 255, 255)
  draw_border(buttonsprite, x, y, w, h)

  -- Print label
  local margin_x = 4
  local margin_y = (h - 16) / 2
  love.graphics.print(label, x + margin_x, y + margin_y)

  -- Highlight if mouse is over button
  if state and state.mousex and state.mousey and 
    Rectangle(x, y, w, h):contains(state.mousex, state.mousey)
  then
    if state.mousepressed then
      love.graphics.setColor(0, 0, 0, 100)
    else
      love.graphics.setColor(255, 255, 255, 100)
    end
    love.graphics.rectangle("fill", x + 2, y + 2, w - 4, h - 4)
  end
end

setmetatable(Button, {
  __call = Button.new
})

return Button