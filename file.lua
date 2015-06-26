-- -*- mode: lua; tab-width: 2; indent-tabs-mode: 1; st-rulers: [70] -*-
-- vim: ts=4 sw=4 ft=lua noet
---------------------------------------------------------------------
-- @author Daniel Barney <daniel@pagodabox.com>
-- @copyright 2015, Pagoda Box, Inc.
-- @doc
--
-- @end
-- Created :   26 June 2015 by Daniel Barney <daniel@pagodabox.com>
---------------------------------------------------------------------
exports.name = "pagodabox/coro-sleep"
exports.version = "0.1.0"
exports.description = 
  "sleep a coroutine"
exports.tags = {"sleep","coro"}
exports.license = "MIT"
exports.deps = {}
exports.author =
    {name = "Daniel Barney"
    ,email = "daniel@pagodabox.com"}
exports.homepage = 
  "https://github.com/pagodabox/hookyd/blob/master/deps/coro-sleep.lua"

local uv = require('uv')

-- pretty complex huh?
return function(timeout)
	local timer = uv.new_timer()
	local thread = coroutine.running()
  
  uv.timer_start(timer, timeout, 0, function()
  	coroutine.resume(thread)
	end)
	coroutine.yield()
  
  uv.timer_stop(timer)
  uv.close(timer)
end