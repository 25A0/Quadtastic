local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local State = require(current_folder .. ".State")

local imgui = require(current_folder .. ".imgui")
local Button = require(current_folder .. ".Button")
local Label = require(current_folder .. ".Label")
local Frame = require(current_folder .. ".Frame")
local Layout = require(current_folder .. ".Layout")
local Window = require(current_folder .. ".Window")
local Scrollpane = require(current_folder .. ".Scrollpane")
local Tooltip = require(current_folder .. ".Tooltip")
local ImageEditor = require(current_folder .. ".ImageEditor")
local QuadList = require(current_folder .. ".QuadList")
local libquadtastic = require(current_folder .. ".libquadtastic")
local Checkbox = require(current_folder .. ".Checkbox")
local table = require(current_folder .. ".tableplus")
local common = require(current_folder .. ".common")
local Selection = require(current_folder .. ".Selection")
local QuadtasticLogic = require(current_folder .. ".QuadtasticLogic")
local Dialog = require(current_folder .. ".Dialog")
local Menu = require(current_folder .. ".Menu")
local Keybindings = require(current_folder .. ".Keybindings")
local S = require(current_folder .. ".strings")

local lfs = require("lfs")

local settings_filename = "settings"

local function load_settings()
  local success, more = pcall(function()
    return require(settings_filename)
  end)

  if success then
    return more
  else
    print("Warning: Could not load settings. " .. more)
    return nil
  end
end

local function store_settings(settings)
  local success, more = pcall(function()
    local content = common.serialize_table(settings)
    love.filesystem.write(settings_filename .. ".lua", content)
  end)

  if not success then
    print("Warning: Could not store settings. " .. more)
  end
  return success, more
end

local Quadtastic = State("quadtastic",
  nil,
  -- initial data
  {
    display = {
      zoom = 1, -- additional zoom factor for the displayed image
    },
    scrollpane_state = nil,
    quad_scrollpane_state = nil,
    settings = load_settings() or {recent = {}},
    collapsed_groups = {},
    selection = Selection(),
    -- More fields are initialized in the new() transition.
  })

function Quadtastic.reset_view(state)
  state.scrollpane_state = Scrollpane.init_scrollpane_state()
  state.display.zoom = 1
  if state.image then
    Scrollpane.set_focus(state.scrollpane_state, {
      x = 0, y = 0,
      w = state.image:getWidth(), h = state.image:getHeight()
    }, "immediate")
  end
end

-- -------------------------------------------------------------------------- --
--                           TRANSITIONS
-- -------------------------------------------------------------------------- --
-- Transitions are initialized now since they need to call some of the functions
-- defined above.

local interface = {
  reset_view = Quadtastic.reset_view,
  move_quad_into_view = QuadList.move_quad_into_view,
  store_settings = store_settings,
  show_dialog = Dialog.show_dialog,
  query = Dialog.query,
  open_file = Dialog.open_file,
  save_file = Dialog.save_file,
  show_about_dialog = Dialog.show_about_dialog,
  show_ack_dialog = Dialog.show_ack_dialog,
  check_updates = Dialog.check_updates,
}

Quadtastic.transitions = QuadtasticLogic.transitions(interface)

