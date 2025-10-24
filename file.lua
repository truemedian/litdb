--[[lit-meta
	name = 'Corotyest/task'
	version = '1.0.0'
	author = 'Corotyest'
]]

local uv = require 'uv'
local bind = require 'utils'.bind

local threads = {}
local _task = {}

--- Return whether the current thread is active
---@return boolean
function _task:isActive()
	return self._active == true
end

--- Start the current thread (if it is not active)
---@return table
function _task:start(base, callback, ...)
	if self:isActive() then return nil end

	local ist = type(base) == 'table'
	local v1, v2 = ist and base[1] or base, ist and base[2] or 0

	uv.timer_start(self._timer, v1, v2, bind(callback, ...))
	self._active = true
	return self
end

--- Stop the current handle to be started (if it is active)
---@return table
function _task:stop()
	if not self:isActive() then return nil end
	if uv.is_closing(self._timer) then return self end

	uv.timer_stop(self._timer)
	uv.close(self._timer)
	self._active = false
	return self
end

--- Clear the current handle
function _task:clear()
	if self:isActive() then self:stop() end
	threads[self] = nil
end

-- Metatable __index
_task.__index = function(self, k)
	if not threads[self] then
		return error('This thread has cleared', 2)
	end

	local value = rawget(_task, k)
	if type(value) == 'function' then
		return value
	else
		return value
	end
end

--- Check whether param `t` is a handle
---@param t any
---@return boolean
local function isThread(t)
	assert(t, 'pass something to check')
	return threads[t] == true
end

--- Creates a handle in base `_task`
---@return table
local function newHandle()
	local thread = setmetatable({
		_timer = uv.new_timer(),
	}, _task)
	threads[thread] = true
	return thread
end

local running, resume, yield = coroutine.running, coroutine.resume, coroutine.yield

--- Tries to resume a thread and throws error if fails
---@param thread thread
---@vararg any
local function assertResume(thread, ...)
	local success, err = resume(thread, ...)
	if not success then
		error(debug.traceback(thread, err), 0)
	end
end

--- Wait certain time before executing a function (non-blocking) delay is in miliseconds.
---@param delay number
---@param fn function
---@vararg any
---@return table
local function delay(delay, fn, ...)
	if type(delay) ~= 'number' then
		error('bad argument #1 for delay', 2)
	elseif type(fn) ~= 'function' then
		error('bad argument #2 for delay', 2)
	end

	local handle = newHandle()
	handle:start({ delay, 0 }, function(...)
		fn(handle, ...)
		handle:clear()
	end, ...)
	return handle
end

--- Put the currently running thread into a sleep period (non-blocking) delay is in miliseconds.
---@param delay number
---@param thread thread
---@return table
local function sleep(delay, thread, ...)
	if type(delay) ~= 'number' then
		error('bad argument #1 for sleep', 2)
	end

	thread = thread or running()
	if type(thread) ~= 'thread' then
		return nil, 'bad argument #2 for sleep'
	end

	local handle = newHandle()
	handle:start({ delay, 0 }, function(...)
		handle:clear()
		assertResume(thread, handle, ...)
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
