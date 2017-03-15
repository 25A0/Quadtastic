local table = require("Quadtastic/tableplus")
local Selection = {}

Selection.is_selected = function(self, v)
  return self.selection[v]
end

-- Clear the current selection
Selection.clear_selection = function(self)
  self.selection = {}
end

-- Repace the current selection by the given selection
Selection.set_selection = function(self, quads)
  Selection.clear_selection(self)
  Selection.select(self, quads)
end

-- Add the given quads or table of quads to the selection
Selection.select = function(self, quads)
  for _, v in ipairs(quads) do
    self.selection[v] = true
  end
end

-- Remove the given quads from the selection.
-- If a table of quads is passed, the table and all contained quads will be
-- removed from the selection.
Selection.deselect = function(self, quads)
  for _, v in ipairs(quads) do
    self.selection[v] = nil
  end
end

Selection.get_selection = function(self)
  return table.keys(self.selection)
end

Selection.new = function(self)
  local selection = {
    selection = {} -- the actual table that contains selected elements
	}

  setmetatable(selection, {
    __index = Selection,
  })

  return selection
end

setmetatable(Selection, {
  __call = Selection.new
})

return Selection