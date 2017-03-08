local AppModel = {}
local table = require("Quadtastic.tableplus")
local Quadtastic = require("Quadtastic.Quadtastic")
local QuadExport = require("Quadtastic.QuadExport")
local unpack = unpack or table.unpack

setmetatable(AppModel, {
	__call = function(_)
    local state = {}
    state.filepath = "Quadtastic/res/style.png" -- the path to the file that we want to edit
    state.quadpath = "" -- path to the file containing the quad definitions
    state.image = nil -- the loaded image
    state.display = {
      zoom = 1, -- additional zoom factor for the displayed image
    }
    state.scrollpane_state = nil
    state.quad_scrollpane_state = nil
    state.quads = {}
    state.selection = {}

    setmetatable(state, {__index = AppModel})

    return state
  end
})

AppModel.find_lua_file = function(filepath)
  return string.gsub(filepath, "%.(%w+)$", ".lua")
end

AppModel.zoom_in = function(self)
  self.display.zoom = math.min(12, self.display.zoom + 1)
end

AppModel.zoom_out = function(self)
  self.display.zoom = math.max(1, self.display.zoom - 1)
end

-- -------------------------------------------------------------------------- --
-- Selection handling
-- -------------------------------------------------------------------------- --

AppModel.is_selected = function(self, v)
  return self.selection[v]
end

-- Clear the current selection
AppModel.clear_selection = function(self)
  self.selection = {}
end

-- Repace the current selection by the given selection
AppModel.set_selection = function(self, ...)
  self:clear_selection()
  self:select(...)
end

-- Add the given quads or table of quads to the selection
AppModel.select = function(self, ...)
  for _, v in ipairs({...}) do
    self.selection[v] = true
    if type(v) == "table" and not is_quad(v) then
      -- Add children
      for _,v in pairs(table_name) do
        self:select(v)
      end
    end
  end
end

-- Remove the given quads from the selection.
-- If a table of quads is passed, the table and all contained quads will be
-- removed from the selection.
AppModel.deselect = function(self, ...)
  for _, v in ipairs({...}) do
    if not is_quad(v) and type(v) == "table" then -- might be a table of quads, or table of tables
      -- Deselect its children
      for _, c in pairs(v) do
        AppModel.deselect(self, c)
      end
    end
    self.selection[v] = nil
  end
end

AppModel.get_selection = function(self)
  return table.keys(self.selection)
end

AppModel.count_selection = function(self) return #self.selection end

-- -------------------------------------------------------------------------- --

AppModel.remove = function(self, ...)
  AppModel.deselect(self, ...)
  for _,quad in ipairs({...}) do
    local keys = {table.find_key(self.quads, quad)}
    if #keys > 0 then
      table.set(self.quads, nil, keys)
    end
  end
end

-- Exports the current quads
AppModel.export = function(self)
  if not self.filepath then error("Cannot export without filepath") end
  local quadfilename = AppModel.find_lua_file(self.filepath)
  QuadExport.export(self.quads, quadfilename)
end

return AppModel