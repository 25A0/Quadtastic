-- Undo/Redo history
local History = {}

function History.new()
	local history = setmetatable({}, {
		__index = History,
	})
	history.events = {}
	history.position = 0
	-- If the initial marked position would be 0, then a newly created history
	-- would always appear marked. We might not want that, so we set the initial
	-- marked position to -1.
	history.marked_position = -1

	return history
end

setmetatable(History, {__call = History.new})

-- Adds an event to the history, defined by its undo and redo action.
-- The undo action is the one that leads from the new state to the previous
-- state, and the redo action is the one that lead from the previous state to
-- the new state.
-- For example, if the current state is a string containing "Hello", then
-- a new event could be recorded as
-- history:add({append, " World"}, {remove, " World"})
function History.add(self, constructive_action, destructive_action)
	-- Remove all later events in this history
	for i=self.position + 1, #self.events do
		self.events[i] = nil
	end

	-- Insert the events into the history
	self.events[self.position + 1] = {
		undo = destructive_action,
		redo = constructive_action
	}
	self.position = self.position + 1
end

function History.is_marked(self)
	return self.marked_position == self.position
end

function History.mark(self)
	self.marked_position = self.position
end

function History.can_undo(self)
	return self.position > 0 and self.events[self.position].undo
end

function History.can_redo(self)
	return self.position < #self.events and self.events[self.position + 1].redo
end

function History.undo(self)
	assert(self.position > 0)
	self.position = self.position - 1
	assert(self.events[self.position+1].undo)
	return self.events[self.position+1].undo
end

function History.redo(self)
	assert(self.position < #self.events)
	self.position = self.position + 1
	assert(self.events[self.position].redo)
	return self.events[self.position].redo
end

return History