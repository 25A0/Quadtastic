local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local Scrollpane = require(current_folder .. ".Scrollpane")
local libquadtastic = require(current_folder .. ".libquadtastic")
local imgui = require(current_folder .. ".imgui")
local Text = require(current_folder .. ".Text")
local Rectangle = require(current_folder .. ".Rectangle")

local ImageEditor = {}

function ImageEditor.zoom(state, delta)
  if not state.display.zoom then state.display.zoom = 1 end
  local cx, cy = Rectangle.center(state.scrollpane_state)
  cx, cy = cx / state.display.zoom, cy / state.display.zoom
  state.display.zoom = math.max(1, math.min(12, state.display.zoom + delta))
  cx, cy = cx * state.display.zoom, cy * state.display.zoom
  Scrollpane.set_focus(state.scrollpane_state, {x = cx, y = cy}, "immediate")
end

local function show_quad(gui_state, state, quad, quadname)
  if libquadtastic.is_quad(quad) then
    -- If the mouse is inside that quad, display its name
    if gui_state.input and quadname and not state.hovered then
      if imgui.is_mouse_in_rect(gui_state, quad.x, quad.y, quad.w, quad.h) then
        love.graphics.push("all")
        love.graphics.scale(1/state.display.zoom, 1/state.display.zoom)
        local mx, my = gui_state.input.mouse.x, gui_state.input.mouse.y
        local x, y = gui_state.transform:unproject(mx + 10, my + 10)
        Text.draw(gui_state, x, y, nil, nil, quadname)
        love.graphics.pop()

        -- Set this quad as the hovered quad in the application state
        state.hovered = quad
      end
    end

    love.graphics.setColor(255, 255, 255, 255)
    -- We'll draw the quads differently if the viewport is zoomed out
    -- all the way
    if state.display.zoom == 1 then
      if quad.w > 1 and quad.h > 1 then
        love.graphics.rectangle("line", quad.x + .5, quad.y + .5, quad.w - 1, quad.h - 1)
      else
        love.graphics.rectangle("fill", quad.x, quad.y, quad.w, quad.h)
      end
    else
      love.graphics.push("all")
      love.graphics.setLineStyle("rough")
      love.graphics.setLineWidth(1/state.display.zoom)
      if quad == state.hovered or state.selection:is_selected(quad) then
        -- Use a dashed line to outline the quad
        local segment_length = 1
        local adv = (gui_state.second or 0) * 2 * segment_length
        -- top
        if adv > segment_length then adv = adv - 2*segment_length end
        while adv < quad.w do
          local start = math.max(quad.x, quad.x + adv)
          local max_adv = math.min(quad.w, adv + segment_length)
          love.graphics.line(start           , quad.y,
                             quad.x + max_adv, quad.y)
          adv = adv + 2*segment_length
        end
        adv = adv - quad.w
        -- right
        if adv > segment_length then adv = adv - 2*segment_length end
        while adv < quad.h do
          local start = math.max(quad.y, quad.y + adv)
          local max_adv = math.min(quad.h, adv + segment_length)
          love.graphics.line(quad.x + quad.w, start,
                             quad.x + quad.w, quad.y + max_adv)
          adv = adv + 2*segment_length
        end
        adv = adv - quad.h
        -- bottom
        if adv > segment_length then adv = adv - 2*segment_length end
        while adv < quad.w do
          local start = math.min(quad.x + quad.w, quad.x + quad.w - adv)
          local max_adv = math.min(quad.w, adv + segment_length)
          love.graphics.line(start                    , quad.y + quad.h,
                             quad.x + quad.w - max_adv, quad.y + quad.h)
          adv = adv + 2*segment_length
        end
        adv = adv - quad.w
        -- left
        if adv > segment_length then adv = adv - 2*segment_length end
        while adv < quad.h do
          local start = math.min(quad.y + quad.h, quad.y + quad.h - adv)
          local max_adv = math.min(quad.h, adv + segment_length)
          love.graphics.line(quad.x, start,
                             quad.x, quad.y + quad.h - max_adv)
          adv = adv + 2*segment_length
        end
        -- adv = adv - quad.h
      else
        -- Use a simple line to outline the quad
        love.graphics.rectangle("line", quad.x, quad.y, quad.w, quad.h)
      end
      love.graphics.pop()
    end
  elseif type(quad) == "table" then
    -- If it's not a quad then it's a list of quads
    for k,v in pairs(quad) do
      local name = quadname and quadname .. "." .. tostring(k) or tostring(k)
      show_quad(gui_state, state, v, name)
    end
  end
