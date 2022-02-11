--[[lit-meta
	name = "RiskoZoSlovenska/coro-thread-work"
	version = "1.0.0"
	homepage = "https://github.com/RiskoZoSlovenska/coro-thread-work"
	description = "Call functions in a new thread, sync-style."
	tags = {"coro", "thread"}
	license = "MIT"
	author = "RiskoZoSlovenska"
]]

local work = require("thread").work
local running, resume, yield = coroutine.running, coroutine.resume, coroutine.yield


return function(func, ...)
	local this = running()

	work(func, function(...)
		local success, res = resume(this, ...)
		if not success then
			error(debug.traceback(this, res), 0)
		end
	end):queue(...)

	return yield()
end