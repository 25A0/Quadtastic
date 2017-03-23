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

  local opened = imgui.is_menu_open(gui_state, label)

  if opened then
    options.bg_color_default = {202, 222, 227}
  end
  -- Draw label
  local hit = Menu.menubar_item(gui_state, label, options)
  if hit then
    imgui.toggle_menu(gui_state, label)
  end

  if opened then
    love.graphics.push("all")
    love.graphics.setCanvas(gui_state.overlay_canvas)

    -- Draw decoration at the top
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(gui_state.style.stylesheet, gui_state.style.quads.menu.tl, x, y)
    local tl_w = gui_state.style.raw_quads.menu.tl.w
    local tr_w = gui_state.style.raw_quads.menu.tr.w
    local t_w = gui_state.style.raw_quads.menu.t.w
    assert(t_w == 1)
    love.graphics.draw(gui_state.style.stylesheet, gui_state.style.quads.menu.t,
      x + tl_w, y, 0, w - tl_w - tr_w, 1)
    love.graphics.draw(gui_state.style.stylesheet, gui_state.style.quads.menu.tr,
      x + w - tr_w, y)
    local deco_height = gui_state.style.raw_quads.menu.t.h
    Layout.start(gui_state, x, y + deco_height, w, h - 2*deco_height, {noscissor = true})
  end

  return opened
end

function Menu.menu_finish(gui_state, w, h)
  local x = gui_state.layout.next_x
  local y = gui_state.layout.next_y

  -- Draw decoration at the bottom
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(gui_state.style.stylesheet, gui_state.style.quads.menu.bl, x, y)
  local tl_w = gui_state.style.raw_quads.menu.bl.w
  local tr_w = gui_state.style.raw_quads.menu.br.w
  local t_w = gui_state.style.raw_quads.menu.b.w
  assert(t_w == 1)
  love.graphics.draw(gui_state.style.stylesheet, gui_state.style.quads.menu.b,
    x + tl_w, y, 0, w - tl_w - tr_w, 1)
  love.graphics.draw(gui_state.style.stylesheet, gui_state.style.quads.menu.br,
    x + w - tr_w, y)

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

function Menu.menu_item(gui_state, label, options)
  draw_item_background(gui_state, 16)
  options = options or {}
  if options.disabled then
    options.font_color = {128, 128, 128}
  elseif not options.font_color then options.font_color = {0, 0, 0, 255} end
  if not options.bg_color_hovered then options.bg_color_hovered = {68, 137, 156} end
  if not options.bg_color_pressed then options.bg_color_pressed = {42, 82, 94} end

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
  if options.disabled then
    options.font_color = {128, 128, 128}
  else
    options.font_color = {0, 0, 0, 255}
  end
  local clicked = Button.draw_flat(gui_state, nil, nil, nil, gui_state.layout.max_h,
    label, nil, options)
  Layout.next(gui_state, "-", 1)
  return clicked
end

return Menu
