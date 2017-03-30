local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local State = require(current_folder .. ".State")
local Scrollpane = require(current_folder .. ".Scrollpane")
local Frame = require(current_folder .. ".Frame")
local InputField = require(current_folder .. ".Inputfield")
local Layout = require(current_folder .. ".Layout")
local Button = require(current_folder .. ".Button")
local Label = require(current_folder .. ".Label")
local Text = require(current_folder .. ".Text")
local Window = require(current_folder .. ".Window")
local imgui = require(current_folder .. ".imgui")
local licenses = require(current_folder .. ".res.licenses")

-- Shared library
local lfs = require("lfs")

local Dialog = {}

local function show_buttons(gui_state, buttons, options)
  local clicked_button
  do Layout.start(gui_state)
    for key,button in pairs(buttons) do

      local button_options = {}
      if options and options.disabled[button] then
        button_options.disabled = true
      end

      local button_pressed = Button.draw(gui_state, nil, nil, nil, nil,
        string.upper(button), nil, button_options)
      local key_pressed = type(key) == "string" and
        (imgui.was_key_pressed(gui_state, key) or
         -- Special case since "return" is a reserved keyword
         key == "enter" and imgui.was_key_pressed(gui_state, "return"))
      if button_pressed or key_pressed then
        clicked_button = button
      end
      Layout.next(gui_state, "-")
    end
  end Layout.finish(gui_state, "-")
  return clicked_button
end

local function show_filelist(gui_state, scrollpane_state, filelist, chosen_file)
  local options = {}
  options.font_color = {202, 222, 227}
  options.alignment_v = "-"

  local committed_file
  do Frame.start(gui_state, nil, nil, nil, 150)
    do scrollpane_state = Scrollpane.start(gui_state, nil, nil, nil, nil, scrollpane_state)
      do Layout.start(gui_state, nil, nil, nil, nil, {noscissor = true})
        for _, file in ipairs(filelist) do
          local row_height = 14
          local row_width = gui_state.layout.max_w

          local hovering = imgui.is_mouse_in_rect(gui_state,
            gui_state.layout.next_x, gui_state.layout.next_y,
            row_width, row_height)
          local clicked = imgui.was_mouse_pressed(gui_state,
            gui_state.layout.next_x, gui_state.layout.next_y,
            row_width, row_height)
          local selected = chosen_file and chosen_file.name == file.name

          if selected then
            love.graphics.setColor(32, 63, 73)
          elseif hovering then
            love.graphics.setColor(42, 82, 94)
          end
          if hovering or selected then
            love.graphics.rectangle("fill",
              gui_state.layout.next_x, gui_state.layout.next_y,
              row_width, row_height)
            love.graphics.setColor(255, 255, 255)
          end

          local x = gui_state.layout.next_x + 2
          if file.type == "directory" then
            love.graphics.draw(
              gui_state.style.stylesheet,
              gui_state.style.quads.filebrowser.directory,
              x, gui_state.layout.next_y + 1)
          elseif file.type == "file" then
            love.graphics.draw(
              gui_state.style.stylesheet,
              gui_state.style.quads.filebrowser.file,
              x, gui_state.layout.next_y + 1)
          end
          x = x + 11
          Text.draw(gui_state, x, nil, nil, row_height, file.name, options)
          local text_width = Text.min_width(gui_state, file.name)
          gui_state.layout.adv_x = math.max(row_width, text_width + 11)
          gui_state.layout.adv_y = row_height

          if selected and clicked then
            committed_file = file
          end

          if clicked  then
            chosen_file = file
          end
          Layout.next(gui_state, "|")
        end
      end Layout.finish(gui_state, "|")
      -- Restrict the viewport's position to the visible content as good as
      -- possible
      scrollpane_state.min_x = 0
      scrollpane_state.min_y = 0
      scrollpane_state.max_x = gui_state.layout.adv_x
      scrollpane_state.max_y = math.max(gui_state.layout.adv_y, gui_state.layout.max_h)
    end Scrollpane.finish(gui_state, scrollpane_state)
  end Frame.finish(gui_state)
  return chosen_file, committed_file, scrollpane_state
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
        local clicked_button = show_buttons(gui_state, data.buttons)
        if clicked_button then
          app.dialog.respond(clicked_button)
        end
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
        local committed
        data.input, committed = InputField.draw(gui_state, nil, nil,
                                     w/2, nil, data.input,
                                     {forced_keyboard_focus = true,
                                      select_all = not data.was_drawn})
        Layout.next(gui_state, "|")
        local clicked_button = show_buttons(gui_state, data.buttons)
        if clicked_button then
          app.query.respond(clicked_button)
        end
        Layout.next(gui_state, "|")
        if committed then
          app.query.respond("OK")
        end
      end Layout.finish(gui_state, "|")
      Layout.next(gui_state, "|")
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

