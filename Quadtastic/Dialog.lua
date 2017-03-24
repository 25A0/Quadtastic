local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local State = require(current_folder .. ".State")
local InputField = require(current_folder .. ".Inputfield")
local Layout = require(current_folder .. ".Layout")
local Button = require(current_folder .. ".Button")
local Label = require(current_folder .. ".Label")
local Window = require(current_folder .. ".Window")
local imgui = require(current_folder .. ".imgui")

local Dialog = {}

local function show_buttons(state, gui_state, buttons)
  do Layout.start(gui_state)
    for key,button in pairs(buttons) do
      local button_pressed = Button.draw(gui_state, nil, nil, nil, nil, string.upper(button))
      local key_pressed = type(key) == "string" and
        (imgui.was_key_pressed(gui_state, key) or
         -- Special case since "return" is a reserved keyword
         key == "enter" and imgui.was_key_pressed(gui_state, "return"))
      if button_pressed or key_pressed then
        state.respond(button)
      end
      Layout.next(gui_state, "-")
    end
  end Layout.finish(gui_state, "-")

end

function Dialog.show_dialog(message, buttons)
  -- Draw the dialog
  local function draw(app, data, gui_state, w, h)
    local min_w = data.min_w or 0
    local min_h = data.min_h or 0
    local x = data.win_x or (w - min_w) / 2
    local y = data.win_y or (h - min_h) / 2
    local dx, dy
    do Window.start(gui_state, x, y, min_w, min_h)
      do Layout.start(gui_state)
        imgui.push_style(gui_state, "font", gui_state.style.small_font)
        Label.draw(gui_state, nil, nil,
                   w/2, nil,
                   data.message)
        Layout.next(gui_state, "|")
        imgui.pop_style(gui_state, "font")
        show_buttons(app.dialog, gui_state, data.buttons)
        Layout.next(gui_state, "|")
      end Layout.finish(gui_state, "|")
    end data.min_w, data.min_h, dx, dy, data.dragging = Window.finish(
      gui_state, x, y, data.dragging)
    if dx then data.win_x = (data.win_x or x) + dx end
    if dy then data.win_y = (data.win_y or y) + dy end
  end

  assert(coroutine.running(), "This function must be run in a coroutine.")
  local transitions = {
    -- luacheck: no unused args
    respond = function(app, data, response)
      return response
    end,
  }
  local dialog_state = State("dialog", transitions,
                             {message = message, buttons = buttons or {enter = "OK"}})
  -- Store the draw function in the state
  dialog_state.draw = draw
  return coroutine.yield(dialog_state)
end

function Dialog.query(message, input, buttons)
  -- Draw the dialog
  local function draw(app, data, gui_state, w, h)
    local min_w = data.min_w or 0
    local min_h = data.min_h or 0
    local x = data.win_x or (w - min_w) / 2
    local y = data.win_y or (h - min_h) / 2
    local dx, dy
    do Window.start(gui_state, x, y, min_w, min_h)
      do Layout.start(gui_state)
        imgui.push_style(gui_state, "font", gui_state.style.small_font)
        Label.draw(gui_state, nil, nil,
                   w/2, nil,
                   data.message)
        Layout.next(gui_state, "|")
        imgui.pop_style(gui_state, "font")
        data.input = InputField.draw(gui_state, nil, nil,
                                     w/2, nil, data.input,
                                     {forced_keyboard_focus = true,
                                      select_all = not data.was_drawn})
        Layout.next(gui_state, "|")
        show_buttons(app.query, gui_state, data.buttons)
        Layout.next(gui_state, "|")
      end Layout.finish(gui_state, "|")
    end data.min_w, data.min_h, dx, dy, data.dragging = Window.finish(
      gui_state, x, y, data.dragging)
    if dx then data.win_x = (data.win_x or x) + dx end
    if dy then data.win_y = (data.win_y or y) + dy end
    data.was_drawn = true
  end

  assert(coroutine.running(), "This function must be run in a coroutine.")
  local transitions = {
    -- luacheck: no unused args
    respond = function(app, data, response)
      return response, data.input
    end,
  }
  local query_state = State("query", transitions,
                             {input = input or "", message = message,
                              buttons = buttons or {escape = "Cancel", enter = "OK"},
                              was_drawn = false,
                             })
  -- Store the draw function in the state
  query_state.draw = draw
  return coroutine.yield(query_state)
end

return Dialog