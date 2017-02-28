local Rectangle = {}

Rectangle.new = function(self, x, y, w, h)
  local rectangle = {
    x = x,
    y = y,
    w = w,
    h = h,
  }

  setmetatable(rectangle, {
    __index = Rectangle,
  })

  return rectangle
end

-- Creates a new Rectangle that is centered around the given point
Rectangle.centered = function(self, x, y, w, h)
  return self:new(x - w/2, y - h/2, w, h)
end

-- Checks whether this rectangle contains the given point
Rectangle.contains = function(self, px, py)
  return px >= self.x and px < self.x + self.w and
         py >= self.y and py < self.y + self.h
end

setmetatable(Rectangle, {
  __call = Rectangle.new
})

return Rectangle

