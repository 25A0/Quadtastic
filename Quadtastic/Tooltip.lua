local Text = require("Text")
local imgui = require("imgui")

local Renderutils = require("Renderutils")

local Tooltip = {}

unpack = unpack or table.unpack

local border_quads  = Renderutils.border_quads(0, 48, 5, 5, 128, 128, 2)
local tip_quad_down = love.graphics.newQuad(6, 48, 5, 3, 128, 128)
local tip_quad_up   = love.graphics.newQuad(6, 50, 5, 3, 128, 128)

local find_tooltip_position = function(gui_state, x, y, w, h, label, options)
   	local textlength = Text.min_width(gui_state, label or "Someone forgot to set the tooltip text...")

	return x + w / 2 - (textlength + 2*2)/2, y + h + 3, textlength + 2*2, 16
end

local show_tooltip = function(gui_state, x, y, w, h, label, options)
   	gui_state.overlay_canvas:renderTo(function()
	   	-- Remember and remove the current scissor
	   	local old_scissor = {love.graphics.getScissor()}
	   	love.graphics.setScissor()

	   	-- Use the small font for the tooltip label
	   	imgui.push_style(gui_state, "font", gui_state.style.small_font)

	   	local ttx, tty, ttw, tth = find_tooltip_position(gui_state, x, y, w, h, label, options)

	   	love.graphics.setColor(255, 255, 255, 255)
	   	-- Draw tooltip border
	   	Renderutils.draw_border(gui_state.style.stylesheet, border_quads, ttx, tty, ttw, tth, 2)
	   	-- Draw tooltip tip
	   	love.graphics.draw(gui_state.style.stylesheet, tip_quad_up, x + w/2, y+h)
	   	if not options then options = {} end
	   	if not options.font_color then
	   		options.font_color = {202, 222, 227}
	   	end
	   	Text.draw(gui_state, ttx + 2, tty, ttw, tth, label, options)

	   	imgui.pop_style(gui_state, "font")

	   	-- Restore the old scissor
	   	love.graphics.setScissor(unpack(old_scissor))

	end)
end

-- A tooltip ignores the current layout's bounds but uses the current layout
-- hints to determine where it should be drawn. It will be drawn at the bottom
-- or the top of the previously drawn component
Tooltip.draw = function(gui_state, label, x, y, w, h, options)
	-- The dimensions of the item next to which the tooltip will be displayed
	x = x or gui_state.layout.next_x
	y = y or gui_state.layout.next_y
	w = w or gui_state.layout.adv_x
	h = h or gui_state.layout.adv_y

	-- love.graphics.rectangle("line", x, y, w, h)

	local old_mouse_x = gui_state.mouse.old_x
	local old_mouse_y = gui_state.mouse.old_y
	if not old_mouse_x or not old_mouse_y then return end

	-- Check if the mouse was in that area in the previous frame
	local was_in_frame = imgui.is_mouse_in_rect(gui_state, x, y, w, h,
		old_mouse_x, old_mouse_y)
	-- Now check the current mouse position
	local is_in_frame = imgui.is_mouse_in_rect(gui_state, x, y, w, h)

	if was_in_frame and is_in_frame then
		gui_state.tooltip_time = gui_state.tooltip_time + gui_state.dt
	elseif is_in_frame then -- the mouse has just been moved into the frame
		-- This is not super-accurate but will probably suffice
		gui_state.tooltip_time = gui_state.dt
	else -- the mouse is not in the frame.
		return
	end
	print("tooltip time: ", gui_state.tooltip_time)

	-- The threshold after which the tooltip should be displayed. Default is 1s
	local threshold = options and options.tooltip_threshold or 1

	if gui_state.tooltip_time > threshold then -- display the tooltip
		show_tooltip(gui_state, x, y, w, h, label, options)
	end

end

return Tooltip
