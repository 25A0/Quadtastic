local imgui = require("imgui")

local Layout = {}

-- Orientation should be "|" for vertical or "-" for horizontal
Layout.start = function(state, x, y, w, h, options)
	x = x or state.layout.next_x
	y = y or state.layout.next_y
	w = w or state.layout.max_w
	h = h or state.layout.max_h

	imgui.push_layout_state(state, 0, 0, w, h)

	love.graphics.push("all")

	if not options or not options.noscissor then
      local abs_x, abs_y = state.transform:project(x, y)
      local abs_w, abs_h = state.transform:project_dimensions(w, h)
      love.graphics.intersectScissor(abs_x, abs_y, abs_w, abs_h)
    end

	love.graphics.translate(x, y)
end

local function update_state(state, orientation, spacing)
	orientation = orientation or "-"
	spacing = spacing or 0

	-- For a horizontal layout, the advance in x is added to the accumulative
	-- advance, while the advance in y might increase the accumulative advance
	-- in y if it is larger than the current advance.
	-- Since we stack elements next to one another horizontally, the
	-- accumulative advance in y is the advance in y of the largest element.

	-- For a vertical layout it's the same logic with x and y swapped.
	if orientation == "-" then
		state.layout.acc_adv_x = state.layout.acc_adv_x + state.layout.adv_x
		-- Decrease the remaining width by the advance in x
		state.layout.max_w = math.max(0, state.layout.max_w - state.layout.adv_x - spacing)
    	state.layout.acc_adv_y = math.max(state.layout.acc_adv_y, state.layout.adv_y)

    	state.layout.next_x = state.layout.next_x + state.layout.adv_x + spacing
	else
    	state.layout.acc_adv_x = math.max(state.layout.acc_adv_x, state.layout.adv_x)
    	state.layout.acc_adv_y = state.layout.acc_adv_y + state.layout.adv_y
		-- Decrease the remaining height by the advance in y
		state.layout.max_h = math.max(0, state.layout.max_h - state.layout.adv_y - spacing)

    	state.layout.next_y = state.layout.next_y + state.layout.adv_y + spacing
	end
	state.layout.adv_x = 0
	state.layout.adv_y = 0

end

Layout.next = function(state, orientation, spacing)
	update_state(state, orientation, spacing)
end

Layout.finish = function(state, orientation)
	-- Update the accumulated advances for the last element
	update_state(state, orientation, 0)

	local acc_adv_x = state.layout.acc_adv_x
	local acc_adv_y = state.layout.acc_adv_y

	love.graphics.pop()

	imgui.pop_layout_state(state)

	state.layout.adv_x = acc_adv_x
	state.layout.adv_y = acc_adv_y
end

return Layout