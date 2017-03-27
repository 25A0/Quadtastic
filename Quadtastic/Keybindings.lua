-- Each entry is a table with the trigger key in the first element, and a
-- list of modifiers in the second element.
-- Modifiers that have a left and right equivalent can be specified as
-- e.g. "*shift" when it doesn't matter which of the two modifiers was pressed
-- Quick reference for modifiers: (from https://love2d.org/wiki/KeyConstant)

-- numlock		Num-lock key	Clear on Mac leopards.
-- capslock		Caps-lock key	Caps-on is a key press. Caps-off is a key release.
-- scrolllock	Scroll-lock key
-- rshift		Right shift key
-- lshift		Left shift key
-- rctrl		Right control key
-- lctrl		Left control key
-- ralt			Right alt key
-- lalt			Left alt key
-- rgui			Right gui key	Command key in OS X, Windows key in Windows.
-- lgui			Left gui key	Command key in OS X, Windows key in Windows.
-- mode			Mode key

-- expected values: "OS X", "Windows", "Linux", "Android", or "iOS"
local os = love.system.getOS()
local mac = os == "OS X"
local win = os == "Windows"
local linux = os == "Linux"

local keybindings = {
	-- selection
	select_all = {"a", {mac and "*gui" or "*ctrl"}},
	delete = {"backspace"},
	rename = {mac and "return" or "f2"},
	group = {"g", {mac and "*gui" or "*ctrl"}},
	ungroup = {"g", {mac and "*gui" or "*ctrl", "*shift"}},

	-- open, save, quit, etc
	open    = {"o", {mac and "*gui" or "*ctrl"}},
	save    = {"s", {mac and "*gui" or "*ctrl"}},
	save_as = {"s", {mac and "*gui" or "*ctrl", "*shift"}},
	quit    = mac and {"q", {"*gui"}} or
	          linux and {"q", {"*ctrl"}} or
	          win and {"f4", {"*alt"}} or nil,
	new     = {"n", {mac and "*gui" or "*ctrl"}},
}

return keybindings

