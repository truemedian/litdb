local content = require 'content'
local particle = require 'particle'

local format = string.format
local _error = 'bad argument #%s for %s (%s expected got %s)'

local cache = { }

local function setSlot(self, id, value)
	local type1, type2, type3 = type(self), type(id), type(value)
	if type1 ~= 'table' then
		return nil, format(_error, 'self', 'setSlot', 'table', type1)
	elseif type2 ~= 'string' then
		if type2 ~= 'number' then
			return nil, format(_error, 1, 'setSlot', 'string/number', type2)
		end
	elseif type3 == 'nil' then
		return nil, format(_error, 2, 'setSlot', 'any', nil)
	end

	local handle = self:getHandle()

	if handle then
		value = particle.encode(value)

		local success, error = handle:apply({ key = id, setret = true, value = value })
		if success then
			if self.cacheData == true then
				if not cache[self] then
					cache[self] = {
						[id] = value
					}

					return self
				end

				cache[self][id] = value
			end
			return self
		else
			return nil, error
		end
	end
end

local function getSlot(self, id, enviroment)
	local type1, type2 , type3 = type(self), type(id), type(enviroment)
	if type1 ~= 'table' then
		return nil, format(_error, 'self', 'getSlot', 'table', type1)
	elseif type2 ~= 'string' then
		if type2 ~= 'number' then
			return nil, format(_error, 1, 'getSlot', 'string/number', type2)
		end
	elseif enviroment and type3 ~= 'table' then
		return nil, format(_error, 2, 'getSlot', 'table', type3)
	end

	local cache = cache[self]
	if cache and cache[id] then
		-- self.cacheData = true
		return cache[id]
	end

	local handle = self:getHandle()

	if handle then
		local content, error = handle:content()

		local type3 = type(content)
		if type3 ~= 'nil' and not error then
			return type3 == 'table' and table.search(content, id) or content
		else
			return nil, error or format('Id: —%s— not exists, in —%s—.', id, self.name)
		end
	end
end

local function quitSlot(self, id)
	local type1, type2 = type(self), type(id)
	if type1 ~= 'table' then
		return nil, format(_error, 'self', 'quitSlot', 'table', type1)
	elseif type2 ~= 'string' then
		if type2 ~= 'number' then
			return nil, format(_error, 1, 'quitSlot', 'string/number', type2)
		end
	end

	local isCached = self:getSlot(id)
	if not isCached then return nil, format('Slot: —%s— is quited or not exists, in —%s—', id, self.name) end

	local handle = self:getHandle()

	if handle then
		if cache[self] then
			cache[self][id] = nil
		end

		return self, handle:apply({ key = id, setret = true, value = nil})
	end
end

local function getHandle(self)
	if not self.handle then
		local handle = self.props:get('path', 'store{}')
		local success = content:edit_dir(handle)

		if success then
			self.handle = content:newHandle(handle .. self.name .. '.lua')
		end
	end

	return self.handle
end

-- I won't particularly store the enpoint`s


return {
	name = nil,
	setSlot = setSlot,
	getSlot = getSlot,
	quitSlot = quitSlot,
	getHandle = getHandle,
	cacheData = true,
}