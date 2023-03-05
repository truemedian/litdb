--[[
	author = 'Corotyest',
	version = '1.0.0bw'

	This module creates the stores of Better-Store, or slots.
]]

local format, gsub = string.format, string.gsub
local badArg = 'bad argument #%d for %s (%s expected got %s)'

local YELLOW, BOLD = 33, 1
local STR = format('\27[%d;%dm%s\27[0m', BOLD, YELLOW, '[%d:%d] | [WARN]:')
local function warn(...)
	if not ... then
		return nil
	end

	local date = os.date('*t')
	print(format(STR, date.hour, date.min), ...)
end

local core = require './core'
local prop = require 'prop'

local Emitter = require 'core'.Emitter

local function newStore()
	local store = prop()
	for name, fn in pairs(core) do
		store[name] = fn
	end

	return store
end

local store = prop()
store:setName 'store'

function Emitter:initialize()
	self.store = store
end

local slots = { }
local names = { }

local depecrated = {
	getSlot = true,
	setSlot = true,
	quitSlot = true,
}

function store.isObject(object)
	return slots[object] == true or names[object] and true
end

function store:getStore(name)
	local type1 = type(name)
	if type1 ~= 'string' then
		return error(format(badArg, 1, 'getStore', 'string', type1), 2)
	elseif self.isObject(name) then
		return slots[name]
	end

	local store = newStore()
	store:setName(name)

	store.name = name
	store.paths = self.paths
	store.emitter = self.emitter:new()

	for key in pairs(depecrated) do
		local udepName = gsub(key, 'Slot', '')
		local fn = store[udepName]
		store[key] = function(...)
			warn(format('The function %s.%s() is depecrated, instead use the function %s.%s()', name, key, name, udepName))
			return fn(...)
		end
	end


	local cache = { }
	store:rawset('cache', cache)

	local state = false

	function store:clean()
		warn('By the moment this function is indented to be released in another version. Apologizes.')
	end

	function store.isCacheEnabled()
		-- store.emitter:emit 'checkForCache' --→ Verify if the current cache source remain to `cache`.
		return state == true
	end

	function store:changeCacheState(value)
		state = value and true or (value == nil and not cache)

		self.emitter:emit('cacheStateChanged', state)
	end

	store.emitter:on('cacheStateChanged', function(state)
		if state then
			store:rawset('cache', cache)
		elseif not state then
			store:sanitize 'cache'
		end
	end)

	self.emitter:emit('newStore', store)
	return store
end

store.emitter = Emitter:extend()

return setmetatable({}, {
	__index = store,

	__call = function(self, table)
		local type1 = type(table)
		if type1 ~= 'table' then
			return error(format(badArg, 1, 'store', 'table', type1))
		end

		for name, value in pairs(self) do
			table[name] = value
		end

		for name, value in self:iter() do
			table[name] = value
		end

		return table
	end
})