local function switch_to(data, new_basepath)
  local function create_filelist()
    local filelist = {}
    for file in lfs.dir(".") do
      local mode = lfs.attributes(file, "mode")
      table.insert(filelist, {name=file, type=mode})
    end
    return filelist
  end

  -- Clear chosen file
  data.chosen_file = nil

  local success, err = lfs.chdir(new_basepath)
  if success then
    data.basepath = lfs.currentdir()
    data.filelist = create_filelist()
    data.editing_basepath = data.basepath
    return true
  else
    return false, err
  end
end

function Dialog.open_file(basepath)
  -- Draw the dialog
  local function draw(app, data, gui_state, w, h)
    local min_w = data.min_w or 0
    local min_h = data.min_h or 0
    local x = data.win_x or (w - min_w) / 2
    local y = data.win_y or (h - min_h) / 2
    local dx, dy

    if not data.basepath then
      data.basepath = "/"
    end

    if not data.filelist then
      local success
      -- The given basepath might be a file. In that case set the basepath to
      -- the containing directory, and set the rest as the chosen file
      local mode, err = lfs.attributes(data.basepath, "mode")
      if mode then
        if mode == "file" then
          local prev_basepath, filename = string.gmatch(data.basepath, "(.*/)([^/]*)")()
          success, err = switch_to(data, prev_basepath)
          if success then
            data.chosen_file = {
              type = "file",
              name = filename
            }
          end
        elseif mode == "directory" then
          success, err = switch_to(data, data.basepath)
        end
      end

      -- If switching to the basepath doesn't work the first time the file
      -- dialog is drawn, switch to the file root
      if not success then
        app.open_file.err(err)
        switch_to(data, "/")
      end
    end

    assert(data.filelist)
    local new_basepath

    local intended_width = 180
    do Window.start(gui_state, x, y, min_w, min_h)
      imgui.push_style(gui_state, "font", gui_state.style.small_font)
      data.editing_basepath, new_basepath = InputField.draw(gui_state,
        nil, nil, intended_width, nil, data.editing_basepath or data.basepath)
      Layout.next(gui_state, "|")

      data.chosen_file, data.committed_file, data.scrollpane_state = show_filelist(
        gui_state, data.scrollpane_state, data.filelist, data.chosen_file)

      if data.committed_file then
        if data.committed_file.type == "directory" then
          new_basepath = data.basepath .. "/" .. data.committed_file.name
        elseif data.committed_file.type == "file" then
          app.open_file.respond("Open")
        end
      end

      imgui.pop_style(gui_state, "font")
      Layout.next(gui_state, "|")
      local clicked_button = show_buttons(gui_state, data.buttons,
        {disabled = {Open = data.chosen_file == nil or data.chosen_file.type == "directory"}})
      if clicked_button then

        -- Set chosen file as committed when open is clicked
        if clicked_button == "Open" then
          if data.chosen_file and data.chosen_file.type == "file" then
            data.committed_file = data.chosen_file
          end
        end

        app.open_file.respond(clicked_button)
      end
      Layout.next(gui_state, "|")
    end data.min_w, data.min_h, dx, dy, data.dragging = Window.finish(
      gui_state, x, y, data.dragging)
    if dx then data.win_x = (data.win_x or x) + dx end
    if dy then data.win_y = (data.win_y or y) + dy end

    if new_basepath then
      local success, err = switch_to(data, new_basepath)
      if not success then
        app.open_file.err(err)
      end
    end
  end

  assert(coroutine.running(), "This function must be run in a coroutine.")
  local transitions = {
    -- luacheck: no unused args
    respond = function(app, data, response)
      return response, (data.basepath or "") .. "/" .. (
        data.committed_file and data.committed_file.name or ""
      )
    end,

    err = function(app, data, err)
      Dialog.show_dialog(err)
    end,
  }

  local file_state = State("open_file", transitions,
                             {basepath = basepath or "/",
                              buttons = {escape = "Cancel", enter = "Open"},
                             })

  -- Store the draw function in the state
  file_state.draw = draw
  return coroutine.yield(file_state)
end

