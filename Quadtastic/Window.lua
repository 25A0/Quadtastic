local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local Layout = require(current_folder .. ".Layout")
local imgui = require(current_folder .. ".imgui")
local Frame = require(current_folder .. ".Frame")

local Window = {}

Window.start = function(gui_state, x, y, w, h, options)
  -- Store the window's bounds in the gui state
  gui_state.window_bounds = {x = x, y = y, w = w, h = h}
  gui_state.window_transform = gui_state.transform:clone()

  local active = options and options.active or true
  if not active then
    imgui.cover_input(gui_state)
  end

  local margin = options and options.margin or 4
  local bordersize = 7
  if not (options and options.borderless) then
    Frame.start(gui_state, x, y, w, h,
      {margin = margin, quads = gui_state.style.quads.window_border,
       bordersize = bordersize})
  else
    -- Enclose the window's content in a Layout
    Layout.start(gui_state, x + margin, y + margin, w - 2*margin, h - 2*margin)
  end
end

Window.finish = function(gui_state, options)
  if not (options and options.borderless) then
    Frame.finish(gui_state, nil, nil, {margin = options and options.margin or 2})
  else
    -- Finish the window that encloses the content
    Layout.finish(gui_state)
  end

  local active = options and options.active or true
  if not active then
    imgui.uncover_input(gui_state)
  end

  -- Remove the window bounds
  gui_state.window_bounds = nil
  gui_state.window_transform = nil
end

return Window