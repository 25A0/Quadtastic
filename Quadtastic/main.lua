local inspect = require("lib/inspect")

unpack = unpack or table.unpack

if os.getenv("DEBUG") then
  require("lib/lovedebug/lovedebug")
  require("debugconfig")
end

local Button = require("Button")
local mousex, mousey

button = Button:new("Hello World!", nil, 400, 300)

function love.load()
  font = love.graphics.newFont("res/m5x7.ttf", 16)
  love.graphics.setFont(font)

  buttonsprite = love.graphics.newImage("res/button.png")
end

function love.draw()
  button:draw(mousex, mousey)
end

function love.mousepressed(x, y, button)

end

function love.mousemoved(x, y, dx, dy)
	mousex, mousey = x, y

end


function love.update()
end
