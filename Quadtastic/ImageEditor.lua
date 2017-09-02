local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local Scrollpane = require(current_folder .. ".Scrollpane")
local libquadtastic = require(current_folder .. ".libquadtastic")
local imgui = require(current_folder .. ".imgui")
local Rectangle = require(current_folder .. ".Rectangle")
local QuadList = require(current_folder .. ".QuadList")
local fun = require(current_folder .. ".fun")
local img_analysis = require(current_folder .. ".img_analysis")

local ImageEditor = {}

function ImageEditor.zoom(state, delta)
  -- Ignore zoom instructions if no image is loaded
  if not state.image then return end

  if not state.display.zoom then state.display.zoom = 1 end
  local cx, cy = Rectangle.center(state.scrollpane_state)
  cx, cy = cx / state.display.zoom, cy / state.display.zoom
  local new_zoom
  if state.display.zoom <= 1 then
    if delta > 0 then
      new_zoom = state.display.zoom * 2
    elseif delta < 0 then
      new_zoom = state.display.zoom / 2
    else new_zoom = state.display.zoom end
  else
    new_zoom = math.floor(state.display.zoom + delta)
  end
  state.display.zoom = math.max(1/32, math.min(12, new_zoom))
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

local function draw_dashed_line(quad, gui_state, zoom)
  local t = gui_state.second
  local spritebatch_h = gui_state.style.dashed_line.horizontal.spritebatch
  local spritebatch_v = gui_state.style.dashed_line.vertical.spritebatch
  local size = gui_state.style.dashed_line.size
  local offset = 0
  local quad_top   = love.graphics.newQuad(offset + t*size, 0, quad.w * zoom, 1, size, 1)
  offset = math.fmod(offset + quad.w * zoom, size)
  local quad_right = love.graphics.newQuad(0, offset + t*size, 1, quad.h * zoom, 1, size)
  offset = math.fmod(offset + quad.h * zoom, size)
  local quad_bottom= love.graphics.newQuad(offset + t*size, 0, quad.w * zoom, 1, size, 1)
  offset = math.fmod(offset + quad.w * zoom, size)
  local quad_left  = love.graphics.newQuad(0, offset + t*size, 1, quad.h * zoom, 1, size)

  local x, y, w, h = quad.x, quad.y, quad.w, quad.h
  local d = .5/zoom -- offset to center the line on the quad's border
  local s = 1/zoom -- scale factor
  spritebatch_h:add(quad_top   , x     - d, y     - d, 0, s, s)
  spritebatch_v:add(quad_right , x + w - d, y     - d, 0, s, s)
  spritebatch_h:add(quad_bottom, x + w + d, y + h - d, 0, -s, s)
  spritebatch_v:add(quad_left  , x     - d, y + h + d, 0, s, -s)
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

    love.graphics.push("all")
    love.graphics.setLineStyle("rough")
    love.graphics.setLineWidth(1/state.display.zoom)
    if quad == state.hovered and (state.tool == "select" or
                                  state.tool == "create") or
       state.selection:is_selected(quad)
    then
      -- Use a dashed line to outline the quad
      love.graphics.setColor(255, 255, 255)
      draw_dashed_line(quad, gui_state, state.display.zoom)
    else
      -- Use a simple line to outline the quad
      love.graphics.rectangle("line", quad.x, quad.y, quad.w, quad.h)
    end
    love.graphics.pop()

  elseif type(quad) == "table" then
    -- If it's not a quad then it's a list of quads
    for k,v in pairs(quad) do
      local name = quadname and quadname .. "." .. tostring(k) or tostring(k)
      show_quad(gui_state, state, v, name)
    end
  end
end

-- Snap value to the left or top of the grid tile
local function grid_floor(grid, val)
  return val - (val % grid)
end

-- Snap value to the right or bottom of the grid tile
local function grid_ceil(grid, val)
  return val + (grid - val % grid - 1)
end

-- Returns the closest grid multiple of val.
-- For example, grid_mult(8,  7) -> 8
--              grid_mult(8, 11) -> 8
local function grid_mult(grid, val)
  if val % grid > grid / 2 then
    return val + grid - val % grid
  else
    return val - val % grid
  end
end

-- Returns the closest grid point to px and py.
local function snap_point_to_grid(grid, px, py)
  local gx, gy
  if px % grid.x >= grid.x / 2 then
    gx = grid_ceil(grid.x, px)
  else
    gx = grid_floor(grid.x, px)
  end
  if py % grid.y >= grid.y / 2 then
    gy = grid_ceil(grid.y, py)
  else
    gy = grid_floor(grid.y, py)
  end
  return gx, gy
end

