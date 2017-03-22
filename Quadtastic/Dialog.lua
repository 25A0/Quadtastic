local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local State = require(current_folder .. ".State")
local InputField = require(current_folder .. ".Inputfield")
local Layout = require(current_folder .. ".Layout")
local Button = require(current_folder .. ".Button")
local Label = require(current_folder .. ".Label")
local Window = require(current_folder .. ".Window")

local Dialog = {}

function Dialog.show_dialog(message, buttons)
  -- Draw the dialog
  local function draw(app, data, gui_state, w, h)
    local x = w/4
    local y = h/4
    w = w/2
    h = h/2
    do Window.start(gui_state, x, y, w, h)
      do Layout.start(gui_state)
        Label.draw(gui_state, nil, nil,
                   gui_state.layout.max_w, nil,
                   data.message)
        Layout.next(gui_state, "|")
        do Layout.start(gui_state)
          for _,button in ipairs(data.buttons) do
            if Button.draw(gui_state, nil, nil, nil, nil, string.upper(button)) then
              app.dialog.respond(button)
            end
            Layout.next(gui_state, "-")
          end
        end Layout.finish(gui_state, "-")
      end Layout.finish(gui_state, "|")
    end Window.finish(gui_state)
  end

  assert(coroutine.running(), "This function must be run in a coroutine.")
  local transitions = {
    -- luacheck: no unused args
    respond = function(app, data, response)
      return response
    end,
  }
  local dialog_state = State("dialog", transitions,
                             {message = message, buttons = buttons or {"OK"}})
  -- Store the draw function in the state
  dialog_state.draw = draw
  return coroutine.yield(dialog_state)
end

function Dialog.query(message, input, buttons)
  -- Draw the dialog
  local function draw(app, data, gui_state, w, h)
    local x = w/4
    local y = h/4
    w = w/2
    h = h/2
    do Window.start(gui_state, x, y, w, h)
      do Layout.start(gui_state)
        Label.draw(gui_state, nil, nil,
                   gui_state.layout.max_w, nil,
                   data.message)
        Layout.next(gui_state, "|")
        data.input = InputField.draw(gui_state, nil, nil,
                                     gui_state.layout.max_w, nil, data.input,
                                     {forced_keyboard_focus = true,
                                      select_all = not data.was_drawn})
        Layout.next(gui_state, "|")
        do Layout.start(gui_state)
          for _,button in ipairs(data.buttons) do
            if Button.draw(gui_state, nil, nil, nil, nil, string.upper(button)) then
              app.query.respond(button)
            end
            Layout.next(gui_state, "-")
          end
        end Layout.finish(gui_state, "-")
      end Layout.finish(gui_state, "|")
    end Window.finish(gui_state)
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
                              buttons = buttons or {"Cancel", "OK"},
                              was_drawn = false,
                             })
  -- Store the draw function in the state
  query_state.draw = draw
  return coroutine.yield(query_state)
end

return Dialog