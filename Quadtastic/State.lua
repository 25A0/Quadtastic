local State = {}

setmetatable(State, {
  __call = function(_, name, transitions, data)
    local state = {}
    state.name = name
    state.transitions = transitions
    state.coroutine = nil -- the current coroutine
    -- Additional data
    state.data = data or {}

    return state
  end
})

return State