-- Returns a new rectangle where all four corners snapped to the grid.
-- Note that the four corners will be snapped differently. For example, in a 8x8
-- grid, the left side of the rectangle can be at x positions 0, 8, 16, 24, ...,
-- while the right side of the rectangle can be at x positions 7, 15, 23, 31, ....
local function snap_rect_to_grid(grid, rect)
  local grid_rect = {}
  grid_rect.x = grid_floor(grid.x, rect.x)
  grid_rect.y = grid_floor(grid.y, rect.y)

  local min_w = rect.w + rect.x - grid_rect.x
  local min_h = rect.h + rect.y - grid_rect.y
  grid_rect.w = grid_mult(grid.x, min_w)
  grid_rect.h = grid_mult(grid.y, min_h)

  return grid_rect
end

local function expand_rect_to_grid(grid, rect)
  local grid_rect = {}
  grid_rect.x = grid_floor(grid.x, rect.x)
  grid_rect.y = grid_floor(grid.y, rect.y)
  -- If the rectangle was moved to the left or to the top, then the width and
  -- height need to change accordingly to make sure that the content is still
  -- enclosed in the rectangle.
  local min_w = rect.w + rect.x - grid_rect.x
  local min_h = rect.h + rect.y - grid_rect.y
  -- In this function, the width and height will always expand up to the next
  -- multiple of the grid size. This prevents that small sprites snap to a
  -- width that does not include the entire sprite.
  grid_rect.w = math.max(grid.x, grid.x * math.ceil(min_w / grid.x))
  grid_rect.h = math.max(grid.y, grid.y * math.ceil(min_h / grid.y))

  return grid_rect
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

local function should_snap_to_grid(gui_state, state)
  local should_snap = state.settings.grid.always_snap
  if imgui.are_exact_modifiers_pressed(gui_state, {"*alt"}) then
    -- invert should_snap
    should_snap = not should_snap
  end
  return should_snap
end

local function create_tool(app, gui_state, state, img_w, img_h)
    -- Draw a bright pixel where the mouse is
    love.graphics.setColor(255, 255, 255, 255)
    if gui_state.input then
      local mx, my = gui_state.transform:unproject(
        gui_state.input.mouse.x, gui_state.input.mouse.y)
      mx, my = math.floor(mx), math.floor(my)
      if should_snap_to_grid(gui_state, state) then
        mx, my = snap_point_to_grid(state.settings.grid, mx, my)
      end
      love.graphics.rectangle("fill", mx, my, 1, 1)
    end

    -- Draw a rectangle at the mouse's dragged area
    do
      if gui_state.input and gui_state.input.mouse.buttons[1] and
        gui_state.input.mouse.buttons[1].pressed
      then
        local rect = get_dragged_rect(state, gui_state, img_w, img_h)
        if rect then
          if should_snap_to_grid(gui_state, state) then
            rect = snap_rect_to_grid(state.settings.grid, rect)
          end
          show_quad(gui_state, state, rect)
          gui_state.mousestring = string.format("%dx%d", rect.w, rect.h)
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
        if rect then
          if should_snap_to_grid(gui_state, state) then
            rect = snap_rect_to_grid(state.settings.grid, rect)
          end

          if rect.w > 0 and rect.h > 0 then
            app.quadtastic.create(rect)
          end
        end
      end
    end
end

