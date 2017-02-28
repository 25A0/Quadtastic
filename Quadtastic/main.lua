local inspect = require("lib/inspect")

unpack = unpack or table.unpack

if os.getenv("DEBUG") then
  require("lib/lovedebug/lovedebug")
  require("debugconfig")
end

local Button = require("Button")
local mousex, mousey

-- Scaling factor
local scale = 2

button = Button:new("Hello World!", nil, 200, 150)

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  font = love.graphics.newFont("res/m5x7.ttf", 16)
  love.graphics.setFont(font)

  buttonsprite = love.graphics.newImage("res/button.png")
end

function love.draw()
  love.graphics.scale(scale, scale)
  button:draw(mousex, mousey)
end

function love.mousepressed(x, y, button)

end

function love.mousemoved(x, y, dx, dy)
	mousex, mousey = x / scale, y / scale

end


function love.update()
end
