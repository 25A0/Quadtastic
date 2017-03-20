local Frame = require("Quadtastic/Frame")
local Layout = require("Quadtastic/Layout")
local Text = require("Quadtastic/Text")
local Scrollpane = require("Quadtastic/Scrollpane")
local imgui = require("Quadtastic/imgui")
local libquadtastic = require("Quadtastic/libquadtastic")

local QuadList = {}

local function draw_quads(gui_state, state, quads, last_hovered)
  local clicked, hovered
  for name,quad in pairs(quads) do
    local background_quads
    if state.selection:is_selected(quad) then
      background_quads = gui_state.style.quads.rowbackground.selected
    elseif last_hovered == quad then
      background_quads = gui_state.style.quads.rowbackground.hovered
    else
      background_quads = gui_state.style.quads.rowbackground.default
    end

    love.graphics.setColor(255, 255, 255)
    -- Draw row background
    love.graphics.draw( -- top
      gui_state.style.stylesheet, background_quads.top,
      gui_state.layout.next_x, gui_state.layout.next_y, 
      0, gui_state.layout.max_w, 1)
    love.graphics.draw( -- center
      gui_state.style.stylesheet, background_quads.center,
      gui_state.layout.next_x, gui_state.layout.next_y + 2, 
      0, gui_state.layout.max_w, 12)
    love.graphics.draw( -- bottom
      gui_state.style.stylesheet, background_quads.bottom,
      gui_state.layout.next_x, gui_state.layout.next_y + 14, 
      0, gui_state.layout.max_w, 1)

    if libquadtastic.is_quad(quad) then
      Text.draw(gui_state, 2, nil, gui_state.layout.max_w, nil,
        string.format("%s: x%d y%d  %dx%d", tostring(name), quad.x, quad.y, quad.w, quad.h))
    else
      Text.draw(gui_state, 2, nil, gui_state.layout.max_w, nil,
        string.format("%s: quad group", tostring(name)))
    end
    gui_state.layout.adv_x = gui_state.layout.max_w
    gui_state.layout.adv_y = 16

    -- Check if the mouse was clicked on this list entry
    local x, y = gui_state.layout.next_x, gui_state.layout.next_y
    local w, h = gui_state.layout.adv_x, gui_state.layout.adv_y
    if imgui.was_mouse_pressed(gui_state, x, y, w, h) then
      clicked = quad
    end
    hovered = imgui.is_mouse_in_rect(gui_state, x, y, w, h) and quad or hovered

    Layout.next(gui_state, "|")
    -- If we are drawing a quad list, we now need to recursively draw its
    -- children
    if not libquadtastic.is_quad(quad) then
      -- Use translate to add some indentation
      love.graphics.translate(10, 0)
      local rec_clicked, rec_hovered = draw_quads(gui_state, state, quad, last_hovered)
      clicked = clicked or rec_clicked
      hovered = hovered or rec_hovered
      love.graphics.translate(-10, 0)
    end
  end
  return clicked, hovered
end

-- Draw the quads in the current state.
-- active is a table that contains for each quad whether it is active.
-- hovered is nil, or a single quad that the mouse hovers over.
QuadList.draw = function(gui_state, state, x, y, w, h, last_hovered)
  -- The quad that the user clicked on
  local clicked = nil
  local hovered = nil
  do Frame.start(gui_state, x, y, w, h)
    imgui.push_style(gui_state, "font", gui_state.style.small_font)
    do state.quad_scrollpane_state = Scrollpane.start(gui_state, nil, nil, nil, nil, state.quad_scrollpane_state)
      do Layout.start(gui_state, nil, nil, nil, nil, {noscissor = true})
        clicked, hovered = draw_quads(gui_state, state, state.quads, last_hovered)
      end Layout.finish(gui_state, "|")
      -- Restrict the viewport's position to the visible content as good as
      -- possible
      state.quad_scrollpane_state.min_x = 0
      state.quad_scrollpane_state.min_y = 0
      state.quad_scrollpane_state.max_x = gui_state.layout.adv_x
      state.quad_scrollpane_state.max_y = math.max(gui_state.layout.adv_y, gui_state.layout.max_h)
    end Scrollpane.finish(gui_state, state.quad_scrollpane_state)
    imgui.pop_style(gui_state, "font")
  end Frame.finish(gui_state)
  return clicked, hovered
end

return QuadList