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

Button.new = function(self, label, icon, x, y, w, h, rgba, textrgba)
  local button = {
    label = label or "Button",
    icon = nil,
    r = Rectangle(x or 0,
                  y or 0,
                  w or 70,
                  h or 16),
    rgba = rgba or {0, 0, 0, 255},
    textrgba = textrgba or {37, 82, 105, 255}, 
  }

  setmetatable(button, {
    __index = Button,
  })

  return button
end

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
  love.graphics.draw(sprite, buttonquads.b, x + 3    , y + h -6, 0, w-6, 1  )
  -- center
  love.graphics.draw(sprite, buttonquads.c, x + 3, y + 3, 0, w - 6, h - 6)
end

Button.draw = function(self, mousex, mousey)
  love.graphics.setColor(unpack(self.rgba))
  love.graphics.rectangle("fill", self.r.x, self.r.y, self.r.w, self.r.h)
  love.graphics.setColor(255, 255, 255, 255)
  draw_border(buttonsprite, self.r.x, self.r.y, self.r.w, self.r.h)
  local margin_x = 4
  local margin_y = (self.r.h - 16) / 2
  love.graphics.setColor(unpack(self.textrgba))
  love.graphics.print(self.label, self.r.x + margin_x, self.r.y + margin_y)
  if mousex and mousey and self.r:contains(mousex, mousey) then
    love.graphics.setColor(255, 255, 255, 100)
    love.graphics.rectangle("fill", self.r.x, self.r.y, self.r.w, self.r.h)
  end
end

Button.text = function(self, label, x, y, w, h, rgba)
	return Button.new(label, nil, x, y, w, h, rgba)
end

Button.icon = function(self, icon, x, y, w, h, rgba)
	return Button.new(label, "", icon, x, y, w, h, rgba)
end

setmetatable(Button, {
  __call = Button.new
})

return Button