function Dialog.save_file(basepath)
  -- Draw the dialog
  local function draw(app, data, gui_state, w, h)
    local min_w = data.min_w or 0
    local min_h = data.min_h or 0
    local x = data.win_x or (w - min_w) / 2
    local y = data.win_y or (h - min_h) / 2
    local dx, dy

    if not data.basepath then
      data.basepath = "/"
    end

    if not data.filelist then
      local success

      -- The given basepath might be a file. In that case set the basepath to
      -- the containing directory, and set the rest as the chosen file
      local mode, err = lfs.attributes(data.basepath, "mode")
      if mode then
        if mode == "file" then
          local prev_basepath, filename = string.gmatch(
            data.basepath, "(.*/)([^/]*)"
          )()
          success, err = switch_to(data, prev_basepath)
          if success then
            data.chosen_file = {
              type = "file",
              name = filename
            }
          end
        elseif mode == "directory" then
          success, err = switch_to(data, data.basepath)
        end
      end

      -- If switching to the basepath doesn't work the first time the file
      -- dialog is drawn, switch to the file root
      if not success or err then
        app.save_file.err(err)
        switch_to(data, "/")
      end
    end

    assert(data.filelist)
    local new_basepath

    local intended_width = 180
    do Window.start(gui_state, x, y, min_w, min_h)
      imgui.push_style(gui_state, "font", gui_state.style.small_font)
      data.editing_basepath, new_basepath = InputField.draw(gui_state,
        nil, nil, intended_width, nil, data.editing_basepath or data.basepath)
      Layout.next(gui_state, "|")

      local last_chosen_file = data.chosen_file
      data.chosen_file, data.committed_file, data.scrollpane_state = show_filelist(
        gui_state, data.scrollpane_state, data.filelist, data.chosen_file)

      -- Clear editing filename whenever chosen file changes
      if last_chosen_file ~= data.chosen_file and data.chosen_file.type == "file" then
        data.editing_filename = nil
      end

      Layout.next(gui_state, "|")
      data.editing_filename, data.committed_filename =
        InputField.draw(gui_state,
                        nil, nil, intended_width, nil, data.editing_filename or
                        data.chosen_file and data.chosen_file.type == "file" and
                        data.chosen_file.name or "")

      if data.committed_filename then
        local filetype = lfs.attributes(data.committed_filename, "mode")
        filetype = filetype or "new" -- Assume that this file doesn't exist if
                                     -- we can't query its mode
        data.committed_file = {type=filetype, name=data.committed_filename}
      end

      if data.committed_file then
        local combined_path = data.basepath .. "/" .. data.committed_file.name
        if data.committed_file.type == "directory" then
          new_basepath = combined_path
        elseif data.committed_file.type == "new" then
          app.save_file.save(combined_path)
        elseif data.committed_file.type == "file" then
          app.save_file.override(combined_path)
        end
      end

      imgui.pop_style(gui_state, "font")
      Layout.next(gui_state, "|")

      local clicked_button = show_buttons(gui_state, data.buttons,
        {disabled = {Open = data.chosen_file == nil or
                     data.editing_filename == ""}})
      if clicked_button then

        if clicked_button == "Save" then
          local filename = data.committed_file and data.committed_file.name or
                           data.editing_filename
          if filename then
            local filetype = lfs.attributes(filename, "mode")
            local filepath = (data.basepath or "") .. "/" .. (filename or "")
            if filetype == "file" then
              app.save_file.override(filepath)
            elseif filetype == "directory" then
              app.save_file.err(string.format("%s is a directory.", filepath))
            else -- it's a new file
              app.save_file.save(filepath)
            end
          end
        else
          app.save_file.cancel()
        end

      end
      Layout.next(gui_state, "|")
    end data.min_w, data.min_h, dx, dy, data.dragging = Window.finish(
      gui_state, x, y, data.dragging)
    if dx then data.win_x = (data.win_x or x) + dx end
    if dy then data.win_y = (data.win_y or y) + dy end

    if new_basepath then
      local success, err = switch_to(data, new_basepath)
      if not success then
        app.save_file.err(err)
      end
    end
  end

  assert(coroutine.running(), "This function must be run in a coroutine.")
  local transitions = {
    -- luacheck: no unused args
    save = function(app, data, filepath)
      return "Save", filepath
    end,

    override = function(app, data, filepath)
      local ret = Dialog.show_dialog(
        string.format("File %s already exists. Do you want to replace it?",
                      filepath),
        {"Yes", "No"})
      if ret == "Yes" then
        return "Save", filepath
      end
    end,

    cancel = function(app, data)
      return "Cancel"
    end,

    err = function(app, data, err)
      Dialog.show_dialog(err)
    end,
  }

  local file_state = State("save_file", transitions,
                             {basepath = basepath or "/",
                              buttons = {escape = "Cancel", enter = "Save"},
                             })

  -- Store the draw function in the state
  file_state.draw = draw
  return coroutine.yield(file_state)
end

