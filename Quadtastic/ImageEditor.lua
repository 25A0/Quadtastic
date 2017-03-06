local Scrollpane = require("Scrollpane")

local ImageEditor = {}

local function show_quad(quad)
  if type(quad) == "table" and
    quad.x and quad.y and quad.w and quad.h
  then
    love.graphics.setColor(255, 255, 255, 255)
    -- We'll draw the quads differently if the viewport is zoomed out
    -- all the way
    if state.display.zoom == 1 then
      if quad.w > 1 and quad.h > 1 then
        love.graphics.rectangle("line", quad.x + .5, quad.y + .5, quad.w - 1, quad.h - 1)
      elseif quad.w > 1 or quad.h > 1 then
        love.graphics.rectangle("fill", quad.x, quad.y, quad.w, quad.h)
      else
        love.graphics.rectangle("fill", quad.x, quad.y, 1, 1)
      end
    else
      love.graphics.push("all")
      love.graphics.setLineWidth(1/state.display.zoom)
      love.graphics.rectangle("line", quad.x, quad.y, quad.w, quad.h)
      love.graphics.pop()
    end
  end
end

local function handle_input(gui_state, state, x, y, w, h, img_w, img_h)
    -- Draw a bright pixel where the mouse is
    love.graphics.setColor(255, 255, 255, 255)
    if gui_state.input then
      local mx, my = gui_state.transform:unproject(
        gui_state.input.mouse.x, gui_state.input.mouse.y)
      mx, my = math.floor(mx), math.floor(my)
      love.graphics.rectangle("fill", mx, my, 1, 1)
    end

    local get_dragged_rect = function(gui_state, sp_state)
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

    -- Draw a rectangle at the mouse's dragged area
    do
      if gui_state.input and gui_state.input.mouse.buttons[1] and 
        gui_state.input.mouse.buttons[1].pressed
      then
        local rect = get_dragged_rect(gui_state, scrollpane_state)
        if rect then
          show_quad(rect)
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
        local rect = get_dragged_rect(gui_state, scrollpane_state)
        if rect and rect.w > 0 and rect.h > 0 then
          table.insert(state.quads, rect)
        end
      end
    end

end

ImageEditor.draw = function(gui_state, state, x, y, w, h)
  do state.scrollpane_state = Scrollpane.start(gui_state, nil, nil, nil, 
    nil, state.scrollpane_state
  )
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.scale(state.display.zoom, state.display.zoom)

    -- Draw background pattern
    local img_w, img_h = state.image:getDimensions()
    local backgroundquad = love.graphics.newQuad(0, 0, img_w, img_h, 8, 8)
    love.graphics.draw(backgroundcanvas, backgroundquad)

    love.graphics.draw(state.image)

    if gui_state and gui_state.input then
      handle_input(gui_state, state, x, y, w, h, img_w, img_h)
    end

    -- Draw the outlines of all quads
    for _, quad in pairs(state.quads) do
      show_quad(quad)
    end

    local content_w = img_w * state.display.zoom
    local content_h = img_h * state.display.zoom
  end Scrollpane.finish(gui_state, state.scrollpane_state, content_w, content_h)
end

return ImageEditor