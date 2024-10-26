--- Event handler class with Node.js-like API.
--
-- @author Er2 <er2@dismail.de>
-- @copyright 2022-2025
-- @license Zlib
-- @module Events

--[[lit-meta
	name = 'er2off/events'
	version = '1.0.0'
	homepage = 'https://github.com/er2off/lua-mods'
	description = 'Event handler class with Node.js-like API.'
	tags = {'class', 'lua', 'oop', 'events'}
	license = 'Zlib'
	author = {
		name = 'Er2',
		email = 'er2@dismail.de'
	}
]]

require 'class'

--- Events class
-- @type Events
-- @usage
-- local handler = new 'Events' ()
-- handler:on('trigger', function(arg)
--   print(arg)
-- end)
-- handler:emit('trigger', 'Test!')
class 'Events' {
	function(this)
		this._ev_ = {}
	end,

	_add = function(this, type, name, func)
		table.insert(this._ev_, {
			type = tostring(type),
			name = tostring(name),
			func = func,
		})
	end,

	--- Adds function callback to listeners of event.
	-- @tparam Events this
	-- @tparam string name Event name.
	-- @tparam function func Callback function.
	-- @usage
	-- handler:on('trigger', function(...)
	--   print(...)
	-- end)
	on = function(this, name, func)
		this:_add('on', name, func)
	end,

	--- Adds function callback to listen event only one time.
	-- @tparam Events this
	-- @tparam string name Event name.
	-- @tparam function func Callback function.
	-- @see events:on
	once = function(this, name, func)
		this:_add('once', name, func)
	end,

	--- Binds class method to event with same name.
	-- @tparam Events this
	-- @tparam string name Event name.
	-- @see events:on
	-- @usage
	-- function handler.onTest()
	--   print 'test'
	-- end
	-- handler:wrap 'onTest'
	wrap = function(this, name)
		local func = this[name]
		assert(type(func) == 'function', 'Invalid method type')
		this:_add('on', name, func)
	end,

	--- Removes function callback from listeners of event.
	-- @tparam Events this
	-- @tparam function func Callback function.
	-- @usage
	-- local function test()
	--   print 'unreachable'
	-- end
	-- handler:on('test', test)
	-- handler:on('smthngelse', test)
	-- -- now we don't want it
	-- handler:off(test)
	off = function(this, func)
		for k, v in pairs(this._ev_) do
			if v.func == func
			then table.remove(this._ev_, k)
			end
		end
	end,

	--- Prepends variable to callback call for all events.
	-- @tparam Events this
	-- @tparam any arg Argument which will be prepended for this event class
	-- @usage
	-- handler:addArg {'example'}
	-- handler:on('test', function(t, ...)
	--   assert(t[1] == 'example')
	-- end)
	addArg = function(this, arg)
		local prevEv = this._ev
		function this._ev(t, i, name, ...)
			prevEv(t, i, name, arg, ...)
		end
	end,

	_ev = function(t, i, name, ...)
		local v = t[i]
		if v.name == name then
			v.func(...)
			if v.type == 'once'
			then table.remove(t, i)
			end
		end
	end,

	--- Emits event with optional arguments
	-- @tparam Events this
	-- @tparam string name Event name.
	-- @param ... Optional arguments.
	-- @see events:on, events:once, events:off
	emit = function(this, name, ...)
		local t = this._ev_
		for i = 1, #t do
			local v = t[i]
			if  type(v)      == 'table'
			and type(v.name) == 'string'
			and type(v.type) == 'string'
			and type(v.func) == 'function'
			then this._ev(t, i, name, ...)
			else print 'Invalid event'
				if v then print(v, v.name, v.type, v.func)
				else print 'nil' end
			end
		end
	end,
}

--- EventsThis class
--
-- Same as Events class but automatically prepends
-- this argument to callbacks call
-- @type EventsThis
-- @usage
-- -- Better to use with `class 'YourOwn' : inherits 'EventsThis'`
-- local inst = new 'EventsThis' ()
-- inst.test = 'Test!'
--
-- inst:on('trigger', function(this, arg)
--   assert(this.test == arg)
-- end)
-- inst:emit('trigger', 'Test!')
class 'EventsThis' : inherits 'Events' {
	--- Builds EventsNew class and adds this as argument
	-- @function init
	function(this)
		this:super()
		this:addArg(this)
	end,
}
