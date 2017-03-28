local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local renderutils = require(current_folder .. ".Renderutils")
local imgui = require(current_folder .. ".imgui")
local Text = require(current_folder .. ".Text")

local Inputfield = {}

local function handle_input(state, _, y, w, h, content, text_x)
  assert(state.input)
  -- Track whether the cursor was moved. In that case we will always display it
  local cursor_moved = false

  local function has_selection() return state.input_field.selection_end end
  local function is_shift_down()
    return imgui.is_key_pressed(state, "lshift") or
           imgui.is_key_pressed(state, "rshift")
  end
  local function clear_selection() state.input_field.selection_end = nil end
  local function get_selection_range()
    local from = math.min(state.input_field.selection_end, state.input_field.cursor_pos)
    local to = math.max(state.input_field.selection_end, state.input_field.cursor_pos)
    return from, to
  end

  if has_selection() then
    assert(state.input_field.selection_end ~= state.input_field.cursor_pos)
    -- Adjust selection to size of content
    state.input_field.selection_end = math.max(0, state.input_field.selection_end)
    state.input_field.selection_end = math.min(#content, state.input_field.selection_end)
  end

  -- Change the cursor position based on special key presses
  if imgui.was_key_pressed(state, "left") then
    local new_cursor = math.max(0, state.input_field.cursor_pos - 1)
    if is_shift_down() then
      if not has_selection() then
        state.input_field.selection_end = state.input_field.cursor_pos
      end
    elseif has_selection() then
      new_cursor = math.min(state.input_field.selection_end, state.input_field.cursor_pos)
      clear_selection()
    end
    state.input_field.cursor_pos = new_cursor
    cursor_moved = true
  end
  if imgui.was_key_pressed(state, "right") then
    local new_cursor = math.min(#content, state.input_field.cursor_pos + 1)
    if is_shift_down() then
      if not has_selection() then
        state.input_field.selection_end = state.input_field.cursor_pos
      end
    elseif has_selection() then
      new_cursor = math.max(state.input_field.selection_end, state.input_field.cursor_pos)
      clear_selection()
    end
    state.input_field.cursor_pos = new_cursor
    cursor_moved = true
  end
  if imgui.was_key_pressed(state, "home") then
    local new_cursor = 0
    if is_shift_down() then
      if not has_selection() then
        state.input_field.selection_end = state.input_field.cursor_pos
      end
    elseif has_selection() then
        clear_selection()
    end
    state.input_field.cursor_pos = new_cursor
    cursor_moved = true
  end
  if imgui.was_key_pressed(state, "end") then
    local new_cursor = #content
    if is_shift_down() then
      if not has_selection() then
        state.input_field.selection_end = state.input_field.cursor_pos
      end
    elseif has_selection() then
        clear_selection()
    end
    state.input_field.cursor_pos = new_cursor
    cursor_moved = true
  end
  if imgui.was_key_pressed(state, "escape") and has_selection() then
    -- consume keypress
    imgui.consume_key_press(state, "escape")
    clear_selection()
  end

  local function delete_selection()
    local from, to = get_selection_range()
    content = string.sub(content, 1 , from) ..
              string.sub(content, to + 1, -1)
    state.input_field.cursor_pos = from
    clear_selection()
  end

  -- Remove character to the left of the cursor
  if imgui.was_key_pressed(state, "backspace") then
    if has_selection() then
      delete_selection()
    elseif state.input_field.cursor_pos > 0 then
      content = string.sub(content, 1 , state.input_field.cursor_pos - 1) ..
                string.sub(content, state.input_field.cursor_pos + 1, -1)
      -- Reduce cursor position by 1
      state.input_field.cursor_pos = math.max(0, state.input_field.cursor_pos - 1)
    end
  end
  -- Remove character to the right of the cursor
  if imgui.was_key_pressed(state, "delete") then
    if has_selection() then
      delete_selection()
    elseif state.input_field.cursor_pos < #content then
      content = string.sub(content, 1 , state.input_field.cursor_pos) ..
                string.sub(content, state.input_field.cursor_pos + 2, -1)
      -- The cursor position does not change in this case
    end
  end

  local newtext = state.input.keyboard.text or ""
  if #newtext > 0 and has_selection() then
    delete_selection()
  end
  content = string.sub(content, 1 , state.input_field.cursor_pos) ..
            newtext ..
            string.sub(content, state.input_field.cursor_pos + 1, -1)
  -- Advance the cursor position by the lenght of the added text
  state.input_field.cursor_pos = math.min(#content, state.input_field.cursor_pos + #newtext)

  -- Calculate print offset based on state's cursor
  do
    -- Move text start to the left if text width is larger than field width
    local cursor_text_width = Text.min_width(state,
      string.sub(content, 1, state.input_field.cursor_pos))
    if cursor_text_width + 20 > w - 6 then
      text_x = text_x - (cursor_text_width + 20 - (w-6))
    end
  end

  -- Display the cursor
  state.input_field.cursor_dt = state.input_field.cursor_dt + state.dt
  if state.input_field.cursor_dt > 1 then
    state.input_field.cursor_dt = state.input_field.cursor_dt - 1
  end
  if state.input_field.cursor_dt < .5 then
    local width = Text.min_width(state, string.sub(
      content, 1, state.input_field.cursor_pos))
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.line(text_x + width, y + 4, text_x + width, y + h - 4)
  end

  -- Highlight the selection
  if has_selection() then
    love.graphics.setColor(255, 255, 255, 80)
    local from, to = get_selection_range()
    local x_from = Text.min_width(state, string.sub(content, 1, from))
    local x_to = Text.min_width(state, string.sub(content, 1, to))
    love.graphics.rectangle("fill", text_x + x_from, y + 4, x_to - x_from, h - 8)
    love.graphics.setColor(255, 255, 255, 255)
  end

  local cursor_pos_at_mousex
  -- Calculate the cursor position only once since it's a pricey calculation
  if state.input.mouse.buttons[1] and
    (state.input.mouse.buttons[1].pressed or
     state.input.mouse.buttons[1].presses > 0)
  then
    local mx = state.input.mouse.x
    -- Set the cursor position
    local delta = state.transform:unproject(mx, 0) - text_x
    -- Find the max. length of characters that fit in delta
    local m_width = Text.min_width(state, "m")
    -- Assume that the text is just a ton of ms
    local cursor_pos = math.floor(delta / m_width)
    local actual_width = Text.min_width(state, string.sub(content, 1, cursor_pos))
    local last_letter_width = 0
    -- Make sure that we didn't mess up the estimation
    while actual_width > delta and not (cursor_pos <= 0) do
      cursor_pos = cursor_pos - 1
      local new_width = Text.min_width(state, string.sub(content, 1, cursor_pos))
      last_letter_width = math.abs(actual_width - new_width)
      actual_width = new_width
    end
    -- And then search in the opposite direction
    while actual_width < delta and not (cursor_pos >= #content) do
      cursor_pos = cursor_pos + 1
      local new_width = Text.min_width(state, string.sub(content, 1, cursor_pos))
      last_letter_width = math.abs(actual_width - new_width)
      actual_width = new_width
    end
    -- Round the cursor position
    if actual_width - delta > .5 * last_letter_width then cursor_pos = cursor_pos - 1 end
    cursor_pos = math.floor(cursor_pos + .5)
    if cursor_pos ~= state.input_field.cursor_pos then
      cursor_moved = true
    end

    -- Limit cursor position
    cursor_pos_at_mousex = math.max(0, math.min(#content, cursor_pos))
  end


  -- If the LMB is still pressed, extend the selection accordingly
  if state.input.mouse.buttons[1] and
    state.input.mouse.buttons[1].pressed
  then
    assert(cursor_pos_at_mousex)
    local cursor_pos = cursor_pos_at_mousex

    if not has_selection() then
      state.input_field.selection_end = state.input_field.cursor_pos
    end
    state.input_field.cursor_pos = cursor_pos
  end

  -- If the LMB was pressed in the last frame, set the cursor position
  if state.input.mouse.buttons[1] and
    state.input.mouse.buttons[1].presses > 0
  then
    assert(cursor_pos_at_mousex)
    local cursor_pos = cursor_pos_at_mousex

    if is_shift_down() then
      if not has_selection() then
        state.input_field.selection_end = cursor_pos
      end
    elseif has_selection() then
      clear_selection()
    end
    state.input_field.cursor_pos = cursor_pos
  end

  -- Remove an empty selection
  if has_selection() and
    state.input_field.selection_end == state.input_field.cursor_pos
  then
    clear_selection()
  end

  if cursor_moved then
    state.input_field.cursor_dt = 0
  end
  return content, text_x
end

Inputfield.draw = function(state, x, y, w, h, content, options)
  x = x or state.layout.next_x
  y = y or state.layout.next_y

  local margin_x = 4
  local textwidth = Text.min_width(state, content)
  w = w or math.max(32, 2*margin_x + (textwidth or 32))
  h = h or 18

  state.layout.adv_x = w
  state.layout.adv_y = h

  -- Draw border
  love.graphics.setColor(255, 255, 255, 255)
  renderutils.draw_border(state.style.stylesheet, state.style.quads.input_field_border, x, y, w, h, 3)

  -- Push state
  love.graphics.push("all")

  -- Restrict printing to the enclosed area
  do
    local abs_x, abs_y = state.transform:project(x + 2, y + 2)
    local abs_w, abs_h = state.transform:project_dimensions(w - 4, h - 4)
    abs_w = math.max(0, abs_w)
    abs_h = math.max(0, abs_h)
    love.graphics.intersectScissor(abs_x, abs_y, abs_w, abs_h)
  end

  -- Highlight if mouse is over button
  if state and state.input and
    imgui.is_mouse_in_rect(state, x, y, w, h)
  then
    -- Change cursor to indicate editable text
    love.mouse.setCursor(state.style.cursors.text_cursor)
  end

  -- Label position
  local text_x = x + margin_x

  local committed_content
  if state and state.input then
    local has_focus = false
    -- Check if options force keyboard focus
    if options and options.forced_keyboard_focus then
      has_focus = true
    elseif state.input.mouse.buttons[1] then
      local mx = state.input.mouse.buttons[1].at_x
      local my = state.input.mouse.buttons[1].at_y
      -- This widget has the keyboard focus if the last LMB click was inside this
      -- widget
      if imgui.is_mouse_in_rect(state, x, y, w, h, mx, my) then
        has_focus = true
      end
    end

    if has_focus then
      if options and options.select_all then
        state.input_field.cursor_pos = #content
        state.input_field.selection_end = 0
      end
      content, text_x = handle_input(state, x, y, w, h, content, text_x)
      if imgui.was_key_pressed(state, "return") then
        committed_content = content
        imgui.consume_key_press(state, "return")
      end
    else
      -- The widget does not have the keyboard focus
      if textwidth + 20 > w - 6 then
        text_x = text_x - (textwidth + 20 - (w-6))
      end
    end
  end

  local margin_y = (h - 16) / 2
  local text = content
  if #content == 0 and options and options.ghost_text then
    text = options.ghost_text
    options.font_color = {255, 255, 255, 128}
  end
  Text.draw(state, text_x, y + margin_y, nil, nil, text, options)

  -- Restore state
  love.graphics.pop()
  return content, committed_content
end

return Inputfield