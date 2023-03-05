local content = require 'content'
local particle = require 'format'

local encode, decode = particle.encode, particle.decode

local search = table.search
local format = string.format

local _error = 'bad argument #%s for %s (%s expected got %s)'

local cache = { }

local function set(self, id, value)
	local type1, type2, type3 = type(self), type(id), type(value)
	if type1 ~= 'table' then
		return nil, format(_error, 'self', 'set', 'table', type1)
	elseif type2 ~= 'string' then
		if type2 ~= 'number' then
			return nil, format(_error, 1, 'set', 'string/number', type2)
		end
	elseif type3 == 'nil' then
		return nil, format(_error, 2, 'set', 'any', nil)
	end

	local handle = self:getHandle()
	local emitter = self.emitter

	if handle then
		value = encode(value)

		if emitter then
			emitter:emit('set', id, value)
		end

		local success, error = handle:apply {
			key = id,
			value = value,
			setret = true
		}

		if not success then
			return nil, error
		end

		if self:isCached() == true then
			emitter:emit('cacheSet', id, value)
			if not self.cache then
				cache[self] = {
					[id] = value
				}

				return self
			end

			cache[self][id] = value
		end

		return self
	end
end

local function get(self, id, environment)
	local type1, type2 , type3 = type(self), type(id), type(environment)
	if type1 ~= 'table' then
		return nil, format(_error, 'self', 'get', 'table', type1)
	elseif type2 ~= 'string' then
		if type2 ~= 'number' then
			return nil, format(_error, 1, 'get', 'string/number', type2)
		end
	elseif environment and type3 ~= 'table' then
		return nil, format(_error, 2, 'get', 'table', type3)
	end

	local emitter = self.emitter

	local value = self.cache
	if value and value[id] then
		return value[id]
	end

	local handle = self:getHandle()

	if handle then
		local content, error = handle:content()

		local type3 = type(content)
		if type3 ~= 'nil' and not error then
			return type3 == 'table' and search(content, id) or content
		else
			return nil, error or format('Id: —%s— not exists, in —%s—.', id, self.name)
		end
	end
end

local function quit(self, id)
	local type1, type2 = type(self), type(id)
	if type1 ~= 'table' then
		return nil, format(_error, 'self', 'quit', 'table', type1)
	elseif type2 ~= 'string' then
		if type2 ~= 'number' then
			return nil, format(_error, 1, 'quit', 'string/number', type2)
		end
	end

	local itSlot = self:getSlot(id)
	if itSlot == nil then
		return nil, format('Slot: —%s— is quited or not exists, in —%s—', id, self.name)
	end

	local handle = self:getHandle()
	local emitter = self.emitter

	if handle then
		local value = self.cache
		if value then
			emitter:emit('cacheQuit', id)
			value[id] = nil
		end

		emitter:emit('quit', id)
		return self, handle:apply {
			key = id,
			value = nil,
			setret = true
		}
	end
end

local function isCached(self)
	return self.isCacheEnabled() == true -- self.canDataCached == true
end

local function getHandle(self)
	if not self.handle then
		if not self.paths then
			return nil
		end

		local handle = self.paths.handles:get()
		local success = content:edit_dir(handle)

		if success then
			self.handle = content:newHandle(handle .. self.name .. '.lua')
		end
	end

	return self.handle
end


return {
	get = get,
	set = set,
	quit = quit,
	isCached = isCached,
	getHandle = getHandle,
}