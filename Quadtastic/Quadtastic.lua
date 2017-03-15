local State = require("Quadtastic/State")
local Dialog = require("Quadtastic/Dialog")
local QuadExport = require("Quadtastic/QuadExport")

local imgui = require("Quadtastic/imgui")
local Button = require("Quadtastic/Button")
local Inputfield = require("Quadtastic/Inputfield")
local Label = require("Quadtastic/Label")
local Frame = require("Quadtastic/Frame")
local Layout = require("Quadtastic/Layout")
local Window = require("Quadtastic/Window")
local Scrollpane = require("Quadtastic/Scrollpane")
local Tooltip = require("Quadtastic/Tooltip")
local ImageEditor = require("Quadtastic/ImageEditor")
local QuadList = require("Quadtastic/QuadList")
local libquadtastic = require("Quadtastic/libquadtastic")
local table = require("Quadtastic/tableplus")

local lfs = require("lfs")

local function find_lua_file(filepath)
  return string.gsub(filepath, "%.(%w+)$", ".lua")
end

local Quadtastic = State("quadtastic",
  nil,
  -- initial data
  {
    filepath = "Quadtastic/res/style.png", -- the path to the file that we want to edit
    quadpath = "", -- path to the file containing the quad definitions
    image = nil, -- the loaded image
    display = {
      zoom = 1, -- additional zoom factor for the displayed image
    },
    scrollpane_state = nil,
    quad_scrollpane_state = nil,
    quads = {},
    selection = {},
  })

-- -------------------------------------------------------------------------- --
-- Selection handling
-- -------------------------------------------------------------------------- --

Quadtastic.is_selected = function(self, v)
  return self.selection[v]
end

-- Clear the current selection
Quadtastic.clear_selection = function(self)
  self.selection = {}
end

-- Repace the current selection by the given selection
Quadtastic.set_selection = function(self, quads)
  Quadtastic.clear_selection(self)
  Quadtastic.select(self, quads)
end

-- Add the given quads or table of quads to the selection
Quadtastic.select = function(self, quads)
  for _, v in ipairs(quads) do
    self.selection[v] = true
  end
end

-- Remove the given quads from the selection.
-- If a table of quads is passed, the table and all contained quads will be
-- removed from the selection.
Quadtastic.deselect = function(self, quads)
  for _, v in ipairs(quads) do
    self.selection[v] = nil
  end
end

Quadtastic.get_selection = function(self)
  return table.keys(self.selection)
end

Quadtastic.count_selection = function(self) return #self.selection end

-- -------------------------------------------------------------------------- --

function Quadtastic.reset_view(state)
  state.scrollpane_state = Scrollpane.init_scrollpane_state()
  state.display.zoom = 1
  if state.image then
    Scrollpane.set_focus(state.scrollpane_state, {
      x = 0, y = 0, 
      w = state.image:getWidth(), h = state.image:getHeight()
    }, "immediate")
  end
end

-- -------------------------------------------------------------------------- --
--                           TRANSITIONS
-- -------------------------------------------------------------------------- --
-- Transitions are initialized now since they need to call some of the functions
-- defined above.

