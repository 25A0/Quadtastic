local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local os_name = love.system.getOS()
package.cpath = package.cpath ..
                string.format(";%s/shared/%s/?.%s",
                              love.filesystem.getSourceBaseDirectory(),
                              os_name, os_name == "Windows" and "dll" or "so")

local imgui = require(current_folder .. ".imgui")

local AppLogic = require(current_folder .. ".AppLogic")
local Quadtastic = require(current_folder .. ".Quadtastic")
local libquadtastic = require(current_folder .. ".libquadtastic")
local exporters = require(current_folder .. ".Exporters")

local Transform = require(current_folder .. '.transform')
local Toast = require(current_folder .. '.Toast')
local Text = require(current_folder .. '.Text')
local S = require(current_folder .. '.strings')
local Version = require(current_folder .. '.Version')
local common = require(current_folder .. '.common')
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

local version_url
local checked_version = false

function love.load()
  local version_info = common.get_version()
  love.window.setTitle(love.window.getTitle() .. " " .. version_info)
  -- Disable buffering of stdout
  io.stdout:setvbuf("no")

  -- Direct output to both stdout and a log file
  do
    -- Make sure that the save directory exists
    if not love.filesystem.exists("log.txt") then
      local file = love.filesystem.newFile("log.txt")
      file:open("w")
      file:close()
    end
    local logfile = love.filesystem.getSaveDirectory() .. "/" .. "log.txt"
    io.output(logfile)
    io.output():setvbuf("no")
    local lua_print = print
    print = function(...)
      -- Print to stdout but also to the log file
      lua_print(...)
      io.write(...)
      io.write('\n')
    end
  end

  -- Initialize the exporters directory structure
  do
    local success, err = pcall(exporters.init, S.exporters_dirname)
    if not success then
      print("Could not initialize exporters: " .. err)
    else
      -- Fetch exporters
      local list_success, more = pcall(exporters.list, S.exporters_dirname)
      if not list_success then
        print("Could not fetch list of exporters: " .. more)
      else
        Quadtastic.data.exporters = more
      end
    end
  end

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
  local turboworkflow_deactivated = love.graphics.newImage("res/turboworkflow-deactivated.png")
  local turboworkflow_activated = love.graphics.newImage("res/turboworkflow-activated.png")
  local loading = love.graphics.newImage("res/loading.png")

  love.keyboard.setKeyRepeat(true)
  gui_state = imgui.init_state(transform)
  gui_state.style.small_font = smol_font
  gui_state.style.med_font = med_font
  gui_state.style.font = med_font
  gui_state.style.stylesheet = stylesheet

  gui_state.style.turboworkflow_deactivated = turboworkflow_deactivated

  do
    local frames = {}
    for i=0,3 do
      frames[i + 1] = love.graphics.newQuad(i*128, 0, 128, 16, 512, 16)
    end
    gui_state.style.turboworkflow_activated = {
      sheet = turboworkflow_activated,
      frames = frames,
      duration = .1,
      w = 128,
      h = 16
    }
  end

  do
    local frames = {}
    for i=0,41 do
      frames[i + 1] = love.graphics.newQuad(i*16, 0, 16, 16, 42 * 16, 16)
    end
    gui_state.style.loading = {
      sheet = loading,
      frames = frames,
      duration = .1,
      w = 16,
      h = 16
    }
  end

  gui_state.style.icon = icon
  gui_state.style.raw_quads = require("res/style")
  gui_state.style.quads = libquadtastic.create_quads(gui_state.style.raw_quads,
    stylesheet:getWidth(), stylesheet:getHeight())

  gui_state.style.palette = libquadtastic.create_palette(gui_state.style.raw_quads.palette,
    stylesheet)

  gui_state.style.font_color = gui_state.style.palette.shades.darkest

  gui_state.style.backgroundcanvas = love.graphics.newCanvas(8, 8)
  do
    -- Create a canvas with the background texture on it
    gui_state.style.backgroundcanvas:setWrap("repeat", "repeat")
    gui_state.style.backgroundcanvas:renderTo(function()
      love.graphics.draw(stylesheet, gui_state.style.quads.background)
    end)
  end

  gui_state.style.dashed_line = { horizontal = {}, vertical = {}, size = 8}
  do
    local line = gui_state.style.dashed_line.horizontal
    local size = gui_state.style.dashed_line.size
    line.canvas = love.graphics.newCanvas(size, 1)
    line.spritebatch = love.graphics.newSpriteBatch(line.canvas, 4096, "stream")
    line.canvas:setWrap("repeat", "repeat")
    line.canvas:renderTo(function()
      love.graphics.clear(0, 0, 0)
      love.graphics.rectangle("fill", 0, 0, size/2, 1)
    end)
  end

  do
    local line = gui_state.style.dashed_line.vertical
    local size = gui_state.style.dashed_line.size
    line.canvas = love.graphics.newCanvas(1, size)
    line.spritebatch = love.graphics.newSpriteBatch(line.canvas, 4096, "stream")
    line.canvas:setWrap("repeat", "repeat")
    line.canvas:renderTo(function()
      love.graphics.clear(0, 0, 0)
      love.graphics.rectangle("fill", 0, 0, 1, size/2)
    end)
  end

  gui_state.overlay_canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())

  -- Set up second thread for http requests
  local http_thread = love.thread.newThread("http_thread.lua")
  http_thread:start()

  -- Check for an update
  local channel_name = common.get_edition()
  if channel_name then
    channel_name = common.trim_whitespace(channel_name)
    version_url = string.format("%s/%s", S.update_base_url, channel_name)
    print(string.format("Querying %s", version_url))
    love.thread.getChannel("http_requests"):push(version_url)
  end
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
      f(app, state.data, gui_state, w, h)
      if not is_active then imgui.uncover_input(gui_state) end
    end
  end

  -- Check for result of version query
  if not checked_version then
    local channel = love.thread.getChannel("http_responses")
    local value = channel:peek()
    if value and value.url == version_url then
      channel:pop() -- remove the response from the channel
      if value.success then
        local current_version, latest_version
        do
          local version_info = common.get_version()
          local success, version = pcall(Version, version_info)
          if success then current_version = version end
        end

        local match = string.gmatch(value.response, '{"latest": "(.*)"}')()
        if match then
          local success, version = pcall(Version, match)
          if success then latest_version = version end
        end

        if latest_version and current_version then
          if current_version < latest_version then
            app.quadtastic.offer_update(current_version, latest_version)
          end
        else
          local toast_text = S.toast.err_cannot_fetch_version
          imgui.show_toast(gui_state, toast_text, nil, 4)
        end
      else
        local toast_text = S.toast.err_cannot_fetch_version
        imgui.show_toast(gui_state, toast_text, nil, 4)
      end
      checked_version = true
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
    x, y = math.floor(x), math.floor(y)
    -- Draw dark background for better readability
    love.graphics.setColor(gui_state.style.palette.shades.darkest(192))
    love.graphics.rectangle("fill", x-2, y + 2,
                            Text.min_width(gui_state, gui_state.mousestring) + 4, 12)
    imgui.push_style(gui_state, "font_color", gui_state.style.palette.shades.brightest)
    Text.draw(gui_state, x, y, nil, nil, gui_state.mousestring)
    imgui.pop_style(gui_state, "font_color")
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

