local Layout = require("Layout")

local Scrollpane = {}

local scrollbar_margin = 7

local quads = {
	up_button =      love.graphics.newQuad(80, 0, 7, 7, 128, 128),
	down_button =    love.graphics.newQuad(80, 9, 7, 7, 128, 128),
	left_button =    love.graphics.newQuad(96, 9, 7, 7, 128, 128),
	right_button =   love.graphics.newQuad(96, 0, 7, 7, 128, 128),
	top_bar =        love.graphics.newQuad(89, 0, 7, 3, 128, 128),
	horizontal_bar = love.graphics.newQuad(89, 3, 7, 1, 128, 128),
	bottom_bar =     love.graphics.newQuad(89, 6, 7, 3, 128, 128),
	left_bar =       love.graphics.newQuad(106, 0, 2, 7, 128, 128),
	vertical_bar =   love.graphics.newQuad(108, 0, 1, 7, 128, 128),
	right_bar =      love.graphics.newQuad(109, 0, 2, 7, 128, 128),
	background =     love.graphics.newQuad(89, 9, 1, 1, 128, 128),
	corner =         love.graphics.newQuad(105, 9, 7, 7, 128, 128),
}

-- Move the scrollpane to focus on the given bounds.
-- Might be restricted by the inner bounds in the scrollpane_state
-- (i.e. when moving to the first item, it will not center the viewport on
-- that item, but rather have the viewport's upper bound line up with the upper
-- bound of that item.)
Scrollpane.set_focus = function(gui_state, bounds, scrollpane_state)
	assert(gui_state)
	assert(bounds)
	assert(scrollpane_state)

	-- We cannot focus on a specific element if we don't know the viewport's
	-- dimensions
	if not (scrollpane_state.w or scrollpane_state.h) then return end

	-- Try to center the scrollpane viewport on the given bounds, but without
	-- exceeding the limits set in the scrollpane state

	local center_bounds = Rectangle.center(bounds)
	-- This works because the scrollpane has x, y, w and h
	local center_vp = Rectangle.center(scrollpane_state)

	local dx, dy = center_bounds.x - center_vp.x, center_bounds.y - center_vp.y
	scrollpane_state.x = scrollpane_state.x + dx
	scrollpane_state.y = scrollpane_state.y + dy
end

Scrollpane.init_scrollpane_state = function(x, y, min_x, min_y, max_x, max_y)
	return  {
		x = x or 0, -- the x offset of the viewport
		y = y or 0, -- the y offset of the viewport
		-- If any of the following are set to nil, then the viewport's movement
		-- is not restricted.
		min_x = min_x, -- the x coordinate below which the viewport cannot be moved
		min_y = min_y, -- the y coordinate below which the viewport cannot be moved
		max_x = max_x, -- the x coordinate above which the viewport cannot be moved
		max_y = max_y, -- the y coordinate above which the viewport cannot be moved
		-- the dimensions of the scrollpane's viewport. will be updated
		-- automatically
		w = nil,
		h = nil,
		-- Scrolling behavior
		tx = 0, -- target translate translation in x
    	ty = 0, -- target translate translation in y
    	last_dx = 0, -- last translate speed in x
	    last_dy = 0, -- last translate speed in y

	}
end

Scrollpane.start = function(state, x, y, w, h, scrollpane_state)
	scrollpane_state = scrollpane_state or Scrollpane.init_scrollpane_state()

	assert(state)
	assert(scrollpane_state)
	x = x or state.layout.next_x
	y = y or state.layout.next_y
	w = w or state.layout.max_w
	h = h or state.layout.max_h

	-- Start a layout that contains this scrollpane
	Layout.start(state, x, y, w, h)
	love.graphics.clear(76, 100, 117)

	-- Start a layout that encloses the viewport's content
	-- Note the flipped signs for the scrollpane's offset
	Layout.start(state, 0, 0, w - scrollbar_margin, h - scrollbar_margin)
	love.graphics.translate(-scrollpane_state.x, -scrollpane_state.y)
	-- Update the scrollpane's viewport width and height
	scrollpane_state.w = state.layout.max_w
	scrollpane_state.h = state.layout.max_h

	return scrollpane_state
end

Scrollpane.finish = function(state, scrollpane_state)
	-- Finish the layout that encloses the viewport's content
	Layout.finish(state)

	local x = state.layout.next_x
	local y = state.layout.next_y
	local w = state.layout.max_w
	local h = state.layout.max_h

	-- Render the vertical scrollbar
	love.graphics.draw(state.style.stylesheet, quads.up_button,
		               x + w - scrollbar_margin, y)
	love.graphics.draw(state.style.stylesheet, quads.background,
		               x + w - scrollbar_margin, y + scrollbar_margin,
		               0, 7, h - 3*scrollbar_margin)
	love.graphics.draw(state.style.stylesheet, quads.down_button,
		               x + w - scrollbar_margin, y + h - 2*scrollbar_margin)

	-- Render the horizontal scrollbar
	love.graphics.draw(state.style.stylesheet, quads.left_button,
		               x, y + h - scrollbar_margin)
	love.graphics.draw(state.style.stylesheet, quads.background,
		               x + scrollbar_margin, y + h - scrollbar_margin,
		               0, w - 3*scrollbar_margin, 7)
	love.graphics.draw(state.style.stylesheet, quads.right_button,
		               x + w - 2 * scrollbar_margin, y + h - scrollbar_margin)

	-- Render the little corner
	love.graphics.draw(state.style.stylesheet, quads.corner,
		               x + w - scrollbar_margin, y + h - scrollbar_margin)

	-- This layout always fills the available space
	state.layout.adv_x = state.layout.max_w
	state.layout.adv_y = state.layout.max_h
	Layout.finish(state)

	-- Image panning

	local friction = 0.5
	local threshold = 3

	if state.mouse.wheel_dx ~= 0 then
		scrollpane_state.tx = scrollpane_state.x + 4*state.mouse.wheel_dx
	elseif math.abs(scrollpane_state.last_dx) > threshold then
		scrollpane_state.tx = scrollpane_state.x + scrollpane_state.last_dx
	end
	local dx = friction * (scrollpane_state.tx - scrollpane_state.x)

	if state.mouse.wheel_dy ~= 0 then
		scrollpane_state.ty = scrollpane_state.y - 4*state.mouse.wheel_dy
	elseif math.abs(scrollpane_state.last_dy) > threshold then
		scrollpane_state.ty = scrollpane_state.y + scrollpane_state.last_dy
	end
	local dy = friction * (scrollpane_state.ty - scrollpane_state.y)

	-- Apply the translation change
	scrollpane_state.x = scrollpane_state.x + dx
	scrollpane_state.y = scrollpane_state.y + dy
	-- Remember the last delta to possibly trigger floating in the next frame
	scrollpane_state.last_dx = dx
	scrollpane_state.last_dy = dy

end

return Scrollpane