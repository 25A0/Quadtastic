local inspect = require("lib/inspect")

unpack = unpack or table.unpack

if os.getenv("DEBUG") then
  require("lib/lovedebug/lovedebug")
  require("debugconfig")
end

local imgui = require("imgui")

local Button = require("Button")
local Inputfield = require("Inputfield")
local gui_state
local state = {
  filepath = "", -- the path to the file that we want to edit
}

-- Scaling factor
local scale = 2

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  font = love.graphics.newFont("res/m5x7.ttf", 16)
  love.graphics.setFont(font)

  stylesprite = love.graphics.newImage("res/style.png")

  love.keyboard.setKeyRepeat(true)
  gui_state = imgui.init_state()
end

local count = 0
function love.draw()
  imgui.begin_frame(gui_state)
  love.graphics.scale(scale, scale)
  state.filepath = Inputfield.draw(gui_state, 10, 150, 180, 18, state.filepath)

  local pressed, active = Button.draw(gui_state, 200, 150, nil, nil, "Hello World!")
  if pressed then count = count + 1 end
  Button.draw(gui_state, 200, 170, nil, nil, tostring(count))
  local text = ""
  if active then text = "\\o/" end
  Button.draw(gui_state, 200, 190, nil, nil, text)

  imgui.end_frame(gui_state)
end

local function unproject(x, y)
  return x / scale, y / scale
end

function love.mousepressed(x, y, button)
  x, y = unproject(x, y)
  imgui.mousepressed(gui_state, x, y, button)
end

function love.mousereleased(x, y, button)
  x, y = unproject(x, y)
  imgui.mousereleased(gui_state, x, y, button)
end

function love.mousemoved(x, y, dx, dy)
  x ,  y = unproject(x ,  y)
  dx, dy = unproject(dx, dy)
  imgui.mousemoved(gui_state, x, y, dx, dy)
end

function love.wheelmoved(x, y)
  imgui.wheelmoved(gui_state, x, y)
end

function love.keypressed(key, scancode, isrepeat)
  imgui.keypressed(gui_state, key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
  imgui.keyreleased(gui_state, key, scancode, isrepeat)
end

function love.textinput(text)
  imgui.textinput(gui_state, text)
end

function love.update()

end