-- -------------------------------------------------------------------------- --
--                           DRAWING
-- -------------------------------------------------------------------------- --
Quadtastic.draw = function(app, state, gui_state)
  local save_toast_callback = function(path)
    imgui.show_toast(gui_state, S.toast.saved_as(path), nil, 2)
  end

  local reload_image_toast_callback = function(path)
    imgui.show_toast(gui_state, S.toast.reloaded(path), nil, 2)
  end

  local w, h = gui_state.transform:unproject_dimensions(
    love.graphics.getWidth(), love.graphics.getHeight()
  )
  love.graphics.clear(gui_state.style.palette.shades.bright)
  local win_x, win_y = 0, 0
  do Window.start(gui_state, win_x, win_y, w, h, {margin = 2, active = true, borderless = true})
    local was_menu_open = imgui.is_any_menu_open(gui_state)

    do Menu.menubar_start(gui_state, w, 12)
      if Menu.menu_start(gui_state, w/4, h - 12, S.menu.file()) then
        if Menu.action_item(gui_state, S.menu.file.new,
           {keybinding = Keybindings.to_string("new")})
        then
          app.quadtastic.new()
        end
        if Menu.action_item(gui_state, S.menu.file.open,
           {keybinding = Keybindings.to_string("open")})
        then
          app.quadtastic.choose_quad()
        end
        if Menu.action_item(gui_state, S.menu.file.save,
           {keybinding = Keybindings.to_string("save")})
        then
          app.quadtastic.save(save_toast_callback)
        end
        if Menu.action_item(gui_state, S.menu.file.save_as,
           {keybinding = Keybindings.to_string("save_as")}) then
          app.quadtastic.save_as(save_toast_callback)
        end
        if #state.settings.recent > 0 then
          if Menu.menu_start(gui_state, w/4, h - 12,
                             S.menu.file.open_recent)
          then
            for _, file in ipairs(state.settings.recent) do
              local _, filename = common.split(file)
              if Menu.action_item(gui_state, filename) then app.quadtastic.load_quad(file) end
            end
            Menu.menu_finish(gui_state, w/4, h - 12)
          end
        end
        Menu.separator(gui_state)
        if Menu.action_item(gui_state, S.menu.file.quit,
           {keybinding = Keybindings.to_string("quit")})
        then
          love.event.quit()
        end
        Menu.menu_finish(gui_state, w/4, h - 12)
      end
      if Menu.menu_start(gui_state, w/4, h - 12, S.menu.edit()) then
        if Menu.action_item(gui_state, S.menu.edit.undo,
                            {disabled = not state.history:can_undo(),
                             keybinding = Keybindings.to_string("undo")})
        then
          app.quadtastic.undo()
        end
        if Menu.action_item(gui_state, S.menu.edit.redo,
                            {disabled = not state.history:can_redo(),
                             keybinding = Keybindings.to_string("redo")})
        then
          app.quadtastic.redo()
        end
        Menu.menu_finish(gui_state, w/4, h - 12)
      end
      if Menu.menu_start(gui_state, w/4, h - 12, S.menu.image()) then
        if Menu.action_item(gui_state, S.menu.image.open_image) then
          app.quadtastic.choose_image()
        end
        local loaded = state.file_timestamps.image_loaded
        local latest = state.file_timestamps.image_latest
        local can_reload = loaded and latest and loaded ~= latest
        local disabled = not can_reload or not state.quads._META.image_path
        if Menu.action_item(gui_state, S.menu.image.reload_image,
                            {disabled = disabled})
        then
          app.quadtastic.load_image(state.quads._META.image_path)
        end
        Menu.menu_finish(gui_state, w/4, h - 12)
      end
      if Menu.menu_start(gui_state, w/4, h - 12, S.menu.help()) then

        if Menu.action_item(gui_state, S.menu.help.documentation) then
          love.system.openURL(S.documentation_url)
        end
        if Menu.action_item(gui_state, S.menu.help.source_code) then
          love.system.openURL(S.source_code_url)
        end
        if Menu.menu_start(gui_state, w/4, h-12, S.menu.help.libquadtastic()) then
          if Menu.action_item(gui_state, S.menu.help.libquadtastic.copy) then
            local content = love.filesystem.read("libquadtastic.lua")
            love.system.setClipboardText(content)
            imgui.show_toast(gui_state, S.toast.copied_to_clipboard, nil, 2)
          end
          Menu.menu_finish(gui_state, w/4, h-12)
        end
        if Menu.menu_start(gui_state, w/4, h - 12, S.menu.help.report()) then

          if Menu.action_item(gui_state, S.menu.help.report.github) then
            local version_info = common.get_version()
            local body = S.menu.help.report.issue_body(version_info)
            love.system.openURL("https://www.github.com/25A0/Quadtastic/issues/new?body="..body)
          end
          if Menu.action_item(gui_state, S.menu.help.report.email) then
            local version_info = common.get_version()
            local subject = S.menu.help.report.email_subject(version_info)
            local body = S.menu.help.report.issue_body(version_info)
            love.system.openURL("mailto:moritz@25a0.com?subject="..subject..
                                "&body="..body)
          end
          Menu.menu_finish(gui_state, w/4, h-12)
        end
        Menu.separator(gui_state)
        if Menu.action_item(gui_state, S.menu.help.check_updates) then
          app.quadtastic.check_updates()
        end
        if Menu.action_item(gui_state, S.menu.help.acknowledgements) then
          app.quadtastic.show_ack_dialog()
        end
        if Menu.action_item(gui_state, S.menu.help.about) then
          app.quadtastic.show_about_dialog()
        end
        Menu.menu_finish(gui_state, w/4, h - 12)
      end
    end Menu.menubar_finish(gui_state)

    if was_menu_open then
      imgui.cover_input(gui_state)
    end

    Layout.next(gui_state, "|")

    do Layout.start(gui_state) -- Image editor
      -- Toolbar
      do Layout.start(gui_state)
        if Button.draw(gui_state, nil, nil, nil, nil, nil,
                       gui_state.style.quads.tools.select,
                       {pressed = state.tool == "select"})
        then
          app.quadtastic.switch_tool("select")
        end
        Tooltip.draw(gui_state, S.tooltips.select_tool)
        Layout.next(gui_state, "|")

        if Button.draw(gui_state, nil, nil, nil, nil, nil,
                       gui_state.style.quads.tools.create,
                       {pressed = state.tool == "create"})
        then
          app.quadtastic.switch_tool("create")
        end
        Tooltip.draw(gui_state, S.tooltips.create_tool)
        Layout.next(gui_state, "|")

        if Button.draw(gui_state, nil, nil, nil, nil, nil,
                       gui_state.style.quads.tools.border,
                       {pressed = state.tool == "border"})
        then
          app.quadtastic.switch_tool("border")
          imgui.show_toast(gui_state, "NYI", nil, 2)
        end
        Tooltip.draw(gui_state, S.tooltips.border_tool)
        Layout.next(gui_state, "|")

        if Button.draw(gui_state, nil, nil, nil, nil, nil,
                       gui_state.style.quads.tools.strip,
                       {pressed = state.tool == "strip"})
        then
          app.quadtastic.switch_tool("strip")
          imgui.show_toast(gui_state, "NYI", nil, 2)
        end
        Tooltip.draw(gui_state, S.tooltips.strip_tool)
        Layout.next(gui_state, "|")

        if Button.draw(gui_state, nil, nil, nil, nil, nil,
                       gui_state.style.quads.tools.wand,
                       {pressed = state.tool == "wand"})
        then
          app.quadtastic.switch_tool("wand")
        end
        Tooltip.draw(gui_state, S.tooltips.wand_tool)
        Layout.next(gui_state, "|")

        if Button.draw(gui_state, nil, nil, nil, nil, nil,
                       gui_state.style.quads.tools.palette,
                       {pressed = state.tool == "palette"})
        then
          app.quadtastic.switch_tool("palette")
        end
        Tooltip.draw(gui_state, S.tooltips.palette_tool)
        Layout.next(gui_state, "|")

      end Layout.finish(gui_state, "|")

      Layout.next(gui_state, "-")

      do Layout.start(gui_state, nil, nil, gui_state.layout.max_w - 160, nil)
        do Frame.start(gui_state, nil, nil, nil, gui_state.layout.max_h - 13)
          if state.image then
            ImageEditor.draw(app, gui_state, state)
          else
            -- Put a label in the center of the frame
            imgui.push_style(gui_state, "font", gui_state.style.small_font)
            Label.draw(gui_state, nil, nil,
              gui_state.layout.max_w, gui_state.layout.max_h,
              S.image_editor_no_image,
              {alignment_h = ":", alignment_v = "-"})
            imgui.pop_style(gui_state, "font")
          end
        end Frame.finish(gui_state)

        Layout.next(gui_state, "|", 1)

        do Layout.start(gui_state) -- Zoom buttons
          do
            local pressed = Button.draw(gui_state, nil, nil, nil, nil, nil,
              gui_state.style.quads.buttons.plus)
            if pressed then
              ImageEditor.zoom(state, 1)
            end
            Tooltip.draw(gui_state, S.tooltips.zoom_in)
          end
          Layout.next(gui_state, "-")
          do
            local pressed = Button.draw(gui_state, nil, nil, nil, nil, nil,
              gui_state.style.quads.buttons.minus)
            if pressed then
              ImageEditor.zoom(state, -1)
            end
            Tooltip.draw(gui_state, S.tooltips.zoom_out)
          end
          Layout.next(gui_state, "-")

          -- Status bar
          imgui.push_style(gui_state, "font", gui_state.style.small_font)

          love.graphics.setColor(255, 255, 255, 255)
          Label.draw(gui_state, nil, -3, nil, nil, string.format("%d%%", state.display.zoom * 100))
          Layout.next(gui_state, "-")

          if gui_state.input and Scrollpane.is_mouse_inside_widget(gui_state,
             state.scrollpane_state)
          then
            local margin_y = (16 - gui_state.style.raw_quads.crosshair.h) / 2
            love.graphics.draw(gui_state.style.stylesheet,
                               gui_state.style.quads.crosshair,
                               gui_state.layout.next_x,
                               gui_state.layout.next_y - 2 + margin_y)
            gui_state.layout.adv_x = gui_state.style.raw_quads.crosshair.w
            gui_state.layout.adv_y = 16
            Layout.next(gui_state, "-")
            local mx, my = gui_state.input.mouse.x, gui_state.input.mouse.y
            mx, my = state.scrollpane_state.transform:unproject(mx, my)
            mx = mx + state.scrollpane_state.x
            my = my + state.scrollpane_state.y
            mx, my = mx / state.display.zoom, my / state.display.zoom
            Label.draw(gui_state, nil, -3, nil, nil, string.format("%d %d", mx, my))
            Layout.next(gui_state, "-")
          end

          if os.getenv("DEBUG") then
            Label.draw(gui_state, nil, -3, nil, nil, string.format("%d FPS", gui_state.fps or gui_state.frames or 0))
            Layout.next(gui_state, "-")
          end
          imgui.pop_style(gui_state, "font")

        end Layout.finish(gui_state, "-") -- Zoom buttons

      end Layout.finish(gui_state, "|")

      Layout.next(gui_state, "-")

      -- Quad list and buttons
      do Layout.start(gui_state)
        -- Quad list
        do Layout.start(gui_state)
          do Layout.start(gui_state, nil, nil, gui_state.layout.max_w - 21)
            -- Draw the list of quads
            local clicked, hovered =
              QuadList.draw(gui_state, state, nil, nil, nil, gui_state.layout.max_h - 33,
                            state.hovered)
            if clicked then
              local new_quads = {clicked}
              -- If shift was pressed, select all quads between the clicked one and
              -- the last quad that was clicked
              if gui_state.input and
                (imgui.is_key_pressed(gui_state, "lshift") or
                 imgui.is_key_pressed(gui_state, "rshift")) and
                state.previous_clicked
              then
                -- Make sure that the new quad and the last quads are child of the
                -- same parent
                local previous_keys = {table.find_key(state.quads, state.previous_clicked)}
                local new_keys = {table.find_key(state.quads, clicked)}
                -- Remove the last keys since they will likely differ
                local previous_key = table.remove(previous_keys)
                local new_key = table.remove(new_keys)
                if table.shallow_equals(previous_keys, new_keys) then
                  if previous_key == new_key then
                    assert(state.previous_clicked == clicked)
                    -- In this case the user clicked the same quad twice after
                    -- pressing shift. We don't need to take any extra steps.
                  else
                    -- We don't know the exact order in which quads appear. So we
                    -- iterate through the quads of the shared parent. Once we
                    -- encounter either the new or the previous quad, we start
                    -- adding all intermediate quads to a list that will then be
                    -- selected.
                    local parent = table.get(state.quads, unpack(new_keys))
                    local found_previous = false
                    local found_new = false
                    -- Clear the list of new quads to make the accumulation process
                    -- a bit easier
                    new_quads = {}
                    for k,v in pairs(parent) do
                      if v == clicked then
                        found_new = true
                      end
                      if v == state.previous_clicked then
                        found_previous = true
                      end
                      if found_new or found_previous and k ~= "_META" then
                        table.insert(new_quads, v)
                      end
                      if found_new and found_previous then break end
                    end
                  end
                end
              else
                state.previous_clicked = clicked
              end

              if gui_state.input and
                (imgui.is_key_pressed(gui_state, "lctrl") or
                 imgui.is_key_pressed(gui_state, "rctrl"))
              then
                if #new_quads == 1 and state.selection:is_selected(clicked) then
                  state.selection:deselect(new_quads)
                else
                  state.selection:select(new_quads)
                end
              else
                state.selection:set_selection(new_quads)
              end
            end

            -- Move viewport so that clicked quad is visible
            if clicked and libquadtastic.is_quad(clicked) then
              local bounds = {}
              -- We need to transform the position and dimension of the clicked
              -- quad, since the scrollpane doesn't handle the zoom.
              bounds.x = clicked.x * state.display.zoom
              bounds.y = clicked.y * state.display.zoom
              bounds.w = clicked.w * state.display.zoom
              bounds.h = clicked.h * state.display.zoom

              -- Move the image editor's viewport to the focused quad
              Scrollpane.set_focus(state.scrollpane_state, bounds)
            end

            state.hovered = hovered

            Layout.next(gui_state, "|")

            if Button.draw(gui_state, nil, nil, gui_state.layout.max_w, nil,
                           S.buttons.export, nil, {alignment_h = ":"})
            then
              app.quadtastic.save(save_toast_callback)
            end

            Layout.next(gui_state, "|", 2)

            do Layout.start(gui_state)
              state.turbo_workflow = Checkbox.draw(gui_state, nil, nil, nil, 12, state.turbo_workflow)

              Layout.next(gui_state, "-")

              if state.turbo_workflow then
                local anim_set = gui_state.style.turboworkflow_activated
                local frame = 1 + math.fmod(gui_state.second / anim_set.duration, #anim_set.frames)
                frame = math.modf(frame)
                love.graphics.draw(anim_set.sheet, anim_set.frames[frame],
                                   gui_state.layout.next_x, gui_state.layout.next_y - 2)
              else
                love.graphics.draw(gui_state.style.turboworkflow_deactivated,
                                   gui_state.layout.next_x, gui_state.layout.next_y - 2)
              end
              Tooltip.draw(gui_state, S.tooltips.turbo_workflow,
                           nil, nil, 128, 12)
              -- imgui.push_style(gui_state, "font", gui_state.style.small_font)
              -- Label.draw(gui_state, nil, nil, nil, 12, "Turbo-Workflow")
              -- imgui.pop_style(gui_state, "font")
            end Layout.finish(gui_state, "-")

          end Layout.finish(gui_state, "|")
          Layout.next(gui_state, "-")

          -- Draw button column
          do Layout.start(gui_state)
            if Button.draw(gui_state, nil, nil, nil, nil, nil,
                           gui_state.style.quads.buttons.rename)
            then
              app.quadtastic.rename(state.selection:get_selection())
            end
            Tooltip.draw(gui_state, S.tooltips.rename)
            Layout.next(gui_state, "|")
            if Button.draw(gui_state, nil, nil, nil, nil, nil,
                           gui_state.style.quads.buttons.delete)
            then
              app.quadtastic.remove(state.selection:get_selection())
            end
            Tooltip.draw(gui_state, S.tooltips.delete)
            Layout.next(gui_state, "|")
            if Button.draw(gui_state, nil, nil, nil, nil, nil,
                           gui_state.style.quads.buttons.sort)
            then
              app.quadtastic.sort(state.selection:get_selection())
            end
            Tooltip.draw(gui_state, S.tooltips.sort)
            Layout.next(gui_state, "|")
            if Button.draw(gui_state, nil, nil, nil, nil, nil,
                           gui_state.style.quads.buttons.group)
            then
              app.quadtastic.group(state.selection:get_selection())
            end
            Tooltip.draw(gui_state, S.tooltips.group)
            Layout.next(gui_state, "|")
            if Button.draw(gui_state, nil, nil, nil, nil, nil,
                           gui_state.style.quads.buttons.ungroup)
            then
              app.quadtastic.ungroup(state.selection:get_selection())
            end
            Tooltip.draw(gui_state, S.tooltips.ungroup)
          end Layout.finish(gui_state, "|")
        end Layout.finish(gui_state, "-")
      end Layout.finish(gui_state, "|")

    end Layout.finish(gui_state, "-") -- Image editor and quad list

    -- Clear selection if escape was pressed
    if imgui.was_key_pressed(gui_state, "escape") then
      imgui.consume_key_press(gui_state, "escape")
      state.selection:clear_selection()
    end

    if was_menu_open then
      imgui.uncover_input(gui_state)
    end

  end Window.finish(gui_state, win_x, win_y, nil, {active = true, borderless = true})

  local function refresh_image_timestamp(data)
    if not data.quads._META or not data.quads._META.image_path then return end
    local filepath = data.quads._META.image_path
    local current_timestamp = lfs.attributes(filepath, "modification")
    if current_timestamp ~= data.file_timestamps.image_latest then
      if data.turbo_workflow then
        -- Automatically reload the image without asking
        app.quadtastic.load_image(filepath, reload_image_toast_callback)
      else
        -- Ask the user
        app.quadtastic.offer_reload(reload_image_toast_callback)
      end
    end
    data.file_timestamps.image_latest = current_timestamp
  end

  imgui.every_second(gui_state, refresh_image_timestamp, state)

  local function is_pressed(keybinding)
    if not keybinding then return false end
    local triggered = imgui.was_key_pressed(gui_state, keybinding[1])
    triggered = triggered and imgui.are_exact_modifiers_pressed(gui_state, keybinding[2])
    return triggered
  end

  if gui_state.input then
    if is_pressed(Keybindings.open) then app.quadtastic.choose_quad() end
    if is_pressed(Keybindings.save) then app.quadtastic.save(save_toast_callback) end
    if is_pressed(Keybindings.save_as) then app.quadtastic.save_as(save_toast_callback) end
    if is_pressed(Keybindings.quit) then app.quadtastic.quit() end
    if is_pressed(Keybindings.new) then app.quadtastic.new() end

    if is_pressed(Keybindings.undo) then app.quadtastic.undo() end
    if is_pressed(Keybindings.redo) then app.quadtastic.redo() end

    if is_pressed(Keybindings.delete) then app.quadtastic.remove() end
    if is_pressed(Keybindings.rename) then app.quadtastic.rename() end
    if is_pressed(Keybindings.group) then app.quadtastic.group() end
    if is_pressed(Keybindings.ungroup) then app.quadtastic.ungroup() end
  end

end

return Quadtastic