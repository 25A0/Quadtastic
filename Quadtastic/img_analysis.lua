local analysis = {}

-- Returns strips of pixels in the given row that fulfill the given condition.
-- The condition should be a function image_data, x, y, first_x -> boolean
-- first_x is the x-coordinate of the first pixel in the current strip that
-- fulfilled the condition, or nil.
-- The return value is a table which contains a table for each strip, which in
-- turn holds the x coordinate of the first and last pixel that fulfilled the
-- condition.
-- If no pixels fulfil the condition, an empty table is returned.
-- If a strip from pixel 5 to 8 fulfills the condition, then {{5, 8}} is returned.
local function find_strips(image_data, y, min_x, max_x, condition)
  local found = {}
  local x = min_x or 0
  local x_start
  while x <= max_x do
    if condition(image_data, x, y) then
      x_start = x
      x = x + 1
      while x <= max_x and condition(image_data, x, y, x_start) do
        x = x + 1
      end
      -- Now x is w, or the first pixel that didn't fulfill the condition.
      -- This means that the strip starts at x_start, and stops at x - 1.
      table.insert(found, {x_start, x - 1})
    else
      -- Only if the condition was not fulfilled we advance via this branch.
      -- This prevents that we skip a pixel after the condition is no longer true.
      x = x + 1
    end
  end

  return found
end

-- numeric identifiers for events to cut down on the number of hashes
local evt_prev_strip_starts = 1
local evt_prev_strip_ends = 2
local evt_new_strip_starts = 3
local evt_new_strip_ends = 4
local evt_finished = 5

local strip_iterator = function(previous_strips, new_strips)
  local i_prev, i_new = 1, 1 -- the index of the next strips
  local next_p_prev = #previous_strips > 0 and previous_strips[i_prev][1] or nil
  local next_p_new  = #new_strips      > 0 and new_strips     [i_new ][1] or nil
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

local function cond_is_opaque(image_data, x, y, _)
  return select(4, image_data:getPixel(x, y)) ~= 0
end

local function same_color(image_data, x1, y1, x2, y2)
    local color1 = {image_data:getPixel(x1, y1)}
    local color2 = {image_data:getPixel(x2, y2)}
    return color1[1] == color2[1] and
           color1[2] == color2[2] and
           color1[3] == color2[3] and
           color1[4] == color2[4]
end

local function cond_same_color(image_data, x, y, first_x)
  if first_x then
    return same_color(image_data, x, y, first_x, y)
  else
    return select(4, image_data:getPixel(x, y)) ~= 0
  end
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

  if mx < 0 or mx >= w or my < 0 or my >= h then return nil end
  if not cond_is_opaque(img, mx, my) then return nil end

  -- The initial set of strips
  local strips = find_strips(img, my, 0, w - 1, cond_is_opaque)
  for _, strip in ipairs(strips) do
    create_strip_node(my, strip)
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
      local new_strips = find_strips(img, py, 0, w - 1, cond_is_opaque)
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

local function collect_chunks(img, x, y, w, h, condition, states)
  local img_w, img_h = img:getWidth(), img:getHeight()

  -- Move x and y to the upper left corner
  if w < 0 then
    x = x - w
    w = -w
  end
  if h < 0 then
    y = y - h
    h = -h
  end

  if x < 0 then
    w = w + x
    x = 0
  end
  if y < 0 then
    h = h + y
    y = 0
  end

  -- Limit bounds to image bounds
  w = math.max(0, math.min(img_w - x, w))
  h = math.max(0, math.min(img_h - y, h))

  if x >= img_w or y >= img_h or w <= 0 or h <= 0 then
    return {}
  end

  local chunks = {}
  local previous_strips = {}
  for scan_y=y,y + h - 1 do
    local candidate_strips = find_strips(img, scan_y, x, x + w - 1, condition)
    local new_strips = {}
    for _,strip in ipairs(candidate_strips) do
      if strip[2] >= x and strip[1] < x + w then
        -- Restrict strip to rectangle
        strip[1] = math.max(x, strip[1])
        strip[2] = math.min(x + w - 1, strip[2])
        table.insert(new_strips, create_strip_node(scan_y, strip))
      end
    end

    local co = coroutine.create(strip_iterator)
    local _, event, strip = coroutine.resume(co, previous_strips, new_strips)
    local state = states[1]
    local prev_strip, new_strip -- temp variable
    local abandoned = {} -- strips that need to be checked for connections to
                         -- remaining strips
    while event ~= evt_finished do
      state, prev_strip, new_strip = state(event, strip, abandoned,
                                           prev_strip, new_strip)
      _, event, strip = coroutine.resume(co)
    end

    -- Check if the abandoned previous strips are reachable from new strips
    if #abandoned > 0 then
      local seen_strips = {}
      local open_strips = {}
      for _,strip in ipairs(new_strips) do table.insert(open_strips, strip) end
      while #open_strips > 0 do
        local strip = table.remove(open_strips)
        seen_strips[strip] = true
        for _,connected_strip in ipairs(strip.neighbors) do
          if not seen_strips[connected_strip] then
            table.insert(open_strips, connected_strip)
          end
        end
      end

      for _,strip in pairs(abandoned) do
        if not seen_strips[strip] then table.insert(chunks, strip) end
      end
    end

    previous_strips = new_strips
  end
  for _, strip in pairs(previous_strips) do
    table.insert(chunks, strip)
  end

  local rects = {}
  local seen_strips = {}
  for _,strip in ipairs(chunks) do
    local open_strips = {strip}
    if not seen_strips[strip] then
      local chunk = {min_x = strip[1], max_x = strip[2], min_y = strip.y, max_y = strip.y}
      while #open_strips > 0 do
        local strip = table.remove(open_strips)

        -- expand the result chunk
        chunk.min_y = math.min(strip.y, chunk.min_y)
        chunk.max_y = math.max(strip.y, chunk.max_y)
        chunk.min_x = math.min(strip[1], chunk.min_x)
        chunk.max_x = math.max(strip[2], chunk.max_x)

        seen_strips[strip] = true
        for _,connected_strip in ipairs(strip.neighbors) do
          if not seen_strips[connected_strip] then
            table.insert(open_strips, connected_strip)
          end
        end
      end
      table.insert(rects, {
        x = chunk.min_x,
        y = chunk.min_y,
        w = 1 + chunk.max_x - chunk.min_x,
        h = 1 + chunk.max_y - chunk.min_y,
      })
    end
  end

  return rects
