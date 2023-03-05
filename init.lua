local format = string.format
local repo = 'bestorage/%s/'

-- local task = require 'task'

local prop = require 'prop'
local slot = require 'slot'
local store = require 'store'

local paths, classes = { }, { }

local function clone(t, b)
	b = b or { }
	for k, v in pairs(t) do
		b[k] = v
	end
	return b
end

local function class(name, base)
	local class = prop()
	class:setName(name)

	if not base then
		return class
	end

	clone(base, class)
	classes[class] = true
	return class
end

local function isClass(object)
	return classes[object] == true
end

local path = clone(store)

function path:set(index, path)
	self:rawset(index, path)

	return self
end

function path:get(index, id)
	local value = self:rawget(index)
	return not id and value or id and (type(value) == 'table' and value[id]) or nil
end

function path:rem(index)
	local value = self:get(index)
	if not value then
		return nil
	end

	return self:sanitize(index)
end

local function newPath(name)
	local path = clone(path)
	local set, get = path.set, path.get

	function path:set(index, value)
		return set(self, not value and 'default' or index, value or index)
	end

	function path:get(index)
		return get(self, index or 'default')
	end

	path = class('path: ' .. name, path)
	-- path:setType 'path'

	paths[path] = true
	return path
end


local bestore = class 'bestore'

function bestore:load(type)
	local res = {}
	if not type or type == 'ALL' then
		for index, object in pairs(self) do
			if isClass(object) then
				res[#res+1] = object:load()
			end
		end
	else
		local value = self[type]
		if not value then
			return nil
		end

		res[#res+1] = value:load()
	end

	return res
end

function bestore:save(type)
	local res = {}
	if not type or type == 'ALL' then
		for index, object in pairs(self) do
			if isClass(object) then
				res[#res+1] = object:save()
			end
		end
	else
		local value = self[type]
		if not value then
			return nil
		end

		res[#res+1] = value:save()
	end

	return res
end


local storage, handles = newPath 'storage', newPath 'handles'

bestore.paths = class('paths', clone({
	storage = storage, handles = handles
}, store))

function bestore.paths.isPath(object)
	return paths[object] == true
end

function bestore.paths:__iter()
	return function(t, index)
		local index, value = pairs(t)(t, index)
		if not index then
			return nil
		end
		if self.isPath(value) then
			return index, value
		end
		return self:__iter()(t, index)
	end, self
end

function bestore.paths:getPathNames()
	local paths = { }
	for name, path in self:__iter() do
		paths[name] = path:get()
	end
	return paths
end


local defaultPaths = {
	handles = format(repo, '_handles'),
	storage = format(repo, '_storage'),
}

local defaultOptions = {
	paths = defaultPaths
}

local function setOption(hold, these)
	if type(these) == 'string' and type(these) ~= 'table' then
		return hold:set('default', these)
	end

	for name, option in pairs(these) do
		hold:set(type(name) == 'string' and name or 'custom', option)
	end
end

return setmetatable({
	prop = prop,
	clone = clone,
	class = class,
	isClass = isClass,

	---*========================*---
	autoLoad = function(self, value)
		self.automaticLoad = value
	end,
	autoSave = function(self, value)
		self.automaticSave = value
	end,

	---*====================*---
	getAutoLoad = function(self)
		local v = self.automaticLoad
		return v == nil or v
	end,
	getAutoSave = function(self)
		local v = self.automaticSave
		return v == nil or v --? if the value is not equal to nil return it, but if it is nil return true.
	end
}, {
	__index = bestore,
	__pairs = function() return pairs(bestore) end,

	__call = function(self) -- , options)
		-- local istype = type(options) == 'table'

		if not self.inited then
			-- if self.trouble then end
			-- store = clone(self, store)
			slot.paths = self.paths

			self.store = slot;
			self.inited = true
		end

		for element, slot in pairs(defaultOptions) do
			for option, value in pairs(slot) do
				local optionable = self[element]
				if optionable then
					if not optionable[option]:get() then
						-- value = (istype and options[option]) or value
						setOption(optionable[option], value)
					end
				end
			end
		end

		-- get checker function fot this functions

		--[[
			Incompleted features so this unused for the moment.
				→ Need to implement "AUTOMATIC" find of configurations.
			Until it going to auto-configurate through the `defaultOptions`.
		]]
		if self:getAutoLoad() == true then
			if not self.loaded then
				-- self:load 'ALL'
				self.loaded = true
			end
		end


		if self:getAutoSave() == true then
			self:save 'ALL'
		end

		return self
	end,
})