Quadtastic.transitions = {
  export = function(app, data)
    if not data.image then
      Dialog.show_dialog("Load an image first")
      return
    elseif not data.quadpath or data.quadpath == "" then
      local ret, path = Dialog.query(
        "Where should the quad file be stored?", 
        find_lua_file(data.filepath),
        {"Cancel", "OK"})
      if ret == "OK" then
        data.quadpath = path
      else return end
    end
    QuadExport.export(data.quads, data.quadpath)
  end,

  rename = function(app, data, quads)
    if #quads == 0 then return
    elseif #quads > 1 then
      Dialog.show_dialog("You cannot rename more than one quad at once.")
      return
    else
      local quad = quads[1]
      local current_keys = {table.find_key(data.quads, quad)}
      local old_key = table.remove(current_keys)
      local new_key
      if type(old_key) == "number" then 
        new_key = ""
      else 
        new_key = old_key
      end
      local ret
      ret, new_key = Dialog.query("Name:", new_key, {"Cancel", "OK"})
      if ret == "OK" then
        -- Remove the entry under the old key
        local parent = table.get(data.quads, unpack(current_keys))
        parent[old_key] = nil
        -- Add the entry under the new key
        parent[new_key] = quad
      end
    end
  end,

  sort = function(app, data, quads)
    if #quads == 0 then return end
    -- Find the shared parent of the selected quads.
    local first_keys = {table.find_key(data.quads, quads[1])}
    -- Remove the last element of the key list to get the shared key
    table.remove(first_keys)
    local shared_keys = first_keys
    local shared_parent = table.get(data.quads, unpack(shared_keys))
    local individual_keys = {}
    local numeric_quads = 0
    for _,v in ipairs(quads) do
      -- This is an N^2 search and it sucks, but it probably won't matter.
      local key = table.find_key(shared_parent, v)
      if not key then
        Dialog.show_dialog("You cannot sort quads across different groups")
        return
      else
        individual_keys[v] = key
      end
      if type(key) == "number" then
        numeric_quads = numeric_quads + 1
      end
    end
    if numeric_quads == 0 then
      Dialog.show_dialog("Only unnamed quads can be sorted")
      return
    end

    -- Filter out non-quad elements and elements with non-numeric keys
    local new_group = {}
    for _,v in ipairs(quads) do
      if libquadtastic.is_quad(v) and type(individual_keys[v]) == "number" then
        table.insert(new_group, v)
      end
    end

    -- Sort the quads
    local function sort(quad_a, quad_b)
      return quad_a.y < quad_b.y or quad_a.y == quad_b.y and quad_a.x < quad_b.x
    end
    table.sort(new_group, sort)

    -- Remove the quads from their parent
    for _,v in ipairs(new_group) do
      local key = individual_keys[v]
      -- Remove the element from the shared parent
      shared_parent[key] = nil
    end

    -- Now add the quads to the parent in order
    for _,v in ipairs(new_group) do
      table.insert(shared_parent, v)
    end
  end,

  remove = function(app, data, quads)
    if #quads == 0 then
      return
    else
      Quadtastic.deselect(data, quads)
      for _,quad in ipairs(quads) do
        local keys = {table.find_key(data.quads, quad)}
        if #keys > 0 then
          table.set(data.quads, nil, unpack(keys))
        end
      end
    end
  end,

  group = function(app, data, quads)
    if #quads == 0 then return end
    -- Find the shared parent of the selected quads.
    local first_keys = {table.find_key(data.quads, quads[1])}
    -- Remove the last element of the key list to get the shared key
    table.remove(first_keys)
    local shared_keys = first_keys
    local shared_parent = table.get(data.quads, unpack(shared_keys))
    local individual_keys = {}
    for _,v in ipairs(quads) do
      -- This is an N^2 search and it sucks, but it probably won't matter.
      local key = table.find_key(shared_parent, v)
      if not key then
        Dialog.show_dialog("You cannot group quads across different groups")
        return
      else
        individual_keys[v] = key
      end
    end

    -- Do the second pass, this time with destructive actions
    local new_group = {}
    local num_index = 1 -- a counter for numeric indices
    for _,v in ipairs(quads) do
      local key = individual_keys[v]
      -- Remove the element from the shared parent
      shared_parent[key] = nil
      -- No point in preserving a numeric key
      if type(key) == "number" then 
        key = num_index
        num_index = num_index + 1
      end
      new_group[key] = v
    end
    table.insert(shared_parent, new_group)
  end,

  zoom_in = function(app, data)
    data.display.zoom = math.min(12, data.display.zoom + 1)
  end,

  zoom_out = function(app, data)
    data.display.zoom = math.max(1, data.display.zoom - 1)
  end,

  load_quads_from_path = function(app, data, filepath)
    local success, more = pcall(function()
      local filehandle, err = io.open(filepath, "r")
      if err then 
        error(err)
      end
  
      if filehandle then
        filehandle:close()
        local quads = loadfile(filepath)()
        local quadpath = filepath
        return {quads, quadpath}
      end
    end)
  
    if success then
      data.quads, data.quadpath = unpack(more)
    else
      Dialog.show_dialog(string.format("Could not load quads: %s", more))
    end

  end,
    
  load_image_from_path = function(app, data, filepath)
    local success, more = pcall(function()
      local filehandle, err = io.open(filepath, "rb")
      if err then 
        error(err)
      end
      local data = filehandle:read("*a")
      filehandle:close()
      local imagedata = love.image.newImageData(
        love.filesystem.newFileData(data, 'img', 'file'))
      return love.graphics.newImage(imagedata)
    end)
  
    -- success, more = pcall(love.graphics.newImage, data)
    if success then
      data.image = more
      data.filepath = filepath
      Quadtastic.reset_view(data)
      -- Try to read a quad file
      local quadfilename = find_lua_file(data.filepath)
      if lfs.attributes(quadfilename) then
        local should_load = Dialog.show_dialog(string.format("We found a quad file in %s. Would you like to load it?", quadfilename), {"Yes", "No"})
        if should_load == "Yes" then
          app.quadtastic.load_quads_from_path(quadfilename)
        end
      end
    else
      Dialog.show_dialog(string.format("Could not load image: %s", more))
    end
  end,
  
}

