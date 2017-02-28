-- Load this after lovedebug
if package.loaded["lib/lovedebug/lovedebug"] then
	-- Map console to grave key
	_DebugSettings.Hotkey = "`"
	_DebugSettings.Modifiers = nil

	-- Auto-reload main.lua when it changes
	_DebugSettings.LiveAuto = true
end

_DEBUG = os.getenv("DEBUG") .. "ging"
