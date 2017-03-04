local Rectangle = require("Rectangle")
local renderutils = require("Renderutils")
local Label = require("Label")

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

-- Draws a button at the indicated position. Returns, in this, order, whether
-- it was just triggered, whether it is active, and whether the mouse is inside
-- the button's bounding box.
Button.draw = function(state, x, y, w, h, label, options)
  x = x or state.layout.next_x
  y = y or state.layout.next_y

  w = w or Label.min_width(state, label)
  h = h or 18

  state.layout.adv_x = w
  state.layout.adv_y = h

  -- Draw border
  love.graphics.setColor(255, 255, 255, 255)
  renderutils.draw_border(state.style.stylesheet, buttonquads, x, y, w, h, 3)

  -- Print label
  if not options then options = {} end
  if not options.font_color then
    options.font_color = {255, 255, 255, 255}
  end
  Label.draw(state, x, y, w, h, label, options)

  -- Highlight if mouse is over button
  if state and state.mouse and 
    Rectangle(x, y, w, h):contains(state.transform.unproject(state.mouse.x, state.mouse.y))
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