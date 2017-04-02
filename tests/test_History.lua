local History = require("Quadtastic/History")

do
	-- Check that a new history is not marked
	local history = History()
	assert(not history:is_marked())
end

do
	-- Check marking
	local history = History()
	history:mark()
	assert(history:is_marked())
end

do
	-- Check that a history is no longer marked once something was added
	local history = History()
	history:add("foo", "bar")
	assert(not history:is_marked())
	history:mark()
	assert(history:is_marked())
	history:add("baz", "haz")
	assert(not history:is_marked())
end

do
	-- Undo, redo stuff
	local history = History()
	history:add("foo", "bar")
	assert(not history:is_marked())
	history:mark()
	assert(history:is_marked())
	assert(history:can_undo())
	assert(history:undo() == "bar")
	assert(not history:is_marked())
	assert(history:can_redo())
	assert(history:redo() == "foo")
	assert(history:is_marked())
end

do
	-- Test diverting history
	local history = History()
	history:add("foo", "bar")
	history:add("baz", "boo")
	assert(history:can_undo())
	assert(history:undo() == "boo")
	assert(history:can_redo())
	history:add("fuz", "far")
	assert(not history:can_redo())
end

