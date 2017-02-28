local inspect = require("lib/inspect")

unpack = unpack or table.unpack

if os.getenv("DEBUG") then
  require("lib/lovedebug/lovedebug")
  require("debugconfig")
end

local Button = require("Button")
local state = {}

-- Scaling factor
local scale = 2

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  font = love.graphics.newFont("res/m5x7.ttf", 16)
  love.graphics.setFont(font)

  buttonsprite = love.graphics.newImage("res/button.png")
end

function love.draw()
  love.graphics.scale(scale, scale)
  Button.draw(state, 200, 150, nil, nil, "Hello World!")
end

function love.mousepressed(x, y, button)
  state.mousepressed = true
end

function love.mousereleased(x, y, button)
  state.mousepressed = false
end

function love.mousemoved(x, y, dx, dy)
	state.mousex, state.mousey = x / scale, y / scale

end


function love.update()
end
