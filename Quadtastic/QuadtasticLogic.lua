local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local Dialog = require(current_folder.. ".Dialog")
local QuadExport = require(current_folder.. ".QuadExport")
local table = require(current_folder.. ".tableplus")
local libquadtastic = require(current_folder.. ".libquadtastic")
local common = require(current_folder.. ".common")

-- Shared library
local lfs = require("lfs")

local function find_lua_file(filepath)
  return string.gsub(filepath, "%.(%w+)$", ".lua")
end

local QuadtasticLogic = {}

-- These methods will be replaced while testing,
-- so that user interaction can be simulated easily
QuadtasticLogic.show_dialog = Dialog.show_dialog
QuadtasticLogic.query = Dialog.query
QuadtasticLogic.open_file = Dialog.open_file
QuadtasticLogic.save_file = Dialog.save_file

function QuadtasticLogic.transitions(interface) return {
  -- luacheck: no unused args

  quit = function(app, data)
    local result = QuadtasticLogic.show_dialog("Do you really want to quit?", {"Yes", "No"})
    if result == "Yes" then
      return 0
    end
  end,

  rename = function(app, data, quads)
    if not quads then quads = data.selection:get_selection() end
    if #quads == 0 then return
    elseif #quads > 1 then
      QuadtasticLogic.show_dialog("You cannot rename more than one element at once.")
      return
    else
      local quad = quads[1]
      local current_keys = {table.find_key(data.quads, quad)}
      local old_key = table.concat(current_keys, ".")
      local new_key = old_key
      local ret
      ret, new_key = QuadtasticLogic.query(
        "Name:", new_key, {escape = "Cancel", enter = "OK"})

      local function replace(tab, old_keys, new_keys, element)
        -- Make sure that the new keys form a valid path, that is, all but the
        -- last key must be tables that are not quads
        local current_table = tab
        for i=1,#new_keys do
          if type(current_table) == "table" and libquadtastic.is_quad(current_table) then
            local keys_so_far = table.concat(new_keys, ".", 1, i)
            QuadtasticLogic.show_dialog(string.format(
              "The element %s is a quad, and can therefore not have nested quads.",
              keys_so_far))
            return
          end
          -- This does intentionally not check the very last key, since it is
          -- fine when that one is a quad
          if i < #new_keys then
            local next_key = new_keys[i]
            -- Create a new empty table if necessary
            if not current_table[next_key] then
              current_table[next_key] = {}
            end
            current_table = current_table[next_key]
          end
        end

        -- Remove the entry under the old key
        table.set(data.quads, nil, unpack(old_keys))
        -- Add the entry under the new key
        table.set(data.quads, element, unpack(new_keys))
      end

      if ret == "OK" then
        if new_key == old_key then return end

        local new_keys = {}
        for k in string.gmatch(new_key, "([^.]+)") do
          table.insert(new_keys, k)
        end
        -- Check if that key already exists
        if table.get(data.quads, unpack(new_keys)) then
          local action = QuadtasticLogic.show_dialog(
            string.format("The element '%s' already exists.", new_key),
            {"Cancel", "Swap", "Replace"})
          if action == "Swap" then
            local old_value = table.get(data.quads, unpack(new_keys))
            table.set(data.quads, old_value, unpack(current_keys))
            table.set(data.quads, quad, unpack(new_keys))
          elseif action == "Replace" then
            replace(data.quads, current_keys, new_keys, quad)
          else -- Cancel option
            return
          end
        else
          replace(data.quads, current_keys, new_keys, quad)
        end

        -- Set the focus of the quad list to the renamed quad
        interface.move_quad_into_view(data.quad_scrollpane_state, quad)
      end
    end
  end,

  sort = function(app, data, quads)
    if not quads then quads = data.selection:get_selection() end
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
        QuadtasticLogic.show_dialog("You cannot sort quads across different groups")
        return
      else
        individual_keys[v] = key
      end
      if type(key) == "number" then
        numeric_quads = numeric_quads + 1
      end
    end
    if numeric_quads == 0 then
      QuadtasticLogic.show_dialog("Only unnamed quads can be sorted")
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
    if not quads then quads = data.selection:get_selection() end
    if #quads == 0 then
      return
    else
      data.selection:deselect(quads)
      for _,quad in ipairs(quads) do
        local keys = {table.find_key(data.quads, quad)}
        if #keys > 0 then
          table.set(data.quads, nil, unpack(keys))
          -- Remove the element from the list of collapsed groups. This will have
          -- no effect if the element was a quad.
          data.collapsed_groups[quad] = nil
        end
      end
    end
  end,

  create = function(app, state, new_quad)
    -- If a group is currently selected, add the new quad to that group
    -- If a quad is currently selected, add the new quad to the same
    -- group.
    local selection = state.selection:get_selection()
    if #selection == 1 then
      local keys = {table.find_key(state.quads, selection[1])}
      if libquadtastic.is_quad(selection[1]) then
        -- Remove the last key so that the new quad is added to the
        -- group that contains the currently selected quad
        table.remove(keys)
      end
      local group = table.get(state.quads, unpack(keys))
      table.insert(group, new_quad)
    else
      -- Just add it to the root
      table.insert(state.quads, new_quad)
    end
    state.selection:set_selection({new_quad})
    interface.move_quad_into_view(state.quad_scrollpane_state, new_quad)
  end,

  move_quads = function(app, data, quads, dx, dy, img_w, img_h)
    if not quads then quads = data.selection:get_selection() end
    if #quads == 0 then return end

    for _,quad in ipairs(quads) do
      if libquadtastic.is_quad(quad) then
        quad.x = math.max(0, math.min(img_w - quad.w, quad.x + dx))
        quad.y = math.max(0, math.min(img_h - quad.h, quad.y + dy))
      end
    end
  end,

  -- Resizes all given quads by the given amount, in the given direction.
  -- The direction is a string that identifies which side or corner is
  -- changed, and should be a table containing the keys n, e, s, w when
  -- the quads are resized in the respective direction. For example, if a
  -- quad is resized at the south-east corner, then direction.s and direction.e
  -- should be set to `true`. All other keys should be `false` or `nil`.
  -- The image dimensions are needed so that the position and size of the quads
  -- can be restricted.
  resize_quads = function(app, data, quads, direction, dx, dy, img_w, img_h)
    dx, dy = dx or 0, dy or 0
    -- All quads have their position in the upper left corner, and their
    -- size extends to the lower right corner.

    -- The change in position to be applied to all quads
    local dpx, dpy = 0, 0

    -- The change in size to be applied to all quads
    local dw, dh = 0, 0

    if direction.n and dy ~= 0 then
      dpy = dy -- move the quad by the given amount
      dh = -dy -- but reduce the height accordingly
    elseif direction.s and dy ~= 0 then
      dh = dy
    end

    if direction.w and dx ~= 0 then
      dpx = dx -- move the quad by the given amount
      dw = -dx -- but reduce the height accordingly
    elseif direction.e and dx ~= 0 then
      dw = dx
    end

    -- Now apply all changes
    for _,quad in pairs(quads) do
      -- Resize the quads, but restrict their dimensions and position
      quad.x = math.max(0, math.min(img_w, quad.x + math.min(quad.w - 1, dpx)))
      quad.y = math.max(0, math.min(img_h, quad.y + math.min(quad.h - 1, dpy)))
      quad.w = math.max(1, math.min(img_w - quad.x, quad.w + dw))
      quad.h = math.max(1, math.min(img_h - quad.y, quad.h + dh))
    end
  end,

  group = function(app, data, quads)
    if not quads then quads = data.selection:get_selection() end
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
        QuadtasticLogic.show_dialog("You cannot group quads across different groups")
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

    -- Focus quad list on new group
    interface.move_quad_into_view(data.quad_scrollpane_state, new_group)
  end,

  ungroup = function(app, data, quads)
    if not quads then quads = data.selection:get_selection() end
    if #quads == 0 then return end
    if #quads > 1 then
      QuadtasticLogic.show_dialog("You can only break up one group at a time")
      return
    end
    if libquadtastic.is_quad(quads[1]) then
      return
    end

    local group = quads[1]
    local keys = {table.find_key(data.quads, group)}
    -- Remove the last element of the key list to get the parent's keys
    local group_key = table.remove(keys)
    local parent_keys = keys
    local parent = table.get(data.quads, unpack(parent_keys))

    -- Check that we can break up this group by making sure that the parent
    -- element and the group don't have any conflicting keys
    local ignore_numeric_clash = false
    for k,_ in pairs(group) do
      if parent[k] and k ~= group_key then
        local parent_name
        for _,v in ipairs(parent_keys) do
          parent_name = (parent_name and (parent_name .. ".") or "") .. tostring(v)
        end
        if type(k) == "number" and not ignore_numeric_clash then
          local ret = QuadtasticLogic.show_dialog(string.format([[
Breaking up this group will change some numeric indices of the
elements in that group. In particular, the index %d already exists%s.
Proceed anyways?]],
            k, (parent_name and " in group "..parent_name) or ""),
            {"Yes", "No"})
          if ret == "Yes" then
            ignore_numeric_clash = true
          else
            return
          end
        else
          QuadtasticLogic.show_dialog(string.format([[
This group cannot be broken up since there is already an element called '%s'%s.]],
            k, (parent_name and " in group "..parent_name) or ""))
          return
        end
      end
    end

    -- Remove group from parent
    parent[group_key] = nil
    data.collapsed_groups[group_key] = nil
    for k,v in pairs(group) do
      if type(k) == "number" then
        table.insert(parent, v)
      else
        parent[k] = v
      end
    end
  end,

  offer_reload = function(app, data)
    local image_path = data.quads._META.image_path
    local ret = QuadtasticLogic.show_dialog(
      string.format("The image %s has changed on disk.\nDo you want to reload it?", image_path),
      {enter="Yes", escape="No"})
    if ret == "Yes" then
      app.quadtastic.load_image(image_path)
    end
  end,

  new = function(app, data)
    data.quads = {
      _META = {}
    }
    data.quadpath = nil -- path to the file containing the quad definitions
    data.image = nil -- the loaded image
    interface.reset_view(data)
    -- Reset list of collapsed groups
    data.collapsed_groups = {}

    data.file_timestamps = {}

    data.toolstate = { type = "create"}
  end,

  save = function(app, data, callback)
    if not data.image then
      QuadtasticLogic.show_dialog("Load an image first")
      return
    elseif not data.quadpath or data.quadpath == "" then
      app.quadtastic.save_as()
    else
      QuadExport.export(data.quads, data.quadpath)
      if callback then callback(data.quadpath) end
    end
  end,

  save_as = function(app, data, callback)
    local ret, filepath = QuadtasticLogic.save_file(data.quadpath)
    if ret == "Save" then
      data.quadpath = filepath
      app.quadtastic.save(callback)
    end
  end,

  choose_quad = function(app, data, basepath)
    if not basepath then basepath = "/Users/moritz/Projects/Quadtastic/Quadtastic/res" end
    local ret, filepath = QuadtasticLogic.open_file(basepath)
    if ret == "Open" then
      app.quadtastic.load_quad(filepath)
    end
  end,

  load_quad = function(app, data, filepath)
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
      -- Reset list of collapsed groups
      data.collapsed_groups = {}
      if not data.quads._META then data.quads._META = {} end
      local metainfo = libquadtastic.get_metainfo(data.quads)
      if metainfo.image_path then
        app.quadtastic.load_image(metainfo.image_path)
      end

      -- Insert new file into list of recently loaded files
      -- Remove duplicates from recent files
      local remaining_files = {filepath}
      for _,v in ipairs(data.settings.recent) do
        if v ~= filepath then
          table.insert(remaining_files, v)
        end
      end
      data.settings.recent = remaining_files
      interface.store_settings(data.settings)
    else
      QuadtasticLogic.show_dialog(string.format("Could not load quads: %s", more))
    end
  end,

  choose_image = function(app, data, basepath)
    if not basepath and data.quads and data.quads._META then
      basepath = data.quads._META.image_path
    end
    local ret, filepath = QuadtasticLogic.open_file(basepath)
    if ret == "Open" then
      app.quadtastic.load_image(filepath)
    end
  end,

  load_image = function(app, data, filepath)
    local success, more = pcall(common.load_image, filepath)

    -- success, more = pcall(love.graphics.newImage, data)
    if success then
      data.image = more
      data.quads._META.image_path = filepath
      data.file_timestamps.image_loaded = lfs.attributes(filepath, "modification")
      data.file_timestamps.image_latest = data.file_timestamps.image_loaded
      interface.reset_view(data)
      -- Try to read a quad file
      local quadfilename = find_lua_file(filepath)
      if not data.quadpath and lfs.attributes(quadfilename) then
        local should_load = QuadtasticLogic.show_dialog(string.format(
          "We found a quad file in %s.\nWould you like to load it?", quadfilename),
          {enter = "Yes", escape = "No"}
        )
        if should_load == "Yes" then
          app.quadtastic.load_quad(quadfilename)
        end
      end
    else
      QuadtasticLogic.show_dialog(string.format("Could not load image: %s", more))
    end
  end,
}
end

return QuadtasticLogic