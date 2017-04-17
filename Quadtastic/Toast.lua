local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local Text = require(current_folder .. ".Text")
local imgui = require(current_folder .. ".imgui")

local Renderutils = require(current_folder .. ".Renderutils")

local Toast = {}

local function find_toast_position(bounds, textwidth, textheight, border_width, border_height
)
  -- The toast should be centered in the bounds, and 4px away from the bottom
  local x = bounds.x + math.floor((bounds.w - (textwidth + border_width)) / 2)
  local margin = 4
  local y = bounds.y + bounds.h - margin - border_height - textheight
  return x, y
end

-- Renders a toast with the given label inside the given bounds.
-- Start is the time at which this toast was first drawn, duration is the
-- total time for which the toast should be visible.
-- THE BOUNDS ARE EXPECTED TO BE IN ABSOLUTE COORDINATES.
function Toast.draw(gui_state, label, bounds, start, duration, options)
  love.graphics.push("all")
  love.graphics.setCanvas(gui_state.overlay_canvas)

  if not bounds then
    -- Use current window's bounds instead
    assert(gui_state.window_bounds, "Toast drawn without explicit bounds and surrounding window")
    bounds = gui_state.window_transform:project_bounds(gui_state.window_bounds)
  end

  -- Set scissor to bounds so that fading in looks right regardless of where
  -- the bounds are in the window
  love.graphics.setScissor(bounds.x, bounds.y, bounds.w, bounds.h)
  imgui.push_style(gui_state, "font", gui_state.style.small_font)
  bounds = gui_state.transform:unproject_bounds(bounds)
  local textwidth = Text.min_width(gui_state, label)
  local textheight = 10
  local raw_quads = gui_state.style.raw_quads.toast
  local border_width = raw_quads.l.w + raw_quads.r.w
  local border_height = raw_quads.t.h + raw_quads.b.h
  local border_size = raw_quads.tl.w
  local x, y = find_toast_position(bounds, textwidth, textheight, border_width, border_height)

  if start and duration and duration >= 1 then --consider animating
    local elapsed = gui_state.t - start
    local anim_time = .25
    if elapsed < anim_time then
      local d = bounds.y + bounds.h - y
      local r = elapsed / anim_time
      y = math.floor(y + (1 - r) * d)
    end
  end

  Renderutils.draw_border(gui_state.style.stylesheet, gui_state.style.quads.toast,
    x, y, textwidth + border_width, textheight + border_height, border_size)

  if not options then options = {} end
  options.alignment_v = "-"
  if not options.font_color then
    options.font_color = gui_state.style.palette.shades.brightest
  end
  Text.draw(gui_state, x + border_size, y + border_size,
    textwidth, textheight, label, options)

  imgui.pop_style(gui_state, "font")

  love.graphics.setCanvas()
  love.graphics.pop()
end

return Toast