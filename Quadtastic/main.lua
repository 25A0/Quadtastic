local inspect = require("lib/inspect")

unpack = unpack or table.unpack

if os.getenv("DEBUG") then
  require("lib/lovedebug/lovedebug")
  require("debugconfig")
end

local imgui = require("imgui")

local Button = require("Button")
local Inputfield = require("Inputfield")
local Label = require("Label")
local Frame = require("Frame")
local Layout = require("Layout")
local Window = require("Window")
local Scrollpane = require("Scrollpane")
local Tooltip = require("Tooltip")
local ImageEditor = require("ImageEditor")
local QuadList = require("QuadList")
local AppModel = require("AppModel")

-- Make the state variables local unless we are in debug mode
if not _DEBUG then
  local gui_state
  local state
end

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

local load_image_from_path = function(filepath)
  local success, more = pcall(function()
    local filehandle, err = io.open(filepath, "rb")
    if err then print(err); return false end
    local data = filehandle:read("*a")
    filehandle:close()
    local imagedata = love.image.newImageData(
      love.filesystem.newFileData(data, 'img', 'file'))
    return love.graphics.newImage(imagedata)
  end)

  -- success, more = pcall(love.graphics.newImage, data)
  if success then
    state.image = more
    state.filepath = filepath
  else
    print(more)
  end
  return success
end

local reset_view = function(state)
  state.scrollpane_state = Scrollpane.init_scrollpane_state()
  state.display.zoom = 1
  if state.image then
    Scrollpane.set_focus(state.scrollpane_state, {
      x = 0, y = 0, 
      w = state.image:getWidth(), h = state.image:getHeight()
    }, "immediate")
  end
end

function love.load()
  -- Initialize the state
  state = AppModel()

  love.window.setMode(800, 600, {resizable=true, minwidth=400, minheight=300})

  love.graphics.setDefaultFilter("nearest", "nearest")

  local med_font = love.graphics.newFont("res/m5x7.ttf", 16)
  local smol_font = love.graphics.newFont("res/m3x6.ttf", 16)
  love.graphics.setFont(med_font)

  local stylesheet = love.graphics.newImage("res/style.png")

  backgroundcanvas = love.graphics.newCanvas(8, 8)
  do
    -- Create a canvas with the background texture on it
    backgroundquad = love.graphics.newQuad(48, 16, 8, 8, 128, 128)
    backgroundcanvas:setWrap("repeat", "repeat")
    backgroundcanvas:renderTo(function()
      love.graphics.draw(stylesheet, backgroundquad)
    end)
  end

  love.keyboard.setKeyRepeat(true)
  gui_state = imgui.init_state(transform)
  gui_state.style.small_font = smol_font
  gui_state.style.med_font = med_font
  gui_state.style.font = med_font
  gui_state.style.stylesheet = stylesheet
  gui_state.style.rowbackground = {
    top    = love.graphics.newQuad(0, 32, 1, 2, 128, 128),
    center = love.graphics.newQuad(0, 34, 1, 1, 128, 128),
    bottom = love.graphics.newQuad(0, 46, 1, 2, 128, 128),
  }
  gui_state.style.buttonicons = {
    plus  = love.graphics.newQuad(64, 0, 5, 5, 128, 128),
    minus = love.graphics.newQuad(69, 0, 5, 5, 128, 128),
    rename = love.graphics.newQuad(48, 64, 13, 13, 128, 128),
    delete = love.graphics.newQuad(96, 64, 13, 13, 128, 128),
    sort = love.graphics.newQuad(112, 64, 13, 13, 128, 128),
    group = love.graphics.newQuad(96, 48, 13, 13, 128, 128),
    ungroup = love.graphics.newQuad(112, 48, 13, 13, 128, 128),
  }
  gui_state.overlay_canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
end

