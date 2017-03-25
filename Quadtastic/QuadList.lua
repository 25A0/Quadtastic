local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local Frame = require(current_folder .. ".Frame")
local Layout = require(current_folder .. ".Layout")
local Text = require(current_folder .. ".Text")
local Scrollpane = require(current_folder .. ".Scrollpane")
local imgui = require(current_folder .. ".imgui")
local libquadtastic = require(current_folder .. ".libquadtastic")
local Button = require(current_folder .. ".Button")

local QuadList = {}

local function draw_elements(gui_state, state, elements, last_hovered, quad_bounds)
  local clicked_element, hovered_element
  for name,element in pairs(elements) do
    if name ~= "_META" then
      local background_quads
      if state.selection:is_selected(element) then
        background_quads = gui_state.style.quads.rowbackground.selected
      elseif last_hovered == element then
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

      local input_consumed
      if libquadtastic.is_quad(element) then
        Text.draw(gui_state, 2, nil, gui_state.layout.max_w, nil,
          string.format("%s: x%d y%d  %dx%d", tostring(name), element.x, element.y, element.w, element.h))
      else
        local raw_quads, quads
        if state.collapsed_groups[element] then
          raw_quads = gui_state.style.raw_quads.rowbackground.collapsed
          quads = gui_state.style.quads.rowbackground.collapsed
        else
          raw_quads = gui_state.style.raw_quads.rowbackground.expanded
          quads = gui_state.style.quads.rowbackground.expanded
        end

        assert(raw_quads.default.w == raw_quads.default.h)
        local quad_size = raw_quads.default.w

        local x, y = gui_state.layout.next_x + 1, gui_state.layout.next_y + 5
        local w, h = quad_size, quad_size

        local clicked, pressed, hovered = Button.draw_flat(gui_state, x, y, w, h, nil, quads)
        if clicked then
          if state.collapsed_groups[element] then
            state.collapsed_groups[element] = false
          else
            state.collapsed_groups[element] = true
          end
        end
        input_consumed = clicked or pressed or hovered

        Text.draw(gui_state, quad_size + 3, nil, gui_state.layout.max_w, nil,
          string.format("%s", tostring(name)))
      end
      gui_state.layout.adv_x = gui_state.layout.max_w
      gui_state.layout.adv_y = 16

      quad_bounds[element] = {x = gui_state.layout.next_x, y = gui_state.layout.next_y,
                           w = gui_state.layout.adv_x, h = gui_state.layout.adv_y}

      -- Check if the mouse was clicked on this list entry
      local x, y = gui_state.layout.next_x, gui_state.layout.next_y
      local w, h = gui_state.layout.adv_x, gui_state.layout.adv_y
      if not input_consumed and imgui.was_mouse_pressed(gui_state, x, y, w, h) then
        clicked_element = element
      end
      hovered_element = not input_consumed and
                        imgui.is_mouse_in_rect(gui_state, x, y, w, h) and
                        element or hovered_element

      Layout.next(gui_state, "|")
      -- If we are drawing a group, we now need to recursively draw its
      -- children
      if not libquadtastic.is_quad(element) and not state.collapsed_groups[element] then
        -- Use translate to add some indentation
        love.graphics.translate(9, 0)
        local rec_clicked, rec_hovered = draw_elements(gui_state, state, element, last_hovered, quad_bounds)
        clicked_element = clicked_element or rec_clicked
        hovered_element = hovered_element or rec_hovered
        love.graphics.translate(-9, 0)
      end
    end
  end
  return clicked_element, hovered_element
end

-- Draw the quads in the current state.
-- active is a table that contains for each quad whether it is active.
-- hovered is nil, or a single quad that the mouse hovers over.
QuadList.draw = function(gui_state, state, x, y, w, h, last_hovered)
  -- The quad that the user clicked on
  local clicked
  local hovered
  local quad_bounds = {}
  do Frame.start(gui_state, x, y, w, h)
    imgui.push_style(gui_state, "font", gui_state.style.small_font)
    do state.quad_scrollpane_state = Scrollpane.start(gui_state, nil, nil, nil, nil, state.quad_scrollpane_state)
      do Layout.start(gui_state, nil, nil, nil, nil, {noscissor = true})
        clicked, hovered = draw_elements(gui_state, state, state.quads, last_hovered, quad_bounds)
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

  -- Move viewport to focus quad if necessary
  if state.quad_scrollpane_state.focus_quad then
    Scrollpane.move_into_view(
      state.quad_scrollpane_state,
      quad_bounds[state.quad_scrollpane_state.focus_quad])
    -- Clear focus quad
    state.quad_scrollpane_state.focus_quad = nil
  end

  return clicked, hovered
end

QuadList.move_quad_into_view = function(scrollpane_state, quad)
  scrollpane_state.focus_quad = quad
end

return QuadList