-- -------------------------------------------------------------------------- --
--                           DRAWING
-- -------------------------------------------------------------------------- --
Quadtastic.draw = function(app, state, gui_state)
  local w, h = gui_state.transform:unproject_dimensions(
    love.graphics.getWidth(), love.graphics.getHeight()
  )
  love.graphics.clear(138, 179, 189)
  do Window.start(gui_state, 0, 0, w, h, {margin = 2, active = true, borderless = true})

    do Layout.start(gui_state)
      Label.draw(gui_state, nil, nil, nil, nil, "Image:")
      Layout.next(gui_state, "-", 2)

      state.filepath = Inputfield.draw(gui_state, nil, nil, gui_state.layout.max_w - 34, nil, state.filepath)
      Layout.next(gui_state, "-", 2)

      local pressed, active = Button.draw(gui_state, nil, nil, nil, nil, "Load")
      if pressed then
        app.quadtastic.load_image_from_path(state.filepath)
      end
      Tooltip.draw(gui_state, "Who's a good boy??")
    end Layout.finish(gui_state, "-")

    Layout.next(gui_state, "|", 2)

    do Layout.start(gui_state)
      Label.draw(gui_state, nil, nil, nil, nil, "Quads:")
      Layout.next(gui_state, "-", 2)

      state.quadpath = Inputfield.draw(gui_state, nil, nil, gui_state.layout.max_w - 34, nil, state.quadpath or "")
      Layout.next(gui_state, "-", 2)

      local pressed, active = Button.draw(gui_state, nil, nil, nil, nil, "Load")
      if pressed then
        app.quadtastic.load_quads_from_path(state.quadpath)
      end
      Tooltip.draw(gui_state, "Who's a good boy??")
    end Layout.finish(gui_state, "-")

    Layout.next(gui_state, "|", 2)

    do Layout.start(gui_state, nil, nil, nil, gui_state.layout.max_h - 30)
      do Frame.start(gui_state, nil, nil, gui_state.layout.max_w - 160, nil)
        if state.image then
          ImageEditor.draw(gui_state, state)
        else
          -- Put a label in the center of the frame
          local y = gui_state.layout.max_h / 2 - gui_state.style.font:getHeight()
          Label.draw(gui_state, nil, y, gui_state.layout.max_w, nil,
                     "no image :(", {alignment = ":"})
        end
      end Frame.finish(gui_state)

      Layout.next(gui_state, "-", 2)

      do Layout.start(gui_state, nil, nil, gui_state.layout.max_w - 21)
        -- Draw the list of quads
        local clicked, hovered = 
          QuadList.draw(gui_state, state, nil, nil, nil, gui_state.layout.max_h - 19,
                        state.selection, state.hovered)
        if clicked then
          local new_quads = {clicked}
          -- If shift was pressed, select all quads between the clicked one and
          -- the last quad that was clicked
          if gui_state.input and
            (imgui.is_key_pressed(gui_state, "lshift") or
             imgui.is_key_pressed(gui_state, "rshift")) and
            state.previous_clicked
          then
            -- Make sure that the new quad and the last quads are child of the
            -- same parent
            local previous_keys = {table.find_key(state.quads, state.previous_clicked)}
            local new_keys = {table.find_key(state.quads, clicked)}
            -- Remove the last keys since they will likely differ
            local previous_key = table.remove(previous_keys)
            local new_key = table.remove(new_keys)
            if table.shallow_equals(previous_keys, new_keys) then
              if previous_key == new_key then
                assert(state.previous_clicked == clicked)
                -- In this case the user clicked the same quad twice after
                -- pressing shift. We don't need to take any extra steps.
              else
                -- We don't know the exact order in which quads appear. So we
                -- iterate through the quads of the shared parent. Once we
                -- encounter either the new or the previous quad, we start
                -- adding all intermediate quads to a list that will then be
                -- selected.
                local parent = table.get(state.quads, unpack(new_keys))
                local found_previous = false
                local found_new = false
                -- Clear the list of new quads to make the accumulation process
                -- a bit easier
                new_quads = {}
                for k,v in pairs(parent) do
                  if v == clicked then
                    found_new = true
                  end
                  if v == state.previous_clicked then
                    found_previous = true
                  end
                  if found_new or found_previous then
                    table.insert(new_quads, v)
                  end
                  if found_new and found_previous then break end
                end
              end
            end
          else
            state.previous_clicked = clicked
          end

          if gui_state.input and
            (imgui.is_key_pressed(gui_state, "lctrl") or
             imgui.is_key_pressed(gui_state, "rctrl"))
          then
            if #new_quads == 1 and Quadtastic.is_selected(state, clicked) then
              Quadtastic.deselect(state, new_quads)
            else
              Quadtastic.select(state, new_quads)
            end
          else
            Quadtastic.set_selection(state, new_quads)
          end
        end
        state.hovered = hovered

        Layout.next(gui_state, "|")

        if Button.draw(gui_state, nil, nil, gui_state.layout.max_w, nil, "EXPORT", nil, {alignment = ":"}) then
          app.quadtastic.export()
        end
      end Layout.finish(gui_state, "|")

      Layout.next(gui_state, "-", 2)

      -- Draw button column
      do Layout.start(gui_state)
        if Button.draw(gui_state, nil, nil, nil, nil, nil, gui_state.style.buttonicons.rename) then
          app.quadtastic.rename(Quadtastic.get_selection(state))
        end
        Tooltip.draw(gui_state, "Rename")
        Layout.next(gui_state, "|")
        if Button.draw(gui_state, nil, nil, nil, nil, nil, gui_state.style.buttonicons.delete) then
          app.quadtastic.remove(Quadtastic.get_selection(state))
        end
        Tooltip.draw(gui_state, "Delete selected quad(s)")
        Layout.next(gui_state, "|")
        if Button.draw(gui_state, nil, nil, nil, nil, nil, gui_state.style.buttonicons.sort) then
          app.quadtastic.sort(Quadtastic.get_selection(state))
        end
        Tooltip.draw(gui_state, "Sort unnamed quads from top to bottom, left to right")
        Layout.next(gui_state, "|")
        if Button.draw(gui_state, nil, nil, nil, nil, nil, gui_state.style.buttonicons.group) then
          app.quadtastic.group(Quadtastic.get_selection(state))
        end
        Tooltip.draw(gui_state, "Group selected quads")
        Layout.next(gui_state, "|")
        Button.draw(gui_state, nil, nil, nil, nil, nil, gui_state.style.buttonicons.ungroup)
        Tooltip.draw(gui_state, "Ungroup selected quads")
      end Layout.finish(gui_state, "|")
    end Layout.finish(gui_state, "-")

    Layout.next(gui_state, "|", 2)

    do Layout.start(gui_state)
      do
        local pressed = Button.draw(gui_state, nil, nil, nil, nil, nil, 
          gui_state.style.buttonicons.plus)
        if pressed then
          app.quadtastic.zoom_in()
        end
        Tooltip.draw(gui_state, "Zoom in")
      end
      Layout.next(gui_state, "-")
      do
        local pressed = Button.draw(gui_state, nil, nil, nil, nil, nil, 
          gui_state.style.buttonicons.minus)
        if pressed then
          app.quadtastic.zoom_out()
        end
        Tooltip.draw(gui_state, "Zoom out")
      end
    end Layout.finish(gui_state, "-")

  end Window.finish(gui_state, {active = true, borderless = true})

end

return Quadtastic