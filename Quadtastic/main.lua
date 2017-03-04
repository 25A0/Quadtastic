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
local Scrollpane = require("Scrollpane")

-- Make the state variables local unless we are in debug mode
if not _DEBUG then
  local gui_state
  local state
end

local transform = require('Quadtastic/transform')

-- Cover love transformation functions
do
  local lg = love.graphics
  lg.translate = transform.translate
  lg.rotate = transform.rotate
  lg.scale = transform.scale
  lg.shear = transform.shear
  lg.origin = transform.origin
  lg.push = transform.push
  lg.pop = transform.pop
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
  state = {
    filepath = "res/style.png", -- the path to the file that we want to edit
    image = nil, -- the loaded image
    display = {
      zoom = 1, -- additional zoom factor for the displayed image
    },
    scrollpane_state = nil,
    quad_scrollpane_state = nil,
    quads = {},
  }

  love.window.setMode(800, 600, {resizable=true, minwidth=400, minheight=300})

  love.graphics.setDefaultFilter("nearest", "nearest")

  font = love.graphics.newFont("res/m5x7.ttf", 16)
  love.graphics.setFont(font)

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
  gui_state.style.font = font
  gui_state.style.stylesheet = stylesheet
  gui_state.style.rowbackground = {
    top    = love.graphics.newQuad(0, 32, 1, 2, 128, 128),
    center = love.graphics.newQuad(0, 34, 1, 1, 128, 128),
    bottom = love.graphics.newQuad(0, 46, 1, 2, 128, 128),
  }
  gui_state.style.buttonicons = {
    plus  = love.graphics.newQuad(64, 0, 5, 5, 128, 128),
    minus = love.graphics.newQuad(69, 0, 5, 5, 128, 128),
  }
end

