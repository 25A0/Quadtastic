local current_folder = ... and (...):match '(.-%.?)[^%.]+$' or ''
local Dialog = require(current_folder.. ".Dialog")
local QuadExport = require(current_folder.. ".QuadExport")
local table = require(current_folder.. ".tableplus")
local libquadtastic = require(current_folder.. ".libquadtastic")

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

function QuadtasticLogic.transitions(interface) return {
  -- luacheck: no unused args
  export = function(app, data)
    if not data.image then
      QuadtasticLogic.show_dialog("Load an image first")
      return
    elseif not data.quadpath or data.quadpath == "" then
      local ret, path = QuadtasticLogic.query(
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
      QuadtasticLogic.show_dialog("You cannot rename more than one element at once.")
      return
    else
      local quad = quads[1]
      local current_keys = {table.find_key(data.quads, quad)}
      local old_key = table.concat(current_keys, ".")
      local new_key = old_key
      local ret
      ret, new_key = QuadtasticLogic.query("Name:", new_key, {"Cancel", "OK"})

      local function replace(tab, old_keys, new_keys, element)
        -- Make sure that the new keys form a valid path, that is, all but the
        -- last key must be tables that are not quads
        local current_table = tab
        for i=1,#new_keys do
          if type(current_table) == "table" and libquadtastic.is_quad(current_table) then
            local keys_so_far = table.concat(new_keys, ".", 1, i)
            QuadtasticLogic.show_dialog(string.format(
              "The element %s is a quad, and can therefore not have nested quads.",
              keys_so_far), {"OK"}
            )
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
This group cannot be broken up since there is already an element
called '%s'%s.]],
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
      -- Reset list of collapsed groups
      data.collapsed_groups = {}
    else
      QuadtasticLogic.show_dialog(string.format("Could not load quads: %s", more))
    end

  end,

  load_image_from_path = function(app, data, filepath)
    local success, more = pcall(function()
      local filehandle, err = io.open(filepath, "rb")
      if err then
        error(err)
      end
      local filecontent = filehandle:read("*a")
      filehandle:close()
      local imagedata = love.image.newImageData(
        love.filesystem.newFileData(filecontent, 'img', 'file'))
      return love.graphics.newImage(imagedata)
    end)

    -- success, more = pcall(love.graphics.newImage, data)
    if success then
      data.image = more
      data.filepath = filepath
      interface.reset_view(data)
      -- Try to read a quad file
      local quadfilename = find_lua_file(data.filepath)
      if lfs.attributes(quadfilename) then
        local should_load = QuadtasticLogic.show_dialog(string.format(
          "We found a quad file in %s. Would you like to load it?", quadfilename),
          {"Yes", "No"}
        )
        if should_load == "Yes" then
          app.quadtastic.load_quads_from_path(quadfilename)
        end
      end
    else
      QuadtasticLogic.show_dialog(string.format("Could not load image: %s", more))
    end
  end,
}
end

return QuadtasticLogic