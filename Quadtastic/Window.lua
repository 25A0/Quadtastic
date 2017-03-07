local Layout = require("Quadtastic/Layout")

local Window = {}

Window.start = function(gui_state, x, y, w, h, options)
	-- Store the window's bounds in the gui state
	gui_state.window_bounds = {x = x, y = y, w = w, h = h}
	gui_state.window_transform = gui_state.transform:clone()

	local margin = options and options.margin or 0
	-- Enclose the window's content in a Layout
	Layout.start(gui_state, x + margin, y + margin, w - 2*margin, h - 2*margin)
end

Window.finish = function(gui_state)
	-- Finish the window that encloses the content
	Layout.finish(gui_state)
	-- Remove the window bounds
	gui_state.window_bounds = nil
	gui_state.window_transform = nil
end

return Window