function love.errhand(error_message)
  local dialog_message = [[
Quadtastic crashed with the following error message:

%s

Would you like to report this crash so that it can be fixed?]]
  local titles = {"Oh no", "Oh boy", "Bad news"}
  local title = titles[love.math.random(#titles)]
  local full_error = debug.traceback(error_message or "")
  local message = string.format(dialog_message, full_error)
  local buttons = {"Yes, on GitHub", "Yes, by email", "No"}

  local pressedbutton = love.window.showMessageBox(title, message, buttons)
  local version
  do
    local success, more = pcall(common.get_version)
    if success then version = more
    else version = "Unknown version" end
  end
  local edition
  do
    local success, more = pcall(common.get_edition)
    if success and more then edition = more
    else edition = "Unknown edition" end
  end

  local function url_encode(text)
    -- This is not complete. Depending on your issue text, you might need to
    -- expand it!
    text = string.gsub(text, "\n", "%%0A")
    text = string.gsub(text, " ", "%%20")
    text = string.gsub(text, "#", "%%23")
    return text
  end

  local issuebody = [[
Quadtastic crashed with the following error message:

%s

[If you can, describe what you've been doing when the error occurred]

---
Affects: %s
Edition: %s]]
  if pressedbutton == 1 then
    -- Surround traceback in ``` to get a Markdown code block
    full_error = table.concat({"```",full_error,"```"}, "\n")
    issuebody = string.format(issuebody, full_error, version, edition)
    issuebody = url_encode(issuebody)
    local subject = string.format("Crash in Quadtastic %s", version)
    local url = string.format("https://www.github.com/25A0/Quadtastic/issues/new?title=%s&body=%s",
                              subject, issuebody)
    love.system.openURL(url)
  elseif pressedbutton == 2 then
    issuebody = string.format(issuebody, full_error, version, edition)
    issuebody = url_encode(issuebody)
    local subject = string.format("Crash in Quadtastic %s", version)
    local url = string.format("mailto:moritz@25a0.com?subject=%s&body=%s",
                              subject, issuebody)
    love.system.openURL(url)
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

function love.threaderror(_, errorstr)
  error("Thread error\n"..errorstr)
end
