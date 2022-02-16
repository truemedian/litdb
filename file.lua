--[[lit-meta
	name = 'Corotyest/task'
	version = '0.0.2'
	author = 'Quichk'
]]

local threads = {}

local uv = require 'uv'
local bind = require 'utils'.bind

local _task = {}

--- Return whatever the current thread is active.
---@param self table
---@return boolean
function _task.isActive(self) return self._active == true end

--- Start the current thread (if it is not active).
---@param self table
---@return table
function _task.start(self)
	local t = self._timer
	return function(base, callback, ...)
		if self.isActive() then return nil end
		local ist = type(base) == 'table'
		local v1, v2 = ist and base[1] or base, ist and base[2] or base
		uv.timer_start(
			t, v1, v2, bind(callback, ...)
		)

		return self
	end
end

--- Stop the current handle to be started (if it is active).
---@param self table
---@return table
function _task.stop(self)
	local t = self._timer
	return function()
		if not self.isActive() then return nil end
		if uv.is_closing(t) then
			return self
		end

		uv.timer_stop(t); uv.close(t); self._active = false

		return self
	end
end

--- Clear the current handle.
---@param self table
function _task.clear(self)
	if self.isActive() and self.stop() or not self.isActive() then
		threads[self] = nil
	end
end

_task.__index = function(self, k)
	if not threads[self] then return error('This thread has cleared', 2) end

	local value = rawget(_task, k)
	if type(value) == 'function' then
		value = value(self)
		if type(value) == 'function' then
			return value
		else
			return function() return value end
		end
	else
		return value
	end
end

--- Check whatever param `t` is a handle.
---@param t any
---@return boolean
local function isThread(t)
	assert(t, 'pass something to check')
	return threads[t] == true
end

--- Creates a handle in base `_task`.
---@return table
local function newHandle()
	local thread = setmetatable({
		_timer = uv.new_timer(),
		_new_handle = newHandle
	}, _task)
	threads[thread] = true
	return thread
end

--- Wait certain time to `fn` execution after this delay spawn the function.
--- If there is no errros return a table with the handle information.
---@param delay number
---@param fn function
---@vararg any
---@return table
local function delay(delay, fn, ...)
	local type1, type2 = type(delay), type(fn)
	if type1 ~= 'number' then
		return error('bad argument #1 for delay', 2)
	elseif type2 ~= 'function' then
		return error('bad argument #2 for delay', 2)
	end

	local handle = newHandle()

	handle.start( { delay, 0 }, function(...)
		fn(handle, ...); handle.clear()
	end, ...)

	return handle
end

local running, resume, yield = coroutine.running, coroutine.resume, coroutine.yield

--- Tries to resume a thread as except it throw an error.
---@param thread thread
---@vararg any
local function assertResume(thread, ...)
	local success, error = resume(thread, ...)
	if not success then
		return error(debug.traceback(thread, error), 0)
	end
end

--- Put the givened or currently running `thread` into a sleep period.
--- If there is no errors return a table with the handle information.
---@param delay number
---@param thread thread
---@return table
local function sleep(delay, thread, ...)
	local type1, type2 = type(delay), type(thread)
	if type1 ~= 'number' then
		return error('bad argument #1 for sleep', 2)
	elseif type2 ~= 'thread' then
		thread = running()
		if type(thread) ~= 'thread' then
			return nil, 'bad argument #2 for sleep'
		end
	end

	local handle = newHandle()

	handle.start( { delay, 0 }, function(...)
		handle.clear(); return assertResume(thread, handle, ...)
	end, ...)

	return yield()
end


return {
	assertResume = assertResume,
	isThread = isThread,
	newHandle = newHandle,
	delay = delay,
	sleep = sleep
}