end

-- Returns a table of rectangles which enclose all chunks of the same color
-- in the given rectangle
function analysis.palette(image_or_imagedata, x, y, w, h)
  local img
  if image_or_imagedata:type() == "Image" then
    img = image_or_imagedata:getData()
  else
    assert(image_or_imagedata:type() == "ImageData")
    img = image_or_imagedata
  end

  local function strip_same_color(s1, s2)
    return same_color(img,  s1[1], s1.y, s2[1], s2.y)
  end

  local states = {}
  states[1] = function(event, strip)
    if event == evt_prev_strip_starts then
      return states[3], strip
    elseif event == evt_new_strip_starts then
      return states[2], nil, strip
    else error("did not expect event " .. event) end
  end

  states[2] = function(event, strip, _, _, new_strip)
    if event == evt_new_strip_ends then
      return states[1]
    elseif event == evt_prev_strip_starts then
      if strip_same_color(strip, new_strip) then
        connect_nodes(strip, new_strip)
        return states[4], strip, new_strip
      else
        return states[6], strip, new_strip
      end
    else error("did not expect event " .. event) end
  end

  states[3] = function(event, strip, abandoned_strips, prev_strip)
    if event == evt_prev_strip_ends then
      table.insert(abandoned_strips, strip)
      return states[1]
    elseif event == evt_new_strip_starts then
      if strip_same_color(prev_strip, strip) then
        connect_nodes(prev_strip, strip)
        return states[4], prev_strip, strip
      else
        return  states[6], prev_strip, strip
      end
    else error("did not expect event " .. event) end
  end

  states[4] = function(event, _, _, prev_strip, new_strip)
    if event == evt_prev_strip_ends then
      return states[2], nil, new_strip
    elseif event == evt_new_strip_ends then
      return states[5], prev_strip
    else error("did not expect event " .. event) end
  end

  states[5] = function(event, strip, _, prev_strip, _)
    if event == evt_new_strip_starts then
      if strip_same_color(prev_strip, strip) then
        connect_nodes(strip, prev_strip)
      end
      return states[4], prev_strip, strip
    elseif event == evt_prev_strip_ends then
      return states[1]
    else error("did not expect event " .. event) end
  end

  states[6] = function(event, strip, abandoned_strips, prev_strip, new_strip)
    if event == evt_new_strip_ends then
      return states[3], prev_strip
    elseif event == evt_prev_strip_ends then
      table.insert(abandoned_strips, prev_strip)
      return states[2], nil, new_strip
    else error("did not expect event " .. event) end
  end

  local rects = collect_chunks(img, x, y, w, h, cond_same_color, states)

  -- Sort the quads
  local function sort(quad_a, quad_b)
    return quad_a.y < quad_b.y or quad_a.y == quad_b.y and quad_a.x < quad_b.x
  end
  table.sort(rects, sort)
  return rects
end

-- Returns a table of rectangles which enclose all opaque chunks in the
-- given rectangle
function analysis.enclosed_chunks(image_or_imagedata, x, y, w, h)
  local img
  if image_or_imagedata:type() == "Image" then
    img = image_or_imagedata:getData()
  else
    assert(image_or_imagedata:type() == "ImageData")
    img = image_or_imagedata
  end

  local states = {}
  states[1] = function(event, strip)
    if event == evt_prev_strip_starts then
      return states[3], strip
    elseif event == evt_new_strip_starts then
      return states[2], nil, strip
    else error("did not expect event " .. event) end
  end

  states[2] = function(event, strip, _, _, new_strip)
    if event == evt_new_strip_ends then
      return states[1]
    elseif event == evt_prev_strip_starts then
      connect_nodes(strip, new_strip)
      return states[4], strip, new_strip
    else error("did not expect event " .. event) end
  end

  states[3] = function(event, strip, abandoned_strips, prev_strip)
    if event == evt_prev_strip_ends then
      table.insert(abandoned_strips, strip)
      return states[1]
    elseif event == evt_new_strip_starts then
      connect_nodes(prev_strip, strip)
      return states[4], prev_strip, strip
    else error("did not expect event " .. event) end
  end

  states[4] = function(event, _, _, prev_strip, new_strip)
    if event == evt_prev_strip_ends then
      return states[2], nil, new_strip
    elseif event == evt_new_strip_ends then
      return states[5], prev_strip
    else error("did not expect event " .. event) end
  end

  states[5] = function(event, strip, _, prev_strip, _)
    if event == evt_new_strip_starts then
      connect_nodes(strip, prev_strip)
      return states[4], prev_strip, strip
    elseif event == evt_prev_strip_ends then
      return states[1]
    else error("did not expect event " .. event) end
  end

  return collect_chunks(img, x, y, w, h, cond_is_opaque, states)

end

return analysis
