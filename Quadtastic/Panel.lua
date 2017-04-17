local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local State = require(current_folder .. ".State")
local Frame = require(current_folder .. ".Frame")
local imgui = require(current_folder .. ".imgui")

local unpack = unpack or table.unpack

local Panel = {}

-- x and y is the position that the arrow will point at
-- w and h are the dimensions of the panel's content. The panel itself will
-- be slightly larger because of borders
-- the name is used to check if this panel should be drawn, based on the value
-- of gui_state.current_panel
function Panel.begin(gui_state, x, y, w, h)
  love.graphics.push("all")
  love.graphics.setScissor()
  love.graphics.setCanvas(gui_state.overlay_canvas)

  -- the panel is always to the right of the point
  local pos_x = x + gui_state.style.raw_quads.panel.arrow.w - 1
  local pos_y = y - gui_state.style.raw_quads.panel.arrow.h
  Frame.start(gui_state, pos_x, pos_y, w, h,
              {quads = gui_state.style.quads.panel, bordersize = 3})
end


function Panel.finish(gui_state, x, y, w, h)
  Frame.finish(gui_state, w, h)
  -- draw the little arrow
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.draw(gui_state.style.stylesheet,
                     gui_state.style.quads.panel.arrow,
                     x, y - math.floor(gui_state.style.raw_quads.panel.arrow.h/2))
  love.graphics.setCanvas()
  love.graphics.pop()
  gui_state.layout.adv_x, gui_state.layout.adv_y = 0, 0
end

function Panel.new(name, gui_state, x, y, panel_w, panel_h, draw_function)
  local transitions = {
    close = function(...) return true end
  }
  local panel = State(name, transitions, data)

  local abs_bounds = gui_state.transform:project_bounds({x = x, y = y, w = panel_w, h = panel_h})

  panel.draw = function(app, data, gui_state, w, h)
    local p_bounds = gui_state.transform:unproject_bounds(abs_bounds)
    Panel.begin(gui_state, p_bounds.x, p_bounds.y, p_bounds.w, p_bounds.h)
    draw_function(app, data, gui_state, p_bounds.w, p_bounds.h)
    Panel.finish(gui_state, p_bounds.x, p_bounds.y, p_bounds.w, p_bounds.h)
    -- Close the panel if the mouse was clicked outside its bounds
    if gui_state.input and gui_state.input.mouse.buttons[1] and
       gui_state.input.mouse.buttons[1].presses >= 1 and
       not imgui.was_mouse_pressed(gui_state, p_bounds.x, p_bounds.y, p_bounds.w, p_bounds.h)
    then
      app[name].close()
    end
  end
  return panel
end

return Panel