local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local Layout = require(current_folder .. ".Layout")
local imgui = require(current_folder .. ".imgui")
local Button = require(current_folder .. ".Button")

local Menu = {}

function Menu.menubar_start(gui_state, w, h)
  imgui.push_style(gui_state, "font", gui_state.style.small_font)
  Layout.start(gui_state, 0, 0, w, h, {noscissor = true})
end

function Menu.menubar_finish(gui_state)
  Layout.finish(gui_state, "-")
  imgui.pop_style(gui_state, "font")
end

function Menu.menu_start(gui_state, w, h, label)
  local x = gui_state.layout.next_x
  local y = gui_state.layout.next_y + 12

  local options = {}
  if gui_state.current_menu == label then
    options.bg_color_default = {202, 222, 227}
  end
  -- Draw label
  local hit = Menu.menubar_item(gui_state, label, options)
  if hit then
    -- Set the current menu item to this menu, or unset it if this is the
    -- current item
    if gui_state.current_menu == label then
      gui_state.current_menu = nil
    else
      gui_state.current_menu = label
    end
  end
  love.graphics.push("all")
  love.graphics.setCanvas(gui_state.overlay_canvas)
  Layout.start(gui_state, x, y, w, h, {noscissor = true})
  return gui_state.current_menu == label
end

function Menu.menu_finish(gui_state)
  Layout.finish(gui_state, "|")
  gui_state.layout.adv_x = 0
  gui_state.layout.adv_y = 0
  love.graphics.setCanvas()
  love.graphics.pop()
end

local function draw_item_background(gui_state, h)
  local x = gui_state.layout.next_x
  local y = gui_state.layout.next_y
  local w = gui_state.layout.max_w
  love.graphics.setColor(202, 222, 227)
  love.graphics.rectangle("fill", x, y, w, h)
end

function Menu.menu_item(gui_state, label)
  draw_item_background(gui_state, 16)
  local options = {
    font_color = {0, 0, 0, 255},
    bg_color_hovered = {138, 179, 189},
    bg_color_pressed = {68, 137, 156},
  }
  local clicked = Button.draw_flat(gui_state, nil, nil, gui_state.layout.max_w, nil,
    label, nil, options)
  Layout.next(gui_state, "|")
  if clicked then
    gui_state.current_menu = nil
  end
  return clicked
end

function Menu.separator(gui_state)
  draw_item_background(gui_state, 3)
  local x = gui_state.layout.next_x + 2
  local y = gui_state.layout.next_y + 1
  local w = gui_state.layout.max_w - 4
  love.graphics.setColor(32, 63, 73)
  love.graphics.rectangle("fill", x, y, w, 1)
  gui_state.layout.adv_x = 0
  gui_state.layout.adv_y = 3
  Layout.next(gui_state, "|")
end

function Menu.menubar_item(gui_state, label, options)
  options = options or {}
  options.font_color = {0, 0, 0, 255}
  local clicked = Button.draw_flat(gui_state, nil, nil, nil, gui_state.layout.max_h,
    label, nil, options)
  Layout.next(gui_state, "-", 1)
  return clicked
end

return Menu
