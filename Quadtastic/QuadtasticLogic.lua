local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local QuadExport = require(current_folder.. ".QuadExport")
local History = require(current_folder.. ".History")
local table = require(current_folder.. ".tableplus")
local libquadtastic = require(current_folder.. ".libquadtastic")
local common = require(current_folder.. ".common")

-- Shared library
local lfs = require("lfs")

local function find_lua_file(filepath)
  return string.gsub(filepath, "%.(%w+)$", ".lua")
end

local QuadtasticLogic = {}

function QuadtasticLogic.transitions(interface) return {
  -- luacheck: no unused args

  quit = function(app, data)
    if not app.quadtastic.proceed_despite_unsaved_changes() then return end
    local result = interface.show_dialog("Do you really want to quit?", {"Yes", "No"})
    if result == "Yes" then
      return 0
    end
  end,

  rename = function(app, data, quads)
    if not quads then quads = data.selection:get_selection() end
    if #quads == 0 then return
    elseif #quads > 1 then
      interface.show_dialog("You cannot rename more than one element at once.")
      return
    else
      local quad = quads[1]
      local current_keys = {table.find_key(data.quads, quad)}
      local old_key = table.concat(current_keys, ".")
      local new_key = old_key
      local ret
      ret, new_key = interface.query(
        "Name:", new_key, {escape = "Cancel", enter = "OK"})

      local function replace(tab, old_keys, new_keys, element)
        -- Make sure that the new keys form a valid path, that is, all but the
        -- last key must be tables that are not quads
        local current_table = tab
        for i=1,#new_keys do
          if type(current_table) == "table" and libquadtastic.is_quad(current_table) then
            local keys_so_far = table.concat(new_keys, ".", 1, i)
            interface.show_dialog(string.format(
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

        local do_action = function()
          -- Remove the entry under the old key
          table.set(data.quads, nil, unpack(old_keys))
          -- Add the entry under the new key
          table.set(data.quads, element, unpack(new_keys))
        end

        local undo_action = function()
          -- Remove the entry under the new key
          table.set(data.quads, nil, unpack(new_keys))
          -- Add the entry under the old key
          table.set(data.quads, element, unpack(old_keys))
        end

        data.history:add(do_action, undo_action)
        do_action()

      end

      if ret == "OK" then
        if new_key == old_key then return end

        local new_keys = {}
        for k in string.gmatch(new_key, "([^.]+)") do
          table.insert(new_keys, k)
        end
        -- Check if that key already exists
        if table.get(data.quads, unpack(new_keys)) then
          local action = interface.show_dialog(
            string.format("The element '%s' already exists.", new_key),
            {"Cancel", "Swap", "Replace"})
          if action == "Swap" then
            local old_value = table.get(data.quads, unpack(new_keys))
            local do_action = function()
              table.set(data.quads, old_value, unpack(current_keys))
              table.set(data.quads, quad, unpack(new_keys))
            end

            local undo_action = function()
              table.set(data.quads, old_value, unpack(new_keys))
              table.set(data.quads, quad, unpack(current_keys))
            end

            data.history:add(do_action, undo_action)
            do_action()

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
    local new_group = {}
    for _,v in ipairs(quads) do
      -- This is an N^2 search and it sucks, but it probably won't matter.
      local key = table.find_key(shared_parent, v)
      if not key then
        interface.show_dialog("You cannot sort quads across different groups")
        return
      else
        individual_keys[v] = key
      end
      if type(key) == "number" and libquadtastic.is_quad(v) then
        numeric_quads = numeric_quads + 1
      end
    end
    if numeric_quads == 0 then
      interface.show_dialog("Only unnamed quads can be sorted")
      return
    end

    -- Filter out non-quad elements and elements with non-numeric keys
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

    local do_action = function()
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
    end

    local undo_action = function()
      for _,v in ipairs(new_group) do
        -- Remove the quad from its shared parent, starting at the end
        table.remove(shared_parent)
      end
      -- We cannot do this in a single pass since these actions can interfere
      for _,v in ipairs(new_group) do
        -- Add the quads to its parent at its original position
        local key = individual_keys[v]
        shared_parent[key] = v
      end
    end

    data.history:add(do_action, undo_action)
    do_action()

  end,

  remove = function(app, data, quads)
    if not quads then quads = data.selection:get_selection() end
    if #quads == 0 then
      return
    else
      local was_collapsed = {}
      local selected_elements = {}
      local keys = {}
      for _,element in ipairs(quads) do
        if data.selection:is_selected(element) then
          table.insert(selected_elements, element)
        end
        was_collapsed[element] = data.collapsed_groups[element]
        keys[element] = {table.find_key(data.quads, element)}
      end

      local do_action = function()
        -- Deselect those elements
        data.selection:deselect(quads)

        for _,element in ipairs(quads) do
          if #keys[element] > 0 then
            -- Remove the elements from the quad tree
            table.set(data.quads, nil, unpack(keys[element]))
            -- Remove the element from the list of collapsed groups. This will have
            -- no effect if the element was a quad.
            data.collapsed_groups[element] = nil
          end
        end
      end

      local undo_action = function()
        -- Select those quads
        data.selection:set_selection(selected_elements)

        for _,element in ipairs(quads) do
          if #keys[element] > 0 then
            -- Restore the elements from the quad tree
            table.set(data.quads, element, unpack(keys[element]))
            -- Restore their entries from the list of collapsed groups
            data.collapsed_groups[element] = was_collapsed[element]
          end
        end
      end

      data.history:add(do_action, undo_action)
      do_action()

    end
  end,

  create = function(app, state, new_quad)
    -- If a group is currently selected, add the new quad to that group
    -- If a quad is currently selected, add the new quad to the same
    -- group.
    local selection = state.selection:get_selection()
    local group -- the group to which the new quad will be added
    if #selection == 1 then
      local keys = {table.find_key(state.quads, selection[1])}
      if libquadtastic.is_quad(selection[1]) then
        -- Remove the last key so that the new quad is added to the
        -- group that contains the currently selected quad
        table.remove(keys)
      end
      group = table.get(state.quads, unpack(keys))
    else
      -- Just add it to the root
      group = state.quads
    end

    local new_index = #group + 1
    local do_action = function()
      group[new_index] = new_quad
    end
    local undo_action = function()
      group[new_index] = nil
    end

    state.history:add(do_action, undo_action)
    do_action()

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
        interface.show_dialog("You cannot group quads across different groups")
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
      -- No point in preserving a numeric key
      if type(key) == "number" then
        key = num_index
        num_index = num_index + 1
      end
      new_group[key] = v
    end

    local do_action = function()
      for _,v in ipairs(quads) do
        -- Remove the element from the shared parent
        local key = individual_keys[v]
        shared_parent[key] = nil
      end
      table.insert(shared_parent, new_group)

      -- Focus quad list on new group
      interface.move_quad_into_view(data.quad_scrollpane_state, new_group)
    end

    local undo_action = function()
      for _,v in ipairs(quads) do
        -- Restore the element in its original position in shared parent
        local key = individual_keys[v]
        shared_parent[key] = v
      end
      -- We used a simple insert to add the new group to the parent.
      -- Therefore the group was inserted at the very end of the parent, and
      -- can be removed with table.remove
      table.remove(shared_parent)
    end

    data.history:add(do_action, undo_action)
    do_action()

  end,

  ungroup = function(app, data, quads)
    if not quads then quads = data.selection:get_selection() end
    if #quads == 0 then return end
    if #quads > 1 then
      interface.show_dialog("You can only break up one group at a time")
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
          local ret = interface.show_dialog(string.format([[
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
          interface.show_dialog(string.format([[
This group cannot be broken up since there is already an element called '%s'%s.]],
            k, (parent_name and " in group "..parent_name) or ""))
          return
        end
      end
    end

    local do_action = function()
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
    end

    local undo_action = function()
      -- Remove the group's elements from the parent
      for k,v in pairs(group) do
        if type(k) == "number" then
          table.remove(parent)
        else
          parent[k] = nil
        end
      end

      -- Add the group to the parent
      parent[group_key] = group
    end
    data.history:add(do_action, undo_action)
    do_action()

  end,

  offer_reload = function(app, data)
    local image_path = data.quads._META.image_path
    local ret = interface.show_dialog(
      string.format("The image %s has changed on disk.\nDo you want to reload it?", image_path),
      {enter="Yes", escape="No"})
    if ret == "Yes" then
      app.quadtastic.load_image(image_path)
    end
  end,

  undo = function(app, data)
    assert(data.history:can_undo())
    local undo_action = data.history:undo()
    undo_action()
  end,

  redo = function(app, data)
    assert(data.history:can_redo())
    local redo_action = data.history:redo()
    redo_action()
  end,

  new = function(app, data)
    local proceed = app.quadtastic.proceed_despite_unsaved_changes()
    if not proceed then return end

    data.quads = {
      _META = {}
    }
    data.quadpath = nil -- path to the file containing the quad definitions
    data.image = nil -- the loaded image
    interface.reset_view(data)
    -- Reset list of collapsed groups
    data.collapsed_groups = {}

    data.file_timestamps = {}
    data.history = History()
    data.history:mark() -- A new file doesn't have any changes worth saving
                        -- until the user actually does something

    data.toolstate = { type = "create"}
  end,

  save = function(app, data, callback)
    if not data.image then
      interface.show_dialog("Load an image first")
      return
    elseif not data.quadpath or data.quadpath == "" then
      app.quadtastic.save_as(callback)
    else
      QuadExport.export(data.quads, data.quadpath)
      data.history:mark()
      if callback then callback(data.quadpath) end
    end
  end,

  save_as = function(app, data, callback)
    local ret, filepath = interface.save_file(data.quadpath)
    if ret == "Save" then
      data.quadpath = filepath
      app.quadtastic.save(callback)
    end
  end,

  choose_quad = function(app, data, basepath)
    if not basepath and data.settings.latest_qua then
      basepath = data.settings.latest_qua
    else
      basepath = love.filesystem.getUserDirectory()
    end
    local ret, filepath = interface.open_file(basepath)
    if ret == "Open" then
      app.quadtastic.load_quad(filepath)
    end
  end,

  -- Checks with the user how they want to handle unsaved changes before an
  -- action is executed that would override those changes.
  -- The user can save or discard the changes, or cancel the action.
  -- This function returns whether the user chose an action that indicates that
  -- they want to go ahead with the action (i.e. the function returns true if
  -- the user pressed save or discard, false otherwise).
  -- This function will also return true if there are no unsaved changes.
  proceed_despite_unsaved_changes = function(app, data)
    -- Return true if there are no unsaved changes
    if not data.history or data.history:is_marked() then return true end

    -- Otherwise check with the user
    local ret = interface.show_dialog("Do you want to save the changes you made in the current file?",
      {"Cancel", "Discard", "Save"})
    if ret == "Save" then
      app.quadtastic.save()
    end
    return ret == "Save" or ret == "Discard"
  end,

  load_quad = function(app, data, filepath)
    if not app.quadtastic.proceed_despite_unsaved_changes() then return end
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
      data.history = History()
      -- A newly loaded project has no unsaved changes
      data.history:mark()
      if not data.quads._META then data.quads._META = {} end
      local metainfo = libquadtastic.get_metainfo(data.quads)
      if metainfo.image_path then
        app.quadtastic.load_image(metainfo.image_path)
      end

      -- Insert new file into list of recently loaded files
      -- Remove duplicates from recent files
      local remaining_files = {filepath}
      for _,v in ipairs(data.settings.recent) do
        -- Limit the number of recent files to 10
        if #remaining_files >= 10 then break end
        if v ~= filepath then
          table.insert(remaining_files, v)
        end
      end
      data.settings.recent = remaining_files
      -- Update latest qua dir
      data.settings.latest_qua = common.split(filepath)
      interface.store_settings(data.settings)
    else
      interface.show_dialog(string.format("Could not load quads: %s", more))
    end
  end,

  choose_image = function(app, data, basepath)
    if not basepath then
      if data.quads and data.quads._META and data.quads._META.image_path then
        basepath = data.quads._META.image_path
      elseif data.settings.latest_img then
        basepath = data.settings.latest_img
      else
        basepath = love.filesystem.getUserDirectory()
      end
    end
    local ret, filepath = interface.open_file(basepath)
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

      -- Update latest image dir
      data.settings.latest_img = common.split(filepath)
      interface.store_settings(data.settings)

      data.file_timestamps.image_loaded = lfs.attributes(filepath, "modification")
      data.file_timestamps.image_latest = data.file_timestamps.image_loaded
      interface.reset_view(data)
      -- Try to read a quad file
      local quadfilename = find_lua_file(filepath)
      if not data.quadpath and lfs.attributes(quadfilename) then
        local should_load = interface.show_dialog(string.format(
          "We found a quad file in %s.\nWould you like to load it?", quadfilename),
          {enter = "Yes", escape = "No"}
        )
        if should_load == "Yes" then
          app.quadtastic.load_quad(quadfilename)
        end
      end
    else
      interface.show_dialog(string.format("Could not load image: %s", more))
    end
  end,

  load_dropped_file = function(app, data, filepath)
    -- Determine how to treat this file depending on its extensions
    local _, extension = common.split_extension(filepath)
    if extension == "lua" or extension == "qua" then
      app.quadtastic.load_quad(filepath)
    else
      -- Try to load this as an image
      app.quadtastic.load_image(filepath)
    end
  end,

  show_about_dialog = function(app, data)
    interface.show_about_dialog()
  end,

  show_ack_dialog = function(app, data)
    interface.show_ack_dialog()
  end,
}
end

return QuadtasticLogic