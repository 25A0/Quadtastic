local Rectangle = {}

Rectangle.new = function(_, x, y, w, h)
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

-- Returns the center of the rectangle
Rectangle.center = function(self)
  return self.x + self.w/2, self.y + self.h/2
end

-- Checks whether this rectangle contains the given point or rectangle
Rectangle.contains = function(self, px, py, pw, ph)
  return px >= self.x and px < self.x + self.w and
         py >= self.y and py < self.y + self.h and
         (not pw or px + pw >= self.x and px + pw < self.x + self.w) and
         (not ph or py + ph >= self.y and py + ph < self.y + self.h)
end

setmetatable(Rectangle, {
  __call = Rectangle.new
})

return Rectangle

