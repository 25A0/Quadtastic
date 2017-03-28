local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local Scrollpane = require(current_folder .. ".Scrollpane")
local libquadtastic = require(current_folder .. ".libquadtastic")
local imgui = require(current_folder .. ".imgui")
local Text = require(current_folder .. ".Text")
local Rectangle = require(current_folder .. ".Rectangle")
local QuadList = require(current_folder .. ".QuadList")
local fun = require(current_folder .. ".fun")

local ImageEditor = {}

function ImageEditor.zoom(state, delta)
  if not state.display.zoom then state.display.zoom = 1 end
  local cx, cy = Rectangle.center(state.scrollpane_state)
  cx, cy = cx / state.display.zoom, cy / state.display.zoom
  state.display.zoom = math.max(1, math.min(12, state.display.zoom + delta))
  cx, cy = cx * state.display.zoom, cy * state.display.zoom
  Scrollpane.set_focus(state.scrollpane_state, {x = cx, y = cy}, "immediate")
end

local function iter_quads(tab, index, depth)
  if not depth then depth = 1 end
  if not index then index = {} end
  if #index > depth then -- continue traversing nested element
    local keys, v = iter_quads(tab[index[depth]], index, depth + 1)
    if not keys then -- we have finished traversing that nested element
      -- Remove any deeper keys
      for i=depth + 1,#index do index[i] = nil end
      return iter_quads(tab, index, depth)
    else
      return keys, v
    end
  else -- Pick the next element on this level
    local next_key, next_value = next(tab, index[depth])
    if not next_key then return nil end -- we hit the end of this table
    index[depth] = next_key
    if libquadtastic.is_quad(next_value) then
      return index, next_value
    elseif type(next_value) == "table" then
      local nested_keys, nested_value = iter_quads(tab[next_key], index, depth + 1)
      if not nested_keys then -- we have finished traversing that nested element
        -- Remove any deeper keys
        for i=depth + 1,#index do index[i] = nil end
        return iter_quads(tab, index, depth)
      else
        return nested_keys, nested_value
      end
    else -- we hit something that is neither a table nor a quad. Skip that
      return iter_quads(tab, index, depth)
    end
  end
end

local function draw_dashed_line(quad, gui_state)
  local segment_length = 1
  local adv = (gui_state and gui_state.second or 0) * 2 * segment_length
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
end

local function show_quad(gui_state, state, quad, quadname)
  if libquadtastic.is_quad(quad) then
    -- If the mouse is inside that quad, display its name
    if gui_state.input and quadname and not state.hovered and
       not state.toolstate.selecting
    then
      if imgui.is_mouse_in_rect(gui_state, quad.x, quad.y, quad.w, quad.h) then
        gui_state.mousestring = quadname
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
        draw_dashed_line(quad, gui_state)
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
    if img_w then
      mx = math.max(0, math.min(img_w - 1, mx))
      from_x = math.max(0, math.min(img_w - 1, from_x))
    end
    if img_h then
      my = math.max(0, math.min(img_h - 1, my))
      from_y = math.max(0, math.min(img_h - 1, from_y))
    end

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

local function create_tool(app, gui_state, state, img_w, img_h)
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
    do
      -- Check if the lmb was released
      if gui_state.input and gui_state.input.mouse.buttons[1] and
        gui_state.input.mouse.buttons[1].releases > 0
      then
        local rect = get_dragged_rect(state, gui_state, img_w, img_h)
        if rect and rect.w > 0 and rect.h > 0 then
          app.quadtastic.create(rect)
        end
      end
    end
end

