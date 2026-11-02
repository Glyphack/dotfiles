-- Runs fn just before Hammerspoon reloads its config or quits. Windows such
-- as choosers and web views stay on screen after a reload unless they are
-- closed here, and nothing is left that can close them afterwards.
local function onShutdown(fn)
	local previous = hs.shutdownCallback
	hs.shutdownCallback = function()
		fn()
		if previous then
			previous()
		end
	end
end

return onShutdown
