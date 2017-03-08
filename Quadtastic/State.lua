local State = {}

setmetatable(State, {
  __call = function(_, name, transitions)
    local state = {}
    state.name = name
    state.transitions = transitions
    state.coroutine = nil -- the current coroutine
    -- Additional data
    state.data = {}

    return state
  })

return State