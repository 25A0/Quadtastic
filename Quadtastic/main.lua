package.cpath = package.cpath .. string.format(";%s/shared/?.so", love.filesystem.getSourceBaseDirectory())

if os.getenv("DEBUG") then
  -- require("lib/lovedebug/lovedebug")
  require("debugconfig")
end

local imgui = require("imgui")

local AppLogic = require("AppLogic")
local Quadtastic = require("Quadtastic")
local libquadtastic = require("libquadtastic")

local Transform = require('Transform')
local transform = Transform()

-- Cover love transformation functions
do
  local lg = love.graphics
  lg.translate = function(...) transform:translate(...) end
  lg.rotate = function(...) transform:rotate(...) end
  lg.scale = function(...) transform:scale(...) end
  lg.shear = function(...) transform:shear(...) end
  lg.origin = function(...) transform:origin(...) end
  lg.push = function(...) transform:push(...) end
  lg.pop = function(...) transform:pop(...) end
end

-- Scaling factor
local scale = 2

local app
local gui_state

function love.load()
  -- Initialize the state
  app = AppLogic(Quadtastic)

  love.window.setMode(800, 600, {resizable=true, minwidth=400, minheight=300})

  love.graphics.setDefaultFilter("nearest", "nearest")

  local med_font = love.graphics.newFont("res/m5x7.ttf", 16)
  local smol_font = love.graphics.newFont("res/m3x6.ttf", 16)
  love.graphics.setFont(med_font)

  local stylesheet = love.graphics.newImage("res/style.png")

  love.keyboard.setKeyRepeat(true)
  gui_state = imgui.init_state(transform)
  gui_state.style.small_font = smol_font
  gui_state.style.med_font = med_font
  gui_state.style.font = med_font
  gui_state.style.stylesheet = stylesheet
  gui_state.style.raw_quads = require("res/style")
  gui_state.style.quads = libquadtastic.import_quads(gui_state.style.raw_quads,
    stylesheet:getWidth(), stylesheet:getHeight())

  gui_state.style.backgroundcanvas = love.graphics.newCanvas(8, 8)
  do
    -- Create a canvas with the background texture on it
    gui_state.style.backgroundcanvas:setWrap("repeat", "repeat")
    gui_state.style.backgroundcanvas:renderTo(function()
      love.graphics.draw(stylesheet, gui_state.style.quads.background)
    end)
  end

  gui_state.overlay_canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
end

function love.draw()
  imgui.begin_frame(gui_state)
  love.graphics.scale(scale, scale)

  gui_state.overlay_canvas:renderTo(function() love.graphics.clear() end)

  local w, h = gui_state.transform:unproject_dimensions(
    love.graphics.getWidth(), love.graphics.getHeight()
  )
  if app:has_active_state_changed() then
    imgui.reset_input(gui_state)
  end
  for _, statebundle in ipairs(app:get_states()) do
    local state, is_active = statebundle[1], statebundle[2]
    if not state.draw then
      print(string.format("Don't know how to display %s", state.name))
    else
      if not is_active then imgui.cover_input(gui_state) end
      local f = state.draw
      -- Draw that state with the draw function
      love.graphics.setColor(32, 63, 73, 60)
      love.graphics.rectangle("fill", 0, 0, w, h)
      love.graphics.setColor(255, 255, 255, 255)
      f(app, state.data, gui_state, w, h)
      if not is_active then imgui.uncover_input(gui_state) end
    end
  end

  love.graphics.origin()
  love.graphics.draw(gui_state.overlay_canvas)

  imgui.end_frame(gui_state)
end

function love.filedropped(file)
  app.quadtastic.load_image_from_path(file:getFilename())
end

function love.mousepressed(x, y, button)
  x, y = x, y
  imgui.mousepressed(gui_state, x, y, button)
end

function love.mousereleased(x, y, button)
  x, y = x, y
  imgui.mousereleased(gui_state, x, y, button)
end

function love.mousemoved(x, y, dx, dy)
  x ,  y = x ,  y
  dx, dy = dx, dy
  imgui.mousemoved(gui_state, x, y, dx, dy)
end

function love.wheelmoved(x, y)
  imgui.wheelmoved(gui_state, x, y)
end

function love.keypressed(key, scancode)
  imgui.keypressed(gui_state, key, scancode)
end

function love.keyreleased(key, scancode)
  imgui.keyreleased(gui_state, key, scancode)
end

function love.textinput(text)
  imgui.textinput(gui_state, text)
end

function love.update(dt)
  imgui.update(gui_state, dt)
end

function love.resize(new_w, new_h)
  gui_state.overlay_canvas = love.graphics.newCanvas(new_w, new_h)
end
