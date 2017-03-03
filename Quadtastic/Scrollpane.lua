local Layout = require("Layout")
local Rectangle = require("Rectangle")

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
local apply_focus = function(gui_state, scrollpane_state)
	assert(gui_state)
	assert(scrollpane_state)
	assert(scrollpane_state.focus)

	local bounds = scrollpane_state.focus

	-- We cannot focus on a specific element if we don't know the viewport's
	-- dimensions
	if not (scrollpane_state.w or scrollpane_state.h) then return end

	-- Try to center the scrollpane viewport on the given bounds, but without
	-- exceeding the limits set in the scrollpane state

	local center_bounds = {}
	center_bounds.x, center_bounds.y = Rectangle.center(bounds)
	-- This works because the scrollpane has x, y, w and h
	local center_vp = {}
	center_vp.x, center_vp.y = Rectangle.center(scrollpane_state)

	local dx, dy = center_bounds.x - center_vp.x, center_bounds.y - center_vp.y
	local x, y = scrollpane_state.x + dx, scrollpane_state.y + dy

	-- In immediate mode both the current and the target location are changed
	if bounds.mode == "immediate" then
		scrollpane_state.x = x
		scrollpane_state.y = y
	end
	-- Otherwise only the target position is changed
	scrollpane_state.tx = x
	scrollpane_state.ty = y

	scrollpane_state.focus = nil
end

-- Mode can be either "immediate" or "transition". Immediate makes the viewport
-- jump to the target position on the next frame, while transition causes a
-- smoother transition.
Scrollpane.set_focus = function(scrollpane_state, bounds, mode)
	scrollpane_state.focus = {
		x = bounds.x,
		y = bounds.y,
		w = bounds.w,
		h = bounds.h,
		mode = mode,
	}
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

		-- whether the scrollpane needed scrollbars in the last frame
		had_vertical = false,
		had_horizontal = false,

		-- Scrolling behavior
		tx = 0, -- target translate translation in x
    	ty = 0, -- target translate translation in y
    	last_dx = 0, -- last translate speed in x
	    last_dy = 0, -- last translate speed in y

	    -- Focus, will be applied on the next frame
	    focus = nil,
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

	-- Calculate the dimension of the viewport, based on whether the viewport
	-- needed a scrollbar in the last frame
	local inner_w = w
	if scrollpane_state.had_vertical then inner_w = inner_w - scrollbar_margin end
	local inner_h = h
	if scrollpane_state.had_horizontal then inner_h = inner_h - scrollbar_margin end

	-- Start a layout that encloses the viewport's content
	Layout.start(state, 0, 0, inner_w, inner_h)

	-- Update the scrollpane's viewport width and height
	scrollpane_state.w = state.layout.max_w
	scrollpane_state.h = state.layout.max_h

	-- Apply focus if there is one
	if scrollpane_state.focus then
		apply_focus(state, scrollpane_state)
	end

	-- Note the flipped signs
	love.graphics.translate(-scrollpane_state.x, -scrollpane_state.y)

	return scrollpane_state
end

Scrollpane.finish = function(state, scrollpane_state, w, h)
	-- If the content defined advance values in x and y, we can detect whether
	-- we need to draw scroll bars at all.
	local content_w = w or state.layout.adv_x
	local content_h = h or state.layout.adv_y

	-- Finish the layout that encloses the viewport's content
	Layout.finish(state)

	local x = state.layout.next_x
	local y = state.layout.next_y
	local w = state.layout.max_w
	local h = state.layout.max_h

	local has_vertical = content_h > state.layout.max_h - 
		(scrollpane_state.had_horizontal and scrollbar_margin or 0)
	local has_horizontal = content_w > state.layout.max_w - 
		(scrollpane_state.had_vertical and scrollbar_margin or 0)

	-- Render the vertical scrollbar if necessary
	if has_vertical then
		local height = h
		if has_horizontal then height = height - scrollbar_margin end
		love.graphics.draw(state.style.stylesheet, quads.up_button,
			               x + w - scrollbar_margin, y)
		love.graphics.draw(state.style.stylesheet, quads.background,
			               x + w - scrollbar_margin, y + scrollbar_margin,
			               0, 7, height - 2*scrollbar_margin)
		love.graphics.draw(state.style.stylesheet, quads.down_button,
			               x + w - scrollbar_margin, y + height - scrollbar_margin)
	end

	-- Render the horizontal scrollbar if necessary
	if has_horizontal then
		local width = w
		if has_vertical then width = width - scrollbar_margin end
		love.graphics.draw(state.style.stylesheet, quads.left_button,
			               x, y + h - scrollbar_margin)
		love.graphics.draw(state.style.stylesheet, quads.background,
			               x + scrollbar_margin, y + h - scrollbar_margin,
			               0, width - 2*scrollbar_margin, 7)
		love.graphics.draw(state.style.stylesheet, quads.right_button,
			               x + width - scrollbar_margin, y + h - scrollbar_margin)
	end

	-- Render the little corner if we have both a vertical and horizontal
	-- scrollbar
	if has_vertical and has_horizontal then
		love.graphics.draw(state.style.stylesheet, quads.corner,
			               x + w - scrollbar_margin, y + h - scrollbar_margin)
	end

	scrollpane_state.had_vertical = has_vertical
	scrollpane_state.had_horizontal = has_horizontal

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