local Rectangle = require("Quadtastic/Rectangle")
local renderutils = require("Quadtastic/Renderutils")
local imgui = require("Quadtastic/imgui")
local Text = require("Quadtastic/Text")

local Inputfield = {}

local transform = require("Quadtastic/transform")

-- Cache ibeam cursor
local i_beam_cursor = love.mouse.getSystemCursor("ibeam")

local function handle_input(state, x, y, w, h, content, options, text_x)
  assert(state.input)
  -- Track whether the cursor was moved. In that case we will always display it
  local cursor_moved = false

  -- Change the cursor position based on special key presses
  if imgui.was_key_pressed(state, "left") then
    state.input_field.cursor_pos = math.max(0, state.input_field.cursor_pos - 1)
    cursor_moved = true
  end
  if imgui.was_key_pressed(state, "right") then
    state.input_field.cursor_pos = math.min(#content, state.input_field.cursor_pos + 1)
    cursor_moved = true
  end
  if imgui.was_key_pressed(state, "home") then
    state.input_field.cursor_pos = 0
    cursor_moved = true
  end
  if imgui.was_key_pressed(state, "end") then
    state.input_field.cursor_pos = #content
    cursor_moved = true
  end

  -- Remove character to the left of the cursor
  if imgui.was_key_pressed(state, "backspace") then
    if state.input_field.cursor_pos > 0 then
      content = string.sub(content, 1 , state.input_field.cursor_pos - 1) ..
                string.sub(content, state.input_field.cursor_pos + 1, -1)
      -- Reduce cursor position by 1
      state.input_field.cursor_pos = math.max(0, state.input_field.cursor_pos - 1)
    end
  end
  -- Remove character to the right of the cursor
  if imgui.was_key_pressed(state, "delete") then
    if state.input_field.cursor_pos < #content then
      content = string.sub(content, 1 , state.input_field.cursor_pos) ..
                string.sub(content, state.input_field.cursor_pos + 2, -1)
      -- The cursor position does not change in this case
    end
  end

  local newtext = state.input.keyboard.text or ""
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
  if cursor_moved then
    state.input_field.cursor_dt = 0
  end
  if state.input_field.cursor_dt < .5 then
    local width = Text.min_width(state, string.sub(
      content, 1, state.input_field.cursor_pos))
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.line(text_x + width, y + 4, text_x + width, y + h - 4)
  end

  -- If the LMB was pressed in the last frame, set the cursor position
  if state.input.mouse.buttons[1] and state.input.mouse.buttons[1].presses > 0 then
    local mx = state.input.mouse.buttons[1].at_x
    local my = state.input.mouse.buttons[1].at_y
    -- Set the cursor position
    local delta = state.transform:unproject(mx, my) - text_x
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
    state.input_field.cursor_pos = math.max(0, math.min(#content, cursor_pos))
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
    love.graphics.setScissor(abs_x, abs_y, abs_w, abs_h)
  end

  -- Highlight if mouse is over button
  if state and state.input and
    imgui.is_mouse_in_rect(state, x, y, w, h)
  then
    -- Change cursor to indicate editable text
    love.mouse.setCursor(i_beam_cursor)
  end

  -- Label position
  local text_x = x + margin_x

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
      content, text_x = handle_input(state, x, y, w, h, content, options, text_x)
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
  return content
end

return Inputfield