local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local imgui = require(current_folder .. ".imgui")

local Grid = {}

function Grid.should_snap_to_grid(gui_state, state)
  local should_snap = state.settings.grid.always_snap
  if imgui.are_exact_modifiers_pressed(gui_state, {"*alt"}) then
    -- invert should_snap
    should_snap = not should_snap
  end
  return should_snap
end

-- Snap value to the left or top of the grid tile
function Grid.floor(grid, val)
  return val - (val % grid)
end

-- Snap value to the right or bottom of the grid tile
function Grid.ceil(grid, val)
  return val + (grid - val % grid - 1)
end

-- Returns the closest grid multiple of val.
-- For example, mult(8,  7) -> 8
--              mult(8, 11) -> 8
function Grid.mult(grid, val)
  if val % grid > grid / 2 then
    return val + grid - val % grid
  else
    return val - val % grid
  end
end

-- Returns the closest grid point to px and py.
function Grid.snap_point(grid, px, py)
  local gx, gy
  if px % grid.x >= grid.x / 2 then
    gx = Grid.ceil(grid.x, px)
  else
    gx = Grid.floor(grid.x, px)
  end
  if py % grid.y >= grid.y / 2 then
    gy = Grid.ceil(grid.y, py)
  else
    gy = Grid.floor(grid.y, py)
  end
  return gx, gy
end

-- Returns a new rectangle where all four corners snapped to the grid.
-- Note that the four corners will be snapped differently. For example, in a 8x8
-- grid, the left side of the rectangle can be at x positions 0, 8, 16, 24, ...,
-- while the right side of the rectangle can be at x positions 7, 15, 23, 31, ....
function Grid.snap_rect(grid, rect)
  local grid_rect = {}
  grid_rect.x = Grid.floor(grid.x, rect.x)
  grid_rect.y = Grid.floor(grid.y, rect.y)

  local dx = rect.x - grid_rect.x
  local dy = rect.y - grid_rect.y
  local min_w = rect.w + (dx < grid.x / 2 and dx or 0)
  local min_h = rect.h + (dy < grid.y / 2 and dy or 0)
  grid_rect.w = Grid.mult(grid.x, min_w)
  grid_rect.h = Grid.mult(grid.y, min_h)

  return grid_rect
end

function Grid.expand_rect(grid, rect)
  local grid_rect = {}
  grid_rect.x = Grid.floor(grid.x, rect.x)
  grid_rect.y = Grid.floor(grid.y, rect.y)
  -- If the rectangle was moved to the left or to the top, then the width and
  -- height need to change accordingly to make sure that the content is still
  -- enclosed in the rectangle.
  local min_w = rect.w + rect.x - grid_rect.x
  local min_h = rect.h + rect.y - grid_rect.y
  -- In this function, the width and height will always expand up to the next
  -- multiple of the grid size. This prevents that small sprites snap to a
  -- width that does not include the entire sprite.
  grid_rect.w = math.max(grid.x, grid.x * math.ceil(min_w / grid.x))
  grid_rect.h = math.max(grid.y, grid.y * math.ceil(min_h / grid.y))

  return grid_rect
end

return Grid