local function wand_tool(app, gui_state, state)
  if gui_state.input then
    -- Draw a bright pixel where the mouse is
    love.graphics.setColor(255, 255, 255, 255)
    local mx, my = gui_state.transform:unproject(
      gui_state.input.mouse.x, gui_state.input.mouse.y)
    mx, my = math.floor(mx), math.floor(my)
    love.graphics.rectangle("fill", mx, my, 1, 1)
    -- If a rectangle larger than 1px is dragged, scan the dragged
    local rect
    if gui_state.input.mouse.buttons[1] and (
        gui_state.input.mouse.buttons[1].pressed or
        gui_state.input.mouse.buttons[1].releases >= 1
      )
    then
      local img_w, img_h = state.image:getDimensions()
      rect = get_dragged_rect(state, gui_state, img_w, img_h)
    end

    if rect and rect.w > 1 and rect.h > 1 then
      show_quad(gui_state, state, rect)
      local rects = img_analysis.enclosed_chunks(state.image, rect.x, rect.y, rect.w, rect.h)
      if should_snap_to_grid(gui_state, state) then
        -- Expand all rectangles to tile size
        for i, r in ipairs(rects) do
          rects[i] = expand_rect_to_grid(state.settings.grid, r)
        end
      end
      for _, r in ipairs(rects) do
        draw_dashed_line(r, gui_state, state.display.zoom)
      end
      gui_state.mousestring = string.format("%d quads", #rects)
      if not gui_state.input.mouse.buttons[1].pressed and #rects > 0 then
        app.quadtastic.create(rects)
      end
    else
      -- Find strip of opaque pixels
      local quad = img_analysis.outter_bounding_box(state.image, mx, my)
      if quad and should_snap_to_grid(gui_state, state) then
        quad = expand_rect_to_grid(state.settings.grid, quad)
      end
      if quad then
        draw_dashed_line(quad, gui_state, state.display.zoom)
        gui_state.mousestring = string.format("%dx%d", quad.w, quad.h)
        if gui_state.input.mouse.buttons[1] and
          gui_state.input.mouse.buttons[1].presses >= 1
        then
          app.quadtastic.create(quad)
        end
      end
    end
  end
end

local function palette_tool(app, gui_state, state)
  if gui_state.input then
    -- Draw a bright pixel where the mouse is
    love.graphics.setColor(255, 255, 255, 255)
    local mx, my = gui_state.transform:unproject(
      gui_state.input.mouse.x, gui_state.input.mouse.y)
    mx, my = math.floor(mx), math.floor(my)
    love.graphics.rectangle("fill", mx, my, 1, 1)
    -- If a rectangle larger than 1px is dragged, scan the dragged
    local rect
    if gui_state.input.mouse.buttons[1] and (
        gui_state.input.mouse.buttons[1].pressed or
        gui_state.input.mouse.buttons[1].releases >= 1
      )
    then
      local img_w, img_h = state.image:getDimensions()
      rect = get_dragged_rect(state, gui_state, img_w, img_h)
    end

    if rect and rect.w > 0 and rect.h > 0 then
      show_quad(gui_state, state, rect)
      local rects = img_analysis.palette(state.image, rect.x, rect.y, rect.w, rect.h)
      for _, r in ipairs(rects) do
        draw_dashed_line(r, gui_state, state.display.zoom)
      end
      gui_state.mousestring = string.format("%d quads", #rects)
      if not gui_state.input.mouse.buttons[1].pressed and #rects > 0 then
        app.quadtastic.create(rects)
      end
    end
  end
end

local function select_tool(app, gui_state, state, img_w, img_h)
  -- Check if we should start resizing a quad
  local direction

  local function get_cursor_string(dir)
    local cursor_string
    if dir.n and dir.e or dir.s and dir.w then
      cursor_string = "sizenesw"
    elseif dir.n and dir.w or dir.s and dir.e then
      cursor_string = "sizenwse"
    elseif dir.n or dir.s then
      cursor_string = "sizens"
    elseif dir.w or dir.e then
      cursor_string = "sizewe"
    end
    return cursor_string
  end

  if not state.toolstate.mode then
    local mx, my = gui_state.input.mouse.x, gui_state.input.mouse.y
    mx, my = gui_state.transform:unproject(mx, my)

    -- Returns the directions in which a quad should be resized based on where
    -- the mouse was pressed
    local function get_resize_directions(quad)
      -- Make a rough check to see if the mouse is near any edge
      if mx < quad.x - 1 or mx > quad.x + quad.w + 1 or
         my < quad.y - 1 or my > quad.y + quad.h + 1
      then
        return nil
      end

      local border = 2/state.display.zoom
      local dir = {}

      if math.abs(mx - quad.x) <= border then
        dir.w = true
      elseif math.abs(mx - (quad.x + quad.w)) <= border then
        dir.e = true
      end
      if math.abs(my - quad.y) <= border then
        dir.n = true
      elseif math.abs(my - (quad.y + quad.h)) <= border then
        dir.s = true
      end
      if not (dir.n or dir.e or dir.s or dir.w) then
        return nil
      else
        return dir
      end
    end

    -- Check if the mouse was pressed on the border of a selected quad
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
      if gui_state.input.mouse.buttons[1] and
         gui_state.input.mouse.buttons[1].presses >= 1
      then
        state.toolstate.mode = "resizing"
        state.toolstate.direction = direction

        -- Store the initial size of each quad
        state.toolstate.original_quad = {}
        for i,v in ipairs(state.selection:get_selection()) do
          if libquadtastic.is_quad(v) then
            state.toolstate.original_quad[i] = {x = v.x, y = v.y, w = v.w, h = v.h}
          end
        end
      end

      -- Set the cursor
      love.mouse.setCursor(gui_state.style.cursors[get_cursor_string(direction)])
    end

  end

  local f = fun.partial(imgui.is_key_pressed, gui_state)
  if state.hovered and not state.toolstate.mode and not direction then
    -- If the hovered quad is already selected, show the movement cursor, and
    -- move the quads when the mouse is dragged
    if state.selection:is_selected(state.hovered) then
      if gui_state.input.mouse.buttons[1] and
         gui_state.input.mouse.buttons[1].presses >= 1
      then
        state.toolstate.mode = "dragging"
        -- Save the locations of all quads
        state.toolstate.original_pos = {}
        for i,v in ipairs(state.selection:get_selection()) do
          if libquadtastic.is_quad(v) then
            state.toolstate.original_pos[i] = {x = v.x, y = v.y}
          end
        end
      else
        love.mouse.setCursor(gui_state.style.cursors.hand_cursor)
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
        (not state.toolstate.mode or state.toolstate.mode == "selecting")
  then
    -- If neither shift or ctrl is pressed, clear the selection
    if not fun.any(f, {"lshift", "rshift", "lctrl", "rctrl"}) then
      state.selection:clear_selection()
    end
    state.toolstate.mode = "selecting"

    local rect = get_dragged_rect(state, gui_state)
    love.graphics.setColor(255, 255, 255, 255)
    draw_dashed_line(rect, gui_state, state.display.zoom)

    -- Highlight all quads that are enclosed in the dragged rect
    local keys, quad = iter_quads(state.quads)
    love.graphics.setColor(gui_state.style.palette.shades.bright(128))
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

    if state.toolstate.mode == "selecting" then
      -- Add all quads to the selection that are enclosed in the dragged rect
      local rect = get_dragged_rect(state, gui_state)
      local keys, quad = iter_quads(state.quads)
      while keys do
        if Rectangle.contains(rect, quad.x, quad.y, quad.w, quad.h) then
          state.selection:select({quad})
        end
        keys, quad = iter_quads(state.quads, keys)
      end
    elseif state.toolstate.mode == "dragging" then
      app.quadtastic.commit_movement(state.selection:get_selection(),
                                     state.toolstate.original_pos)
    elseif state.toolstate.mode == "resizing" then
      app.quadtastic.commit_resizing(state.selection:get_selection(),
                                     state.toolstate.original_quad)
    end
    state.toolstate.mode = nil
  end

  -- dragged movement in sprite pixels
  local dpx, dpy = 0, 0
  if gui_state.input.mouse.buttons[1] then
    local acc_dx = gui_state.input.mouse.x - gui_state.input.mouse.buttons[1].at_x
    local acc_dy = gui_state.input.mouse.y - gui_state.input.mouse.buttons[1].at_y
    acc_dx, acc_dy = gui_state.transform:unproject_dimensions(acc_dx, acc_dy)
    dpx = math.modf(acc_dx)
    dpy = math.modf(acc_dy)
  end

  if state.toolstate.mode == "dragging" then
    love.mouse.setCursor(gui_state.style.cursors.move_cursor)
    -- Move the quads by the dragged amount
    app.quadtastic.move_quads(state.selection:get_selection(),
                              state.toolstate.original_pos,
                              dpx, dpy, img_w, img_h)
  elseif state.toolstate.mode == "resizing" then
    love.mouse.setCursor(gui_state.style.cursors[get_cursor_string(state.toolstate.direction)])
    app.quadtastic.resize_quads(state.selection:get_selection(),
                                state.toolstate.original_quad,
                                state.toolstate.direction,
                                dpx, dpy, img_w, img_h)
  end

end

local function handle_input(app, gui_state, state, img_w, img_h)
    if state.tool == "create" then
      create_tool(app, gui_state, state, img_w, img_h)
    elseif state.tool == "select" then
      select_tool(app, gui_state, state, img_w, img_h)
    elseif state.tool == "wand" then
      wand_tool(app, gui_state, state, img_w, img_h)
    elseif state.tool == "palette" then
      palette_tool(app, gui_state, state, img_w, img_h)
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
    local backgroundquad = love.graphics.newQuad(0, 0, img_w, img_h, 2 * state.settings.grid.x, 2 * state.settings.grid.y)
    love.graphics.draw(gui_state.style.backgroundcanvas, backgroundquad)

    love.graphics.draw(state.image)

    -- Draw the outlines of all quads
    for name, quad in pairs(state.quads) do
      show_quad(gui_state, state, quad, tostring(name))
    end

    if gui_state and gui_state.input then
      handle_input(app, gui_state, state, img_w, img_h)
    end

    -- Draw dashed lines, then clear spritebatches
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(gui_state.style.dashed_line.horizontal.spritebatch)
    gui_state.style.dashed_line.horizontal.spritebatch:clear()
    love.graphics.draw(gui_state.style.dashed_line.vertical.spritebatch)
    gui_state.style.dashed_line.vertical.spritebatch:clear()

    content_w = img_w * state.display.zoom
    content_h = img_h * state.display.zoom
  end Scrollpane.finish(gui_state, state.scrollpane_state, content_w, content_h)
end

return ImageEditor