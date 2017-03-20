local Text = require("Text")
local imgui = require("imgui")

local Renderutils = require("Renderutils")

local Tooltip = {}

unpack = unpack or table.unpack

local find_tooltip_position = function(gui_state, x, y, w, h, label, options)
  local textlength = Text.min_width(gui_state, label or "Someone forgot to set the tooltip text...")

  -- Determine where the most room is to show the tooltip
  local above = y - gui_state.window_bounds.y
  local below = gui_state.window_bounds.h - (h + y)

  local tty, tip_y, orientation
  local tooltip_height = 12
  if above > below then
    tty = y - (3 + tooltip_height) -- move tooltip above the frame
    tip_y = y - 3
    orientation = "downwards"
  else
    tty = y + h + 3 -- move tooltip below the frame
    tip_y = y + h
    orientation = "upwards"
  end

  -- Change the x position depending on how close we are to the window's border
  if textlength > gui_state.window_bounds.w and _DEBUG then
    print("Warning: tooltip label "..label.." exceeds window bounds")
  end
  local tooltip_width = textlength + 2*2
  local ttx = x + w / 2 - tooltip_width/2
  ttx = math.max(gui_state.window_bounds.x + 2, ttx)
  ttx = math.min(gui_state.window_bounds.w - gui_state.window_bounds.x - tooltip_width - 2, ttx)
  local tip_x = x + w/2 - 5/2

  return ttx, tty,
         tooltip_width,
         tooltip_height,
         tip_x, tip_y,
         orientation
end

local show_tooltip = function(gui_state, x, y, w, h, label, options)
  gui_state.overlay_canvas:renderTo(function()
    -- Remember and remove the current scissor
    local old_scissor = {love.graphics.getScissor()}
    love.graphics.setScissor()

    -- Use the small font for the tooltip label
    imgui.push_style(gui_state, "font", gui_state.style.small_font)

    -- Calculate position and dimensions within the window
    local window_x, window_y = gui_state.window_transform:unproject(
      gui_state.transform:project(x, y))
    local window_w, window_h = gui_state.window_transform:unproject_dimensions(
      gui_state.transform:project_dimensions(w, h))
  
    local ttx, tty, ttw, tth, tipx, tipy, orientation = find_tooltip_position(
      gui_state, window_x, window_y, window_w, window_h, label, options)

    -- Replace current transform by window transform.
    -- Only works for translate and scale; sheared or rotated windows will have
    -- incorrect tooltips
    love.graphics.push("all")
    love.graphics.origin()
    love.graphics.translate(gui_state.window_transform:getTranslate())
    love.graphics.scale(gui_state.window_transform:getScale())

    love.graphics.setColor(255, 255, 255, 255)
    -- Draw tooltip border
    Renderutils.draw_border(gui_state.style.stylesheet, 
                            gui_state.style.quads.tooltip.border, 
                            ttx, tty, ttw, tth, 2)
    -- Draw tooltip tip
    love.graphics.draw(gui_state.style.stylesheet, gui_state.style.quads.tooltip.tip[orientation], tipx, tipy)
    if not options then options = {} end
    if not options.font_color then
      options.font_color = {202, 222, 227}
    end
    Text.draw(gui_state, ttx + 2, tty - 2, ttw, tth, label, options)

    imgui.pop_style(gui_state, "font")

    love.graphics.pop()

    -- Restore the old scissor
    love.graphics.setScissor(unpack(old_scissor))

  end)
end

local function handle_input(gui_state, label, x, y, w, h, options)
  local old_mouse_x = gui_state.input.mouse.old_x
  local old_mouse_y = gui_state.input.mouse.old_y
  if not old_mouse_x or not old_mouse_y then return end

  -- Check if the mouse was in that area in the previous frame
  local was_in_frame = imgui.is_mouse_in_rect(gui_state, x, y, w, h,
    old_mouse_x, old_mouse_y)
  -- Now check the current mouse position
  local is_in_frame = imgui.is_mouse_in_rect(gui_state, x, y, w, h)

  if was_in_frame and is_in_frame then
    gui_state.tooltip_time = gui_state.tooltip_time + gui_state.dt
  elseif is_in_frame then -- the mouse has just been moved into the frame
    -- This is not super-accurate but will probably suffice
    gui_state.tooltip_time = gui_state.dt
  else -- the mouse is not in the frame.
    return
  end

  -- The threshold after which the tooltip should be displayed. Default is 1s
  local threshold = options and options.tooltip_threshold or 1

  -- Returns true if the tooltip should be displayed
  return gui_state.tooltip_time > threshold
end

-- A tooltip ignores the current layout's bounds but uses the current layout
-- hints to determine where it should be drawn. It will be drawn at the bottom
-- or the top of the previously drawn component
Tooltip.draw = function(gui_state, label, x, y, w, h, options)
  -- The dimensions of the item next to which the tooltip will be displayed
  x = x or gui_state.layout.next_x
  y = y or gui_state.layout.next_y
  w = w or gui_state.layout.adv_x
  h = h or gui_state.layout.adv_y

  if gui_state and gui_state.input then
    if handle_input(gui_state, label, x, y, w, h, options) then -- display the tooltip
      show_tooltip(gui_state, x, y, w, h, label, options)
    end
  end
end

return Tooltip
