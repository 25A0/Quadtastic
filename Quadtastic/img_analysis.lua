local analysis = {}

-- Returns strips of pixels in the given row that fulfill the given condition.
-- The condition should be a function image_data, x, y -> boolean
-- The return value is a table which contains a table for each strip, which in
-- turn holds the x coordinate of the first and last pixel that fulfilled the
-- condition.
-- If no pixels fulfil the condition, an empty table is returned.
-- If a strip from pixel 5 to 8 fulfills the condition, then {{5, 8}} is returned.
local function find_strips(image_data, y, w, condition)
  local found = {}
  local x = 0
  local x_start
  while x < w do
    if condition(image_data, x, y) then
      x_start = x
      x = x + 1
      while x < w and condition(image_data, x, y) do
        x = x + 1
      end
      -- Now x is w, or the first pixel that didn't fulfill the condition.
      -- This means that the strip starts at x_start, and stops at x - 1.
      table.insert(found, {x_start, x - 1})
    end
    -- Note that we advance x by 2 in this iteration in case that we found a
    -- strip. This is fine because we already checked the previous pixel. If
    -- that pixel had fulfilled the condition then the strip would not have ended.
    x = x + 1
  end

  return found
end

-- Finds and returns the chunk of non-transparent pixels that is connected
-- to the given pixel. Returns nil if the given pixel itself is transparent.
-- A chunk is the smallest rectangle that surrounds a connected region of opaque
-- pixels.
function analysis.outter_bounding_box(image_or_imagedata, mx, my)
  local img
  if image_or_imagedata:type() == "Image" then
    img = image_or_imagedata:getData()
  else
    assert(image_or_imagedata:type() == "ImageData")
    img = image_or_imagedata
  end
  local w, h = img:getWidth(), img:getHeight()

  local function is_opaque(image_data, x, y)
    return select(4, image_data:getPixel(x, y)) ~= 0
  end

  local function create_strip_node(y, strip)
    strip.y = y
    strip.neighbors = {}
    return strip
  end

  local function connect_nodes(s1, s2)
    table.insert(s1.neighbors, s2)
    table.insert(s2.neighbors, s1)
  end

  if mx < 0 or mx >= w or my < 0 or my >= h then return nil end
  if not is_opaque(img, mx, my) then return nil end

  -- The initial set of strips
  local strips = find_strips(img, my, w, is_opaque)
  for _, strip in ipairs(strips) do
    create_strip_node(my, strip)
  end

  -- numeric identifiers for events to cut down on the number of hashes
  local evt_prev_strip_starts = 1
  local evt_prev_strip_ends = 2
  local evt_new_strip_starts = 3
  local evt_new_strip_ends = 4
  local evt_finished = 5

  local strip_iterator = function(previous_strips, new_strips)
    local i_prev, i_new = 1, 1 -- the index of the next strips
    local next_p_prev = previous_strips[i_prev][1]
    local next_p_new  = new_strips     [i_new ][1]
    local started_prev, started_new = false, false
    while next_p_prev or next_p_new do
      if not next_p_prev or next_p_new and
        (started_prev and next_p_new <= next_p_prev or next_p_new < next_p_prev)
      then
        if started_new then
          coroutine.yield(evt_new_strip_ends, new_strips[i_new])
          started_new = false
          i_new = i_new + 1
          if i_new <= #new_strips then
            next_p_new = new_strips[i_new][1]
          else
            next_p_new = nil
          end
        else
          coroutine.yield(evt_new_strip_starts, new_strips[i_new])
          started_new = true
          next_p_new = new_strips[i_new][2]
        end
      else
        if started_prev then
          coroutine.yield(evt_prev_strip_ends, previous_strips[i_prev])
          started_prev = false
          i_prev = i_prev + 1
          if i_prev <= #previous_strips then
            next_p_prev = previous_strips[i_prev][1]
          else
            next_p_prev = nil
          end
        else
          coroutine.yield(evt_prev_strip_starts, previous_strips[i_prev])
          started_prev = true
          next_p_prev = previous_strips[i_prev][2]
        end
      end
    end
    return evt_finished
  end

  -- this is basically a straight implementation of the finite state
  -- diagram that you would probably love to have in front of you right
  -- now. But alas, this is not TempleOS, so no diagrams in source code
  -- for you :P
  local states = {}
  states[1] = function(event, strip)
    if event == evt_prev_strip_starts then
      return states[3], strip
    elseif event == evt_new_strip_starts then
      return states[2], strip
    else error("did not expect event " .. event) end
  end

  states[2] = function(event, strip, new_strip)
    if event == evt_new_strip_ends then
      return states[1]
    elseif event == evt_prev_strip_starts then
      connect_nodes(strip, new_strip)
      return states[4], strip, new_strip
    else error("did not expect event " .. event) end
  end

  states[3] = function(event, strip, prev_strip)
    if event == evt_prev_strip_ends then
      return states[1]
    elseif event == evt_new_strip_starts then
      connect_nodes(prev_strip, strip)
      return states[4], prev_strip, strip
    else error("did not expect event " .. event) end
  end

  states[4] = function(event, _, prev_strip, new_strip)
    if event == evt_prev_strip_ends then
      return states[5], new_strip
    elseif event == evt_new_strip_ends then
      return states[3], prev_strip
    else error("did not expect event " .. event) end
  end

  states[5] = function(event, strip, new_strip)
    if event == evt_prev_strip_starts then
      connect_nodes(strip, new_strip)
      return states[4], strip, new_strip
    elseif event == evt_new_strip_ends then
      return states[1]
    else error("did not expect event " .. event) end
  end

  local function search(initial_strips, py, dy)
    local previous_strips = initial_strips
    py = py + dy
    while py >= 0 and py < h do
      local new_strips = find_strips(img, py, w, is_opaque)
      -- Stop if this line didn't contain any strips
      if #new_strips == 0 then break end

      -- turn all these strips into strip nodes
      for _,strip in ipairs(new_strips) do
        create_strip_node(py, strip)
      end

      local co = coroutine.create(strip_iterator)
      local _, event, strip = coroutine.resume(co, previous_strips, new_strips)
      local state = states[1]
      local s1, s2 -- extra strips used as temporary variables
      while event ~= evt_finished do
        state, s1, s2 = state(event, strip, s1, s2)
        _, event, strip = coroutine.resume(co)
      end

      previous_strips = new_strips
      py = py + dy
    end
  end

  -- Search upwards how far the chunks expand
  search(strips, my, -1)
  search(strips, my,  1)

  -- search for the strip that contains mx
  local result_strip
  for _, strip in ipairs(strips) do
    if strip[1] <= mx and mx <= strip[2] then
      result_strip = strip
      break
    end
  end
  assert(result_strip)

  local result_chunk = {min_x = mx, min_y = my, max_x = mx, max_y = my}
  local seen_strips = {}
  local open_strips = {result_strip}
  while #open_strips > 0 do
    local strip = table.remove(open_strips)

    -- expand the result chunk
    result_chunk.min_y = math.min(strip.y, result_chunk.min_y)
    result_chunk.max_y = math.max(strip.y, result_chunk.max_y)
    result_chunk.min_x = math.min(strip[1], result_chunk.min_x)
    result_chunk.max_x = math.max(strip[2], result_chunk.max_x)

    seen_strips[strip] = true
    for _,connected_strip in ipairs(strip.neighbors) do
      if not seen_strips[connected_strip] then
        table.insert(open_strips, connected_strip)
      end
    end
  end

  -- return a rectangle
  return {
    x = result_chunk.min_x,
    y = result_chunk.min_y,
    w = 1 + result_chunk.max_x - result_chunk.min_x,
    h = 1 + result_chunk.max_y - result_chunk.min_y,
  }
end

return analysis
