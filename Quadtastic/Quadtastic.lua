local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local State = require(current_folder .. ".State")

local imgui = require(current_folder .. ".imgui")
local Button = require(current_folder .. ".Button")
local Inputfield = require(current_folder .. ".Inputfield")
local Label = require(current_folder .. ".Label")
local Frame = require(current_folder .. ".Frame")
local Layout = require(current_folder .. ".Layout")
local Window = require(current_folder .. ".Window")
local Scrollpane = require(current_folder .. ".Scrollpane")
local Tooltip = require(current_folder .. ".Tooltip")
local ImageEditor = require(current_folder .. ".ImageEditor")
local QuadList = require(current_folder .. ".QuadList")
local libquadtastic = require(current_folder .. ".libquadtastic")
local table = require(current_folder .. ".tableplus")
local Selection = require(current_folder .. ".Selection")
local QuadtasticLogic = require(current_folder .. ".QuadtasticLogic")
local Menu = require(current_folder .. ".Menu")

local lfs = require("lfs")

local Quadtastic = State("quadtastic",
  nil,
  -- initial data
  {
    display = {
      zoom = 1, -- additional zoom factor for the displayed image
    },
    scrollpane_state = nil,
    quad_scrollpane_state = nil,
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
}

Quadtastic.transitions = QuadtasticLogic.transitions(interface)

-- -------------------------------------------------------------------------- --
--                           DRAWING
-- -------------------------------------------------------------------------- --
Quadtastic.draw = function(app, state, gui_state)
  local w, h = gui_state.transform:unproject_dimensions(
    love.graphics.getWidth(), love.graphics.getHeight()
  )
  love.graphics.clear(138, 179, 189)
  local win_x, win_y = 0, 0
  do Window.start(gui_state, win_x, win_y, w, h, {margin = 2, active = true, borderless = true})
    do Menu.menubar_start(gui_state, w, 12)
      if Menu.menu_start(gui_state, w/4, h - 12, "File") then
        if Menu.action_item(gui_state, "New") then app.quadtastic.new() end
        if Menu.action_item(gui_state, "Open...") then app.quadtastic.choose_quad() end
        if Menu.action_item(gui_state, "Save") then app.quadtastic.save() end
        if Menu.action_item(gui_state, "Save as...") then app.quadtastic.save_as() end
        Menu.separator(gui_state)
        if Menu.action_item(gui_state, "Quit") then love.event.quit() end
        Menu.menu_finish(gui_state, w/4, h - 12)
      end
      if Menu.menu_start(gui_state, w/4, h - 12, "Edit") then
        Menu.action_item(gui_state, "Undo", {disabled = true})
        Menu.action_item(gui_state, "Redo", {disabled = true})
        Menu.menu_finish(gui_state, w/4, h - 12)
      end
      if Menu.menu_start(gui_state, w/4, h - 12, "Image") then
        if Menu.action_item(gui_state, "Open image...") then app.quadtastic.choose_image() end
        local loaded = state.file_timestamps.image_loaded
        local latest = state.file_timestamps.image_latest
        local can_reload = loaded and latest and loaded ~= latest
        local disabled = not can_reload or not state.quads._META.image_path
        if Menu.action_item(gui_state, "Reload image", {disabled = disabled}) then
          app.quadtastic.load_image(state.quads._META.image_path)
        end
        Menu.menu_finish(gui_state, w/4, h - 12)
      end
    end Menu.menubar_finish(gui_state)

    if imgui.is_any_menu_open(gui_state) then
      imgui.cover_input(gui_state)
    end

    Layout.next(gui_state, "|")

    do Layout.start(gui_state) -- Image editor
      do Layout.start(gui_state, nil, nil, gui_state.layout.max_w - 160, nil)
        do Frame.start(gui_state, nil, nil, nil, gui_state.layout.max_h - 13)
          if state.image then
            local new_quad = ImageEditor.draw(gui_state, state)
            if new_quad then
              table.insert(state.quads, new_quad)
              QuadList.move_quad_into_view(state.quad_scrollpane_state, new_quad)
            end
          else
            -- Put a label in the center of the frame
            Label.draw(gui_state, nil, nil, gui_state.layout.max_w, gui_state.layout.max_h,
                       "no image :(", {alignment_h = ":", alignment_v = "-"})
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
            Tooltip.draw(gui_state, "Zoom in")
          end
          Layout.next(gui_state, "-")
          do
            local pressed = Button.draw(gui_state, nil, nil, nil, nil, nil,
              gui_state.style.quads.buttons.minus)
            if pressed then
              ImageEditor.zoom(state, -1)
            end
            Tooltip.draw(gui_state, "Zoom out")
          end
          Layout.next(gui_state, "-")

          -- Status bar
          imgui.push_style(gui_state, "font", gui_state.style.small_font)

          love.graphics.setColor(255, 255, 255, 255)
          Label.draw(gui_state, nil, -3, nil, nil, string.format("%d%%", state.display.zoom * 100))
          if os.getenv("DEBUG") then
            Layout.next(gui_state, "-")
            Label.draw(gui_state, nil, -3, nil, nil, string.format("%d FPS", gui_state.fps or gui_state.frames or 0))
          end
          imgui.pop_style(gui_state, "font")

        end Layout.finish(gui_state, "-") -- Zoom buttons

      end Layout.finish(gui_state, "|")

      Layout.next(gui_state, "-", 2)

      -- Quad list and buttons
      do Layout.start(gui_state)
        -- Quad list
        do Layout.start(gui_state)
          do Layout.start(gui_state, nil, nil, gui_state.layout.max_w - 21)
            -- Draw the list of quads
            local clicked, hovered =
              QuadList.draw(gui_state, state, nil, nil, nil, gui_state.layout.max_h - 19,
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
                    for _,v in pairs(parent) do
                      if v == clicked then
                        found_new = true
                      end
                      if v == state.previous_clicked then
                        found_previous = true
                      end
                      if found_new or found_previous then
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

            if Button.draw(gui_state, nil, nil, gui_state.layout.max_w, nil, "EXPORT", nil, {alignment_h = ":"}) then
              app.quadtastic.save()
            end
          end Layout.finish(gui_state, "|")
          Layout.next(gui_state, "-", 2)

          -- Draw button column
          do Layout.start(gui_state)
            if Button.draw(gui_state, nil, nil, nil, nil, nil,
                           gui_state.style.quads.buttons.rename)
            then
              app.quadtastic.rename(state.selection:get_selection())
            end
            Tooltip.draw(gui_state, "Rename")
            Layout.next(gui_state, "|")
            if Button.draw(gui_state, nil, nil, nil, nil, nil,
                           gui_state.style.quads.buttons.delete)
            then
              app.quadtastic.remove(state.selection:get_selection())
            end
            Tooltip.draw(gui_state, "Delete selected quad(s)")
            Layout.next(gui_state, "|")
            if Button.draw(gui_state, nil, nil, nil, nil, nil,
                           gui_state.style.quads.buttons.sort)
            then
              app.quadtastic.sort(state.selection:get_selection())
            end
            Tooltip.draw(gui_state, "Sort unnamed quads from top to bottom, left to right")
            Layout.next(gui_state, "|")
            if Button.draw(gui_state, nil, nil, nil, nil, nil,
                           gui_state.style.quads.buttons.group)
            then
              app.quadtastic.group(state.selection:get_selection())
            end
            Tooltip.draw(gui_state, "Form new group from selected quads")
            Layout.next(gui_state, "|")
            if Button.draw(gui_state, nil, nil, nil, nil, nil,
                           gui_state.style.quads.buttons.ungroup)
            then
              app.quadtastic.ungroup(state.selection:get_selection())
            end
            Tooltip.draw(gui_state, "Break up selected group(s)")
          end Layout.finish(gui_state, "|")
        end Layout.finish(gui_state, "-")
      end Layout.finish(gui_state, "|")

    end Layout.finish(gui_state, "-") -- Image editor and quad list

    -- Clear selection if escape was pressed
    if imgui.was_key_pressed(gui_state, "escape") then
      imgui.consume_key_press(gui_state, "escape")
      state.selection:clear_selection()
    end

    if imgui.is_any_menu_open(gui_state) then
      imgui.uncover_input(gui_state)
    end

  end Window.finish(gui_state, win_x, win_y, nil, {active = true, borderless = true})

  local function refresh_image_timestamp(data)
    if not data.quads._META.image_path then return end
    local filepath = data.quads._META.image_path
    data.file_timestamps.image_latest = lfs.attributes(filepath, "modification")
    print("Image last modified at " .. data.file_timestamps.image_loaded)
  end

  imgui.every_second(gui_state, refresh_image_timestamp, state)

end

return Quadtastic