function Dialog.show_about_dialog()
  local version_info = love.filesystem.read("res/version.txt")
  local copyright_info = love.filesystem.read("res/copyright.txt")

  -- Draw the dialog
  local function draw(app, data, gui_state, w, h)
    local min_w = data.min_w or 0
    local min_h = data.min_h or 0
    local x = data.win_x or (w - min_w) / 2
    local y = data.win_y or (h - min_h) / 2
    local dx, dy
    do Window.start(gui_state, x, y, min_w, min_h)
      do Layout.start(gui_state)

        local icon_w, icon_h = 32, 32
        local x = gui_state.layout.next_x + (gui_state.layout.max_w - icon_w) / 2
        local y = gui_state.layout.next_y
        love.graphics.draw(gui_state.style.icon, x, y)
        gui_state.layout.adv_x, gui_state.layout.adv_y = icon_w, icon_h
        Layout.next(gui_state, "|")

        Label.draw(gui_state, nil, nil, nil, nil, "Quadtastic " .. version_info)
        Layout.next(gui_state, "|")
        Label.draw(gui_state, nil, nil, nil, nil, copyright_info)
        Layout.next(gui_state, "|")
        if Button.draw(gui_state, nil, nil, nil, nil, "Close") then
          app.about_dialog.close()
        end
      end Layout.finish(gui_state, "|")
    end data.min_w, data.min_h, dx, dy, data.dragging = Window.finish(
      gui_state, x, y, data.dragging)
    if dx then data.win_x = (data.win_x or x) + dx end
    if dy then data.win_y = (data.win_y or y) + dy end
  end

  assert(coroutine.running(), "This function must be run in a coroutine.")
  local transitions = {
    -- luacheck: no unused args
    close = function(app, data) return "close" end,
  }
  local dialog_state = State("about_dialog", transitions, {})
  -- Store the draw function in the state
  dialog_state.draw = draw
  return coroutine.yield(dialog_state)
end

function Dialog.show_ack_dialog()
  -- Draw the dialog
  local function draw(app, data, gui_state, w, h)
    local min_w = data.min_w or 0
    local min_h = data.min_h or 0
    local x = data.win_x or (w - min_w) / 2
    local y = data.win_y or (h - min_h) / 2
    local dx, dy
    do Window.start(gui_state, x, y, min_w, min_h)
      imgui.push_style(gui_state, "font", gui_state.style.small_font)
      do Layout.start(gui_state)
        Label.draw(gui_state, nil, nil, nil, nil, "Quadtastic uses the following open-source software projects:")
        Layout.next(gui_state, "|")

        do Frame.start(gui_state, nil, nil, 320, 150)
          imgui.push_style(gui_state, "font_color", {202, 222, 227})
          do scrollpane_state = Scrollpane.start(gui_state, nil, nil, nil, nil, scrollpane_state)
            do Layout.start(gui_state, nil, nil, nil, nil, {noscissor = true})
            for i, software in ipairs(licenses) do
              imgui.push_style(gui_state, "font", gui_state.style.med_font)
              Label.draw(gui_state, nil, nil, nil, nil, software.name)
              imgui.pop_style(gui_state, "font")
              Layout.next(gui_state, "|")
              Label.draw(gui_state, nil, nil, nil, nil, software.license)
              Layout.next(gui_state, "|")
              if next(licenses, i) then
                Label.draw(gui_state, nil, nil, nil, nil, "--------------------")
                Layout.next(gui_state, "|")
              end
            end

            end Layout.finish(gui_state, "|")
            -- Restrict the viewport's position to the visible content as good as
            -- possible
            scrollpane_state.min_x = 0
            scrollpane_state.min_y = 0
            scrollpane_state.max_x = gui_state.layout.adv_x
            scrollpane_state.max_y = math.max(gui_state.layout.adv_y, gui_state.layout.max_h)
          end Scrollpane.finish(gui_state, scrollpane_state)
          imgui.pop_style(gui_state, "font_color")
        end Frame.finish(gui_state)
        Layout.next(gui_state, "|")

        if Button.draw(gui_state, nil, nil, nil, nil, "Close") then
          app.ack_dialog.close()
        end
      end Layout.finish(gui_state, "|")
      imgui.pop_style(gui_state, "font")
    end data.min_w, data.min_h, dx, dy, data.dragging = Window.finish(
      gui_state, x, y, data.dragging)
    if dx then data.win_x = (data.win_x or x) + dx end
    if dy then data.win_y = (data.win_y or y) + dy end
  end

  assert(coroutine.running(), "This function must be run in a coroutine.")
  local transitions = {
    -- luacheck: no unused args
    close = function(app, data) return "close" end,
  }
  local dialog_state = State("ack_dialog", transitions, {})
  -- Store the draw function in the state
  dialog_state.draw = draw
  return coroutine.yield(dialog_state)
end

return Dialog