local count = 0
function love.draw()
  imgui.begin_frame(gui_state)
  love.graphics.scale(scale, scale)

  gui_state.overlay_canvas:renderTo(function() love.graphics.clear() end)

  love.graphics.clear(203, 222, 227)
  local w, h = gui_state.transform:unproject_dimensions(
    love.graphics.getWidth(), love.graphics.getHeight()
  )
  do Window.start(gui_state, 0, 0, w, h, {margin = 2})

    do Layout.start(gui_state)
      Label.draw(gui_state, nil, nil, nil, nil, "File:")
      Layout.next(gui_state, "-", 2)

      state.filepath = Inputfield.draw(gui_state, nil, nil, 160, nil, state.filepath)
      Layout.next(gui_state, "-", 2)

      local pressed, active = Button.draw(gui_state, nil, nil, nil, nil, "Doggo!!")
      if pressed and load_image_from_path(state.filepath) then 
        reset_view(state)
        -- Try to read a quad file
        local quadfilename = AppModel.find_lua_file(state.filepath)
        print(quadfilename)
        local filehandle, more = io.open(quadfilename, "r")
        if filehandle then
          filehandle:close()
          state.quads = loadfile(quadfilename)()
        end
      end
      Tooltip.draw(gui_state, "Who's a good boy??")
    end Layout.finish(gui_state, "-")

    Layout.next(gui_state, "|", 2)

    do Layout.start(gui_state, nil, nil, nil, gui_state.layout.max_h - 30)
      do Frame.start(gui_state, nil, nil, gui_state.layout.max_w - 160, nil)
        if state.image then
          ImageEditor.draw(gui_state, state)
        else
          -- Put a label in the center of the frame
          local y = gui_state.layout.max_h / 2 - gui_state.style.font:getHeight()
          Label.draw(gui_state, nil, y, gui_state.layout.max_w, nil,
                     "no image :(", {alignment = ":"})
        end
      end Frame.finish(gui_state)

      Layout.next(gui_state, "-", 2)

      do Layout.start(gui_state, nil, nil, gui_state.layout.max_w - 21)
        -- Draw the list of quads
        QuadList.draw(gui_state, state, nil, nil, nil, gui_state.layout.max_h - 19)

        Layout.next(gui_state, "|")

        if Button.draw(gui_state, nil, nil, gui_state.layout.max_w, nil, "EXPORT", nil, {alignment = ":"}) then
          state:export()
        end
      end Layout.finish(gui_state, "|")

      Layout.next(gui_state, "-", 2)

      -- Draw button column
      do Layout.start(gui_state)
        Button.draw(gui_state, nil, nil, nil, nil, nil, gui_state.style.buttonicons.rename)
        Tooltip.draw(gui_state, "Rename")
        Layout.next(gui_state, "|")
        Button.draw(gui_state, nil, nil, nil, nil, nil, gui_state.style.buttonicons.delete)
        Tooltip.draw(gui_state, "Delete")
        Layout.next(gui_state, "|")
        Button.draw(gui_state, nil, nil, nil, nil, nil, gui_state.style.buttonicons.sort)
        Tooltip.draw(gui_state, "Sort unnamed quads from top to bottom, left to right")
        Layout.next(gui_state, "|")
        Button.draw(gui_state, nil, nil, nil, nil, nil, gui_state.style.buttonicons.group)
        Tooltip.draw(gui_state, "Group selected quads")
        Layout.next(gui_state, "|")
        Button.draw(gui_state, nil, nil, nil, nil, nil, gui_state.style.buttonicons.ungroup)
        Tooltip.draw(gui_state, "Ungroup selected quads")
      end Layout.finish(gui_state, "|")
    end Layout.finish(gui_state, "-")

    Layout.next(gui_state, "|", 2)

    do Layout.start(gui_state)
      do
        local pressed = Button.draw(gui_state, nil, nil, nil, nil, nil, 
          gui_state.style.buttonicons.plus)
        if pressed then
          state:zoom_in()
        end
        Tooltip.draw(gui_state, "Zoom in")
      end
      Layout.next(gui_state, "-")
      do
        local pressed = Button.draw(gui_state, nil, nil, nil, nil, nil, 
          gui_state.style.buttonicons.minus)
        if pressed then
          state:zoom_out()
        end
        Tooltip.draw(gui_state, "Zoom out")
      end

    end Layout.finish(gui_state, "-")

  end Window.finish(gui_state)

  love.graphics.origin()
  love.graphics.draw(gui_state.overlay_canvas)

  imgui.end_frame(gui_state)
end

function love.filedropped(file)
  if load_image_from_path(file:getFilename()) then
    reset_view(state)
  end
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

function love.keypressed(key, scancode, isrepeat)
  imgui.keypressed(gui_state, key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
  imgui.keyreleased(gui_state, key, scancode, isrepeat)
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