local count = 0
function love.draw()
  imgui.begin_frame(gui_state)
  love.graphics.scale(scale, scale)

  love.graphics.clear(203, 222, 227)
  local w, h = gui_state.transform.unproject_dimensions(
    love.graphics.getWidth(), love.graphics.getHeight()
  )
  do Layout.start(gui_state, 2, 2, w - 4, h - 4)

    do Layout.start(gui_state)
      Label.draw(gui_state, nil, nil, nil, nil, "File:")
      Layout.next(gui_state, "-", 2)

      state.filepath = Inputfield.draw(gui_state, nil, nil, 160, nil, state.filepath)
      Layout.next(gui_state, "-", 2)

      local pressed, active = Button.draw(gui_state, nil, nil, nil, nil, "Doggo!!")
      if pressed and load_image_from_path(state.filepath) then 
        reset_view(state)
      end
    end Layout.finish(gui_state, "-")

    Layout.next(gui_state, "|", 2)

    do Layout.start(gui_state, nil, nil, nil, gui_state.layout.max_h - 30)
      do Frame.start(gui_state, nil, nil, gui_state.layout.max_w - 100, nil)
        if state.image then
          do state.scrollpane_state = Scrollpane.start(gui_state, nil, nil, nil, 
            nil, state.scrollpane_state
          )
            love.graphics.setColor(255, 255, 255, 255)
            love.graphics.scale(state.display.zoom, state.display.zoom)

            -- Draw background pattern
            local img_w, img_h = state.image:getDimensions()
            backgroundquad = love.graphics.newQuad(0, 0, img_w, img_h, 8, 8)
            love.graphics.draw(backgroundcanvas, backgroundquad)

            love.graphics.draw(state.image)
            -- Draw a bright pixel where the mouse is
            love.graphics.setColor(255, 255, 255, 255)
            do
              local mx, my = gui_state.transform.unproject(gui_state.mouse.x, gui_state.mouse.y)
              mx, my = math.floor(mx), math.floor(my)
              love.graphics.rectangle("fill", mx, my, 1, 1)
            end

            local get_dragged_rect = function(gui_state, sp_state)
              -- Absolute mouse coordinates
              local mx, my = gui_state.mouse.x, gui_state.mouse.y
              local from_x = gui_state.mouse.buttons[1].at_x
              local from_y = gui_state.mouse.buttons[1].at_y
              -- Now check if the mouse coordinates were inside the scrollpane
              if Scrollpane.is_mouse_inside_widget(
                  gui_state, state.scrollpane_state, mx, my)
                and Scrollpane.is_mouse_inside_widget(
                  gui_state, state.scrollpane_state, from_x, from_y) then
                mx, my = gui_state.transform.unproject(mx, my)
                from_x, from_y = gui_state.transform.unproject(from_x, from_y)

                -- Restrict coordinates
                mx = math.max(0, math.min(img_w - 1, mx))
                my = math.max(0, math.min(img_h - 1, my))
                from_x = math.max(0, math.min(img_w - 1, from_x))
                from_y = math.max(0, math.min(img_h - 1, from_y))

                -- Round coordinates
                local rmx, rmy = math.floor(mx), math.floor(my)            
                local rfx, rfy = math.floor(from_x), math.floor(from_y)

                local x = math.min(rmx, rfx)
                local y = math.min(rmy, rfy)
                local w = math.abs(rmx - rfx) + 1
                local h = math.abs(rmy - rfy) + 1

                return {x = x, y = y, w = w, h = h}
              else
                return nil
              end
            end

            local show_quad = function(quad)
              if type(quad) == "table" and
                quad.x and quad.y and quad.w and quad.h
              then
                love.graphics.setColor(255, 255, 255, 255)
                -- We'll draw the quads differently if the viewport is zoomed out
                -- all the way
                if state.display.zoom == 1 then
                  if quad.w > 1 and quad.h > 1 then
                    love.graphics.rectangle("line", quad.x + .5, quad.y + .5, quad.w - 1, quad.h - 1)
                  elseif quad.w > 1 or quad.h > 1 then
                    love.graphics.rectangle("fill", quad.x, quad.y, quad.w, quad.h)
                  else
                    love.graphics.rectangle("fill", quad.x, quad.y, 1, 1)
                  end
                else
                  love.graphics.push("all")
                  love.graphics.setLineWidth(1/state.display.zoom)
                  love.graphics.rectangle("line", quad.x, quad.y, quad.w, quad.h)
                  love.graphics.pop()
                end
              end
            end

            -- Draw a rectangle at the mouse's dragged area
            do
              if gui_state.mouse.buttons[1] and gui_state.mouse.buttons[1].pressed then
                local rect =get_dragged_rect(gui_state, scrollpane_state)
                if rect then
                  show_quad(rect)
                end
              end
            end

            -- If the mouse was dragged and released in this scrollpane then add a
            -- new quad
            do
              -- Check if the lmb was released
              if gui_state.mouse.buttons[1] and gui_state.mouse.buttons[1].releases > 0 then
                local rect =get_dragged_rect(gui_state, scrollpane_state)
                if rect and rect.w > 0 and rect.h > 0 then
                  table.insert(state.quads, rect)
                end
              end
            end

            -- Draw the outlines of all quads
            for _, quad in pairs(state.quads) do
              show_quad(quad)
            end

            local content_w = img_w * state.display.zoom
            local content_h = img_h * state.display.zoom
          end Scrollpane.finish(gui_state, state.scrollpane_state, content_w, content_h)
        else
          -- Put a label in the center of the frame
          local y = gui_state.layout.max_h / 2 - gui_state.style.font:getHeight()
          Label.draw(gui_state, nil, y, gui_state.layout.max_w, nil,
                     "no image :(", {alignment = ":"})
        end
      end Frame.finish(gui_state)

      Layout.next(gui_state, "-", 2)

      do Layout.start(gui_state)
        -- Draw the list of quads
        do Frame.start(gui_state, nil, nil, nil, gui_state.layout.max_h - 19)
          do state.quad_scrollpane_state = Scrollpane.start(gui_state, nil, nil, nil, nil, state.quad_scrollpane_state)
            do Layout.start(gui_state, nil, nil, nil, nil, {noscissor = true})
              local i = 1
              for name,quad in pairs(state.quads) do
                love.graphics.setColor(255, 255, 255)
                -- Draw row background
                love.graphics.draw( -- top
                  gui_state.style.stylesheet, gui_state.style.rowbackground.top,
                  gui_state.layout.next_x, gui_state.layout.next_y, 
                  0, gui_state.layout.max_w, 1)
                love.graphics.draw( -- center
                  gui_state.style.stylesheet, gui_state.style.rowbackground.center,
                  gui_state.layout.next_x, gui_state.layout.next_y + 2, 
                  0, gui_state.layout.max_w, 18)
                love.graphics.draw( -- bottom
                  gui_state.style.stylesheet, gui_state.style.rowbackground.bottom,
                  gui_state.layout.next_x, gui_state.layout.next_y + 18, 
                  0, gui_state.layout.max_w, 1)
  
                Label.draw(gui_state, nil, nil, gui_state.layout.max_w, nil,
                  string.format("%d: x%d y%d  %dx%d", i, quad.x, quad.y, quad.w, quad.h))
                gui_state.layout.adv_x = gui_state.layout.max_w
                gui_state.layout.adv_y = 20
                Layout.next(gui_state, "|")
                i = i + 1
              end
            end Layout.finish(gui_state, "|")
            -- Restrict the viewport's position to the visible content as good as
            -- possible
            state.quad_scrollpane_state.min_x = 0
            state.quad_scrollpane_state.min_y = 0
            state.quad_scrollpane_state.max_x = gui_state.layout.adv_x
            state.quad_scrollpane_state.max_y = math.max(gui_state.layout.adv_y, gui_state.layout.max_h)
          end Scrollpane.finish(gui_state, state.quad_scrollpane_state)
        end Frame.finish(gui_state)

        Layout.next(gui_state, "|")

        Button.draw(gui_state, nil, nil, gui_state.layout.max_w, nil, "EXPORT", nil, {alignment = ":"})
      end Layout.finish(gui_state, "|")
    end Layout.finish(gui_state, "-")

    Layout.next(gui_state, "|", 2)

    do Layout.start(gui_state)
      do
        local pressed = Button.draw(gui_state, nil, nil, nil, nil, nil, 
          gui_state.style.buttonicons.plus)
        if pressed then
          state.display.zoom = math.min(12, state.display.zoom + 1)
        end
      end
      Layout.next(gui_state, "-")
      do
        local pressed = Button.draw(gui_state, nil, nil, nil, nil, nil, 
          gui_state.style.buttonicons.minus)
        if pressed then
          state.display.zoom = math.max(1, state.display.zoom - 1)
        end
      end

    end Layout.finish(gui_state, "-")

  end Layout.finish(gui_state, "|")

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
  imgui.update(state, dt)
end
