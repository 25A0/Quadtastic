local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local Layout = require(current_folder .. ".Layout")
local imgui = require(current_folder .. ".imgui")
local Frame = require(current_folder .. ".Frame")

local Window = {}
local bordersize = 7

Window.start = function(gui_state, x, y, w, h, options)
  -- Store the window's bounds in the gui state
  gui_state.window_bounds = {x = x, y = y, w = w, h = h}
  gui_state.window_transform = gui_state.transform:clone()

  local active = options and options.active or true
  if not active then
    imgui.cover_input(gui_state)
  end

  if not (options and options.borderless) then
    Frame.start(gui_state, x, y, w, h,
      {margin = 0, quads = gui_state.style.quads.window_border,
       bordersize = bordersize})
  end
  local margin = options and options.margin or 4

  -- Enclose the window's content in a Layout
  Layout.start(gui_state, margin, margin, w - 2*margin, h - 2*margin)

  if not (options and options.borderless) then
    -- Shift content past the top border
    gui_state.layout.adv_y = bordersize
    Layout.next(gui_state, "|")
  end

end

Window.finish = function(gui_state, x, y, dragging, options)
  local active = options and options.active or true

  -- Finish the layout that encloses the content
  Layout.finish(gui_state)
  local w = gui_state.layout.adv_x + (options and options.margin or 4) * 2
  local h = gui_state.layout.adv_y + (options and options.margin or 4) * 2
  local dx, dy

  if not (options and options.borderless) then
    Frame.finish(gui_state, nil, nil, {margin = options and options.margin or 4})
    h = h + bordersize
    if active then
      -- Check if the user moved the window
      if imgui.was_mouse_pressed(gui_state, x, y, w, bordersize)
      then
        dragging = true
      elseif dragging and not (gui_state.input and gui_state.input.mouse.buttons and
        gui_state.input.mouse.buttons[1] and gui_state.input.mouse.buttons[1].pressed)
      then
        dragging = false
      end
      if dragging and gui_state.input then
        local mdx, mdy = gui_state.input.mouse.dx, gui_state.input.mouse.dy
        dx, dy = gui_state.transform:unproject_dimensions(mdx, mdy)
      end
    end
  end

  if not active then
    imgui.uncover_input(gui_state)
  end

  -- Remove the window bounds
  gui_state.window_bounds = nil
  gui_state.window_transform = nil

  return w, h, dx, dy, dragging
end

return Window