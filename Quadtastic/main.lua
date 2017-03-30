local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
package.cpath = package.cpath .. string.format(";%s/shared/%s/?.so", love.filesystem.getSourceBaseDirectory(), love.system.getOS())

if os.getenv("DEBUG") then
  -- require("lib/lovedebug/lovedebug")
  require("debugconfig")
end

local imgui = require(current_folder .. ".imgui")

local AppLogic = require(current_folder .. ".AppLogic")
local Quadtastic = require(current_folder .. ".Quadtastic")
local libquadtastic = require(current_folder .. ".libquadtastic")

local Transform = require(current_folder .. '.Transform')
local Toast = require(current_folder .. '.Toast')
local Text = require(current_folder .. '.Text')
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
  local version_info = love.filesystem.read("res/version.txt")
  love.window.setTitle(love.window.getTitle() .. " " .. version_info)

  -- Initialize the state
  app = AppLogic(Quadtastic)
  app.quadtastic.new()

  love.graphics.setDefaultFilter("nearest", "nearest")

  local med_font = love.graphics.newFont("res/m5x7.ttf", 16)
  med_font:setFilter("nearest", "nearest")
  local smol_font = love.graphics.newFont("res/m3x6.ttf", 16)
  smol_font:setFilter("nearest", "nearest")
  love.graphics.setFont(med_font)

  local stylesheet = love.graphics.newImage("res/style.png")
  local icon = love.graphics.newImage("res/icon-32x32.png")

  love.keyboard.setKeyRepeat(true)
  gui_state = imgui.init_state(transform)
  gui_state.style.small_font = smol_font
  gui_state.style.med_font = med_font
  gui_state.style.font = med_font
  gui_state.style.stylesheet = stylesheet
  gui_state.style.icon = icon
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

  -- Draw toasts
  local remaining_toasts = {}
  local frame_bounds = gui_state.transform:project_bounds({x = 0, y = 0, w = w, h = h})
  for _,toast in ipairs(gui_state.toasts) do
    toast.remaining = toast.remaining - gui_state.dt
    Toast.draw(gui_state, toast.label, toast.bounds or frame_bounds, toast.start, toast.duration)
    -- Keep this toast only if it should still be drawn in the next frame
    if toast.remaining > 0 then
      table.insert(remaining_toasts, toast)
    end
  end
  gui_state.toasts = remaining_toasts

  -- Draw string next to mouse cursor
  if gui_state.mousestring then
    love.graphics.push("all")
    love.graphics.setCanvas(gui_state.overlay_canvas)
    local mx, my = gui_state.input.mouse.x, gui_state.input.mouse.y
    local x, y = gui_state.transform:unproject(mx + 10, my + 10)
    -- Draw dark background for better readability
    love.graphics.setColor(53, 53, 53, 192)
    love.graphics.rectangle("fill", x-2, y + 2,
                            Text.min_width(gui_state, gui_state.mousestring) + 4, 12)
    love.graphics.setColor(255, 255, 255)
    Text.draw(gui_state, x, y, nil, nil, gui_state.mousestring)
    love.graphics.setCanvas()
    love.graphics.pop()
    gui_state.mousestring = nil
  end


  love.graphics.origin()
  love.graphics.draw(gui_state.overlay_canvas)

  imgui.end_frame(gui_state)
end

function love.quit()
  if os.getenv("DEBUG") then return false end
  if app and app._should_quit then return false
  else
    app.quadtastic.quit()
    return true
  end
end

-- Override isActive function to snooze app when it is not in focus.
-- This is only noticeable in that the dashed lines around selected quads will
-- stop changing.
local has_focus = true
local isActive = love.graphics.isActive
function love.graphics.isActive() return isActive() and has_focus end

function love.focus(f)
  has_focus = f
end

function love.filedropped(file)
  -- Override focus
  has_focus = true
  app.quadtastic.load_dropped_file(file:getFilename())
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
