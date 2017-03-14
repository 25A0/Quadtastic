local unpack = unpack or table.unpack

local quit = love.event.quit or os.exit

local AppLogic = {}

local function run(self, f, ...)
  assert(type(f) == "function" or self._state.coroutine)
  local co, ret
  if self._state.coroutine then
    -- The coroutine might be running if this was a nested call.
    -- In this case however we do expect that a function was passed.
    if coroutine.running() then
      assert(type(f) == "function")
      co = coroutine.running()
      ret = {true, f(self, self._state.data, ...)}
    else
      co = self._state.coroutine
      ret = {coroutine.resume(co, ...)}
    end
  else
    co = coroutine.create(f)
    ret = {coroutine.resume(co, self, self._state.data, ...)}
  end
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
    if coroutine.status(co) == "dead" then
      -- Remove dead coroutine
      self._state.coroutine = nil
    else
      assert(co == coroutine.running(), "coroutine wasn't running")
    end
    -- If values were returned, then they will be returned to the
    -- next state higher up in the state stack.
    -- If this is the only state, then the app will exit with the
    -- returned integer as exit code.
    if #ret > 1 then
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
    application._has_active_state_changed = false

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
          return setmetatable({}, {__index = function(_, event)
            return function(...)
              table.insert(self._event_queue[key], {event, {...}})
            end
          end})
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
  -- Create a new event queue for the pushed state if there isn't one already
  if not self._event_queue[self._state.name] then
    self._event_queue[self._state.name] = {}
  end
  -- Switch states
  self._state = new_state
  self._has_active_state_changed = true
end

function AppLogic.pop_state(self, ...)
  -- Return to previous state
  self._state = table.remove(self._state_stack)
  self._has_active_state_changed = true
  local statename = self._state.name
  -- Resume state's current coroutine with the passed event
  if self._state.coroutine and 
     coroutine.status(self._state.coroutine) == "suspended"
  then
    run(self, nil, ...)
  end
  -- Catch up on events that happened for that state while we were in a
  -- different state, but make sure that states haven't changed since.
  if self._state.name == statename then
    for _,event_bundle in ipairs(self._event_queue[statename]) do
      local f = self._state.transitions[event_bundle[1]]
      run(self, f, unpack(event_bundle[2]))
    end
    self._event_queue[statename] = nil
  else
  end
end

function AppLogic.get_states(self)
  local states = {}
  for i,state in ipairs(self._state_stack) do
    states[i] = {state, false}
  end
  -- Add the current state
  table.insert(states, {self._state, true})
  return states
end

function AppLogic.get_current_state(self)
  return self._state.name
end

-- Will return true once after each time the active state has changed.
function AppLogic.has_active_state_changed(self)
  local has_changed = self._has_active_state_changed
  self._has_active_state_changed = false
  return has_changed
end

return AppLogic