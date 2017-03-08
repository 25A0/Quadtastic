local unpack = unpack or table.unpack

local quit = love.event.quit or os.exit

local AppLogic = {}

local function run(self, f, ...)
  assert(type(f) == "function")
  local co = coroutine.create(f)
  local ret = {coroutine.resume(co, self._state.data, ...)}
  -- Print errors if there are any
  assert(ret[1], ret[2])
  -- If the coroutine yielded then we will issue a state switch based
  -- on the returned values.
  if coroutine.status(co) == "suspended" then
    local new_state = ret[2]
    -- Save the coroutine so that it can be resumed later
    self._state.coroutine = co
    self:push_state(new_state)
  else
    assert(coroutine.status(co) == "dead")
    -- If values were returned, then they will be returned to the
    -- next state higher up in the state stack.
    -- If this is the only state, then the app will exit with the
    -- returned integer as exit code.
    if #ret > 0 then
      if #self._state_stack > 0 then
        self:pop_state(select(2, unpack(ret)))
      else
        quit(ret[1])
      end
    end
  end

end

setmetatable(AppLogic, {
	__call = function(_, initial_state)
    local application = {}
    application._state = initial_state
    application._state_stack = {}
    application._event_queue = {}

    setmetatable(application, {
      __index = function(self, key)
        if rawget(AppLogic, key) then return rawget(AppLogic, key)
        -- If this is a call for the current state, return that state
        elseif key == self._state.name then
          -- return a function that executes the command in a subroutine,
          -- and captures the function's return values
          return setmetatable({}, {__index = function(_, event)
            local f = self._state.transitions[event]
            return function(...)
              run(self, f, ...)
            end
          end})
        -- Otherwise queue that call for later if we have a queue for it
        elseif self._event_queue[key] then
          return function(...)
            table.insert(self._event_queue[key], ...)
          end
        else
          error(string.format("There is no state %s in the current application.", key))
        end
      end
    })
    return application
  end
})

function AppLogic.push_state(self, new_state)
  assert(string.sub(new_state.name, 1, 1) ~= "_",
         "State name cannot start with underscore")

  -- Push the current state onto the state stack
  table.insert(self._state_stack, self._state)
  -- Create a new event queue for the pushed state
  event_queue[self._state] = {}
  -- Switch states
  self._state = new_state
end

function AppLogic.pop_state(self, ...)
  -- Return to previous state
  self._state = table.remove(self._state_stack)
  -- Resume state's current coroutine with the passed event
  if self._state.coroutine and 
     coroutine.status(self._state.coroutine) == "suspended"
  then
    coroutine.resume(self._state.coroutine, ...)
  end
  -- Catch up on events that happened for that state while we were in a
  -- different state
  for _,event_bundle in ipairs(event_queue[self.state]) do
    local event = event_bundle[1]
    self._state.process(event, select(2, unpack(event_bundle)))
  end
end

function AppLogic.get_states(self)
  local states = {}
  for i,state in ipairs(self._state_stack) do
    states[i] = state
  end
  -- Add the current state
  table.insert(states, self._state)
  return states
end

function AppLogic.get_current_state(self)
  return self._state.name
end

return AppLogic