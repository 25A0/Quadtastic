local AppModel = {}

setmetatable(AppModel, {
	__call = function(_)
    local state = {}
    state.filepath = "Quadtastic/res/style.png" -- the path to the file that we want to edit
    state.image = nil -- the loaded image
    state.display = {
      zoom = 1, -- additional zoom factor for the displayed image
    }
    state.scrollpane_state = nil
    state.quad_scrollpane_state = nil
    state.quads = {}

    setmetatable(state, {__index = AppModel})

    return state
  end
})

AppModel.zoom_in = function(self)
  self.display.zoom = math.min(12, self.display.zoom + 1)
end

AppModel.zoom_out = function(self)
  self.display.zoom = math.max(1, self.display.zoom - 1)
end

return AppModel