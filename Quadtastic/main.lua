local inspect = require("lib/inspect")

unpack = unpack or table.unpack

if os.getenv("DEBUG") then
  require("lib/lovedebug/lovedebug")
  require("debugconfig")
end

local imgui = require("imgui")

local Button = require("Button")
local state

-- Scaling factor
local scale = 2

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  font = love.graphics.newFont("res/m5x7.ttf", 16)
  love.graphics.setFont(font)

  buttonsprite = love.graphics.newImage("res/button.png")

  love.keyboard.setKeyRepeat(true)
  state = imgui.init_state()
end

function love.draw()
  imgui.begin_frame(state)
  love.graphics.scale(scale, scale)
  Button.draw(state, 200, 150, nil, nil, "Hello World!")


  imgui.end_frame(state)
end

local function unproject(x, y)
  return x / scale, y / scale
end

function love.mousepressed(x, y, button)
  x, y = unproject(x, y)
  imgui.mousepressed(state, x, y, button)
end

function love.mousereleased(x, y, button)
  x, y = unproject(x, y)
  imgui.mousereleased(state, x, y, button)
end

function love.mousemoved(x, y, dx, dy)
  x ,  y = unproject(x ,  y)
  dx, dy = unproject(dx, dy)
  imgui.mousemoved(state, x, y, dx, dy)
end

function love.wheelmoved(x, y)
  imgui.wheelmoved(state, x, y)
end

function love.keypressed(key, scancode, isrepeat)
  imgui.keypressed(state, key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
  imgui.keyreleased(state, key, scancode, isrepeat)
end

function love.textinput(text)
  imgui.textinput(state, text)
end

function love.update()

end
