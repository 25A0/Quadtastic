local Text = {}

local unpack = unpack or table.unpack

Text.min_width = function(state, text)
  return state.style.font and state.style.font:getWidth(text)
end

-- Returns a table of lines, none of which exceed the given width.
-- Returns a table with the original text if width is 0 or nil.
function Text.break_at(state, text, width)
  if not width or width <= 0 then return {text} end

  local lines = {}
  local line = {}
  local line_length = 0
  local separators = {" ", "-", "/", "\\", "."}
  local function complete_line(separator)
    local new_line = table.concat(line, separator)
    table.insert(lines, new_line)
  end

  local function break_up(chunk, sep_index)
    local separator = separators[sep_index]
    local separator_width = Text.min_width(state, separator)
    for word in string.gmatch(chunk, string.format("[^%s]+", separator)) do
      local wordlength = Text.min_width(state, word)
      if wordlength > width then
        -- Try to break at other boundaries
        if sep_index == #separators then
          print(string.format("Warning: %s is too long for one line", chunk))
        else
          break_up(word, sep_index + 1)
        end
      elseif line_length + wordlength > width then
        complete_line(separator)
        line, line_length = {word}, wordlength
      else
        table.insert(line, word)
        line_length = line_length + wordlength + separator_width
      end
    end
    -- Add any outstanding words
    if #line > 0 then
      complete_line(separator)
      line, line_length = {}, 0
    end
  end

  for l in string.gmatch(text, "[^\n]+") do
    break_up(l, 1)
  end
  return lines
end

Text.draw = function(state, x, y, w, h, text, options)
  x = x or state.layout.next_x
  y = y or state.layout.next_y

  local textwidth = Text.min_width(state, text)
  local textheight = 16
  w = w or textwidth
  h = h or textheight

  if options then
    -- center alignment
    if options.alignment_h == ":" then
      x = x + w/2 - textwidth /2

    -- right alignment
    elseif options.alignment_h == ">" then
      x = x + w - textwidth
    end

    -- vertically aligned to the center
    if options.alignment_v == "-" then
      y = y + h/2 - textheight/2

    -- aligned to the bottom
    elseif options.alignment_v == "v" then
      y = y + h - textheight
    end
  end

  x = math.floor(x)
  y = math.floor(y)
  love.graphics.setFont(state.style.font)
  -- Print Text
  if options and options.font_color then
    love.graphics.setColor(unpack(options.font_color))
  end
  love.graphics.print(text or "", x, y)
end

return Text