local function select_tool(app, gui_state, state, img_w, img_h)
  -- Check if we should start resizing a quad
  if not state.toolstate.resizing then
    local mx, my = gui_state.input.mouse.x, gui_state.input.mouse.y
    mx, my = gui_state.transform:unproject(mx, my)

    -- Returns the directions in which a quad should be resized based on where
    -- the mouse was pressed
    local function get_resize_directions(quad)
      local direction = {}
      if math.abs(mx - quad.x) <= 1 then
        direction.w = true
      elseif math.abs(mx - (quad.x + quad.w)) <= 1 then
        direction.e = true
      end
      if math.abs(my - quad.y) <= 1 then
        direction.n = true
      elseif math.abs(my - (quad.y + quad.h)) <= 1 then
        direction.s = true
      end
      if not (direction.n or direction.e or direction.s or direction.w) then
        return nil
      else
        return direction
      end
    end

    -- Check if the mous was pressed on the border of a selected quad
    local direction
    if state.hovered and state.selection:is_selected(state.hovered) then
      direction = get_resize_directions(state.hovered)
    else -- check each selected quad
      for _, quad in pairs(state.selection:get_selection()) do
        if libquadtastic.is_quad(quad) then
          direction = get_resize_directions(quad)
          if direction then break end
        end
      end
    end
    if direction then
      state.toolstate.resizing = direction
      state.toolstate.selecting = nil
      state.toolstate.dragging = nil
      -- Set the cursor
      if direction.n and direction.e or direction.s and direction.w then
        cursor_string = "resize_nesw"
      elseif direction.n and direction.w or direction.s and direction.e then
        cursor_string = "resize_nwse"
      elseif direction.n or direction.s then
        cursor_string = "resize_ns"
      elseif direction.w or direction.e then
        cursor_string = "resize_we"
      end
      love.mouse.setCursor(gui_state.style[cursor_string])
    end

  end

  local f = fun.partial(imgui.is_key_pressed, gui_state)
  if state.hovered and not state.toolstate.selecting and
     not state.toolstate.resizing
  then
    -- If the hovered quad is already selected, show the movement cursor, and
    -- move the quads when the mouse is dragged
    if state.selection:is_selected(state.hovered) then
      love.mouse.setCursor(gui_state.style.hand_cursor)
      if gui_state.input.mouse.buttons[1] and gui_state.input.mouse.buttons[1].pressed then
        state.toolstate.dragging = true
      end
    -- Else select it on click
    elseif imgui.was_mouse_released(gui_state, state.hovered.x, state.hovered.y,
                                    state.hovered.w, state.hovered.h)
    then
      -- Change selection depending on modifiers
      -- If neither shift or ctrl is pressed, clear the selection
      if fun.any(f, {"lshift", "rshift", "lctrl", "rctrl"}) then
        state.selection:select({state.hovered})
      else
        state.selection:set_selection({state.hovered})
      end
      QuadList.move_quad_into_view(state.quad_scrollpane_state, state.hovered)
    end

  -- The mouse is not hovering over any quads. Check if we should draw a
  -- selection box
  elseif gui_state.input.mouse.buttons[1] and
        gui_state.input.mouse.buttons[1].pressed and
        not state.toolstate.resizing
  then
    -- If neither shift or ctrl is pressed, clear the selection
    if not fun.any(f, {"lshift", "rshift", "lctrl", "rctrl"}) then
      state.selection:clear_selection()
    end
    state.toolstate.selecting = true

    local rect = get_dragged_rect(state, gui_state)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.push("all")
    love.graphics.setLineStyle("rough")
    love.graphics.setLineWidth(1/state.display.zoom)
    draw_dashed_line(rect, gui_state)
    love.graphics.pop()

    -- Highlight all quads that are enclosed in the dragged rect
    local keys, quad = iter_quads(state.quads)
    love.graphics.setColor(82, 128, 191, 128)
    while keys do
      if Rectangle.contains(rect, quad.x, quad.y, quad.w, quad.h) then
        love.graphics.rectangle("fill", quad.x, quad.y, quad.w, quad.h)
      end
      keys, quad = iter_quads(state.quads, keys)
    end
  end

  if not (gui_state.input.mouse.buttons[1] and
          gui_state.input.mouse.buttons[1].pressed)
  then
    state.toolstate.dragging = nil

    if state.toolstate.selecting then
      -- Add all quads to the selection that are enclosed in the dragged rect
      local rect = get_dragged_rect(state, gui_state)
      local keys, quad = iter_quads(state.quads)
      while keys do
        if Rectangle.contains(rect, quad.x, quad.y, quad.w, quad.h) then
          state.selection:select({quad})
        end
        keys, quad = iter_quads(state.quads, keys)
      end
    end
    state.toolstate.selecting = nil
    state.toolstate.resizing = nil
  end

  -- dragged movement in sprite pixels
  local dpx, dpy = 0, 0
  if gui_state.input.mouse.buttons[1] then
    local dx, dy = gui_state.input.mouse.dx, gui_state.input.mouse.dy
    dx, dy = gui_state.transform:unproject_dimensions(dx, dy)
    local acc_dx = gui_state.input.mouse.old_x - gui_state.input.mouse.buttons[1].at_x
    local acc_dy = gui_state.input.mouse.old_y - gui_state.input.mouse.buttons[1].at_y
    acc_dx, acc_dy = gui_state.transform:unproject_dimensions(acc_dx, acc_dy)
    dpx = math.modf(acc_dx + dx) - math.modf(acc_dx)
    dpy = math.modf(acc_dy + dy) - math.modf(acc_dy)
  end

  if state.toolstate.dragging then
    -- Move the quads by the dragged amount
    if dpx ~= 0 or dpy ~= 0 then
      app.quadtastic.move_quads(state.selection:get_selection(), dpx, dpy)
    end
  elseif state.toolstate.resizing and (dpx ~= 0 or dpy ~= 0) then
    app.quadtastic.resize_quads(state.selection:get_selection(),
                                state.toolstate.resizing,
                                dpx, dpy, img_w, img_h)
  end

end

local function handle_input(app, gui_state, state, img_w, img_h)
    if state.toolstate.type == "create" then
      create_tool(app, gui_state, state, img_w, img_h)
    elseif state.toolstate.type == "select" then
      select_tool(app, gui_state, state, img_w, img_h)
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
end

ImageEditor.draw = function(app, gui_state, state, x, y, w, h)
  local content_w, content_h
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

    -- Draw the outlines of all quads
    for name, quad in pairs(state.quads) do
      show_quad(gui_state, state, quad, tostring(name))
    end

    if gui_state and gui_state.input then
      handle_input(app, gui_state, state, img_w, img_h)
    end

    content_w = img_w * state.display.zoom
    content_h = img_h * state.display.zoom
  end Scrollpane.finish(gui_state, state.scrollpane_state, content_w, content_h)
end

return ImageEditor