end

local function get_dragged_rect(state, gui_state, img_w, img_h)
  assert(gui_state.input)
  -- Absolute mouse coordinates
  local mx, my = gui_state.input.mouse.x, gui_state.input.mouse.y
  local from_x = gui_state.input.mouse.buttons[1].at_x
  local from_y = gui_state.input.mouse.buttons[1].at_y
  -- Now check if the mouse coordinates were inside the scrollpane
  if Scrollpane.is_mouse_inside_widget(
      gui_state, state.scrollpane_state, mx, my)
    and Scrollpane.is_mouse_inside_widget(
      gui_state, state.scrollpane_state, from_x, from_y) then
    mx, my = gui_state.transform:unproject(mx, my)
    from_x, from_y = gui_state.transform:unproject(from_x, from_y)

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

local function handle_input(gui_state, state, img_w, img_h)
    -- Draw a bright pixel where the mouse is
    love.graphics.setColor(255, 255, 255, 255)
    if gui_state.input then
      local mx, my = gui_state.transform:unproject(
        gui_state.input.mouse.x, gui_state.input.mouse.y)
      mx, my = math.floor(mx), math.floor(my)
      love.graphics.rectangle("fill", mx, my, 1, 1)
    end

    -- Draw a rectangle at the mouse's dragged area
    do
      if gui_state.input and gui_state.input.mouse.buttons[1] and
        gui_state.input.mouse.buttons[1].pressed
      then
        local rect = get_dragged_rect(state, gui_state, img_w, img_h)
        if rect then
          show_quad(gui_state, state, rect)
        end
      end
    end

    -- If the mouse was dragged and released in this scrollpane then add a
    -- new quad
    local new_quad
    do
      -- Check if the lmb was released
      if gui_state.input and gui_state.input.mouse.buttons[1] and
        gui_state.input.mouse.buttons[1].releases > 0
      then
        local rect = get_dragged_rect(state, gui_state, img_w, img_h)
        if rect and rect.w > 0 and rect.h > 0 then
          new_quad = rect
        end
      end
    end

    -- If the middle mouse button was dragged in this scrollpane, pan the image
    -- by the dragged distance
    if gui_state.input and gui_state.input.mouse.buttons[3] and gui_state.input.mouse.buttons[3].pressed then
      local button_state = gui_state.input.mouse.buttons[3]
      if Scrollpane.is_mouse_inside_widget(gui_state, state.scrollpane_state,
                                           button_state.at_x, button_state.at_y)
      then
        local dx, dy = -gui_state.input.mouse.dx, -gui_state.input.mouse.dy
        dx, dy = gui_state.transform:unproject_dimensions(dx, dy)
        dx, dy = dx * state.display.zoom, dy * state.display.zoom
        Scrollpane.move_viewport(state.scrollpane_state, dx, dy)
      end
    end

    -- if CTRL was pressed and the mousewheel was moved, adjust the zoom level
    -- and consume the mousewheel movement
    if gui_state.input and gui_state.input.mouse.wheel_dy and
      (imgui.is_key_pressed(gui_state, "lctrl") or
       imgui.is_key_pressed(gui_state, "lctrl"))
    then
      local dy = gui_state.input.mouse.wheel_dy
      ImageEditor.zoom(state, dy)
      -- Consume mousewheel movement
      gui_state.input.mouse.wheel_dy = 0
    end
    return new_quad
end

ImageEditor.draw = function(gui_state, state, x, y, w, h)
  local content_w, content_h
  local new_quad
  do state.scrollpane_state = Scrollpane.start(gui_state, x, y, w, h,
    state.scrollpane_state
  )
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.scale(state.display.zoom, state.display.zoom)

    -- Draw background pattern
    local img_w, img_h = state.image:getDimensions()
    local backgroundquad = love.graphics.newQuad(0, 0, img_w, img_h, 8, 8)
    love.graphics.draw(gui_state.style.backgroundcanvas, backgroundquad)

    love.graphics.draw(state.image)

    if gui_state and gui_state.input then
      new_quad = handle_input(gui_state, state, img_w, img_h)
    end

    -- Draw the outlines of all quads
    for name, quad in pairs(state.quads) do
      show_quad(gui_state, state, quad, tostring(name))
    end

    content_w = img_w * state.display.zoom
    content_h = img_h * state.display.zoom
  end Scrollpane.finish(gui_state, state.scrollpane_state, content_w, content_h)
  return new_quad
end

return ImageEditor