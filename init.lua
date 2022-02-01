local default_path = './deps/bestore/'

local default_paths = {
	path = default_path,
	data_store_path = default_path .. 'data-stores/',
	auto_saves_path = default_path .. 'automatic-load-saves/',
}

local default_errors = {
	normal = 'bad argument #%s for %s (%s expected got %s)',
	warning = 'Expected %s for %s are %s (in function %s)'
}

local normal = default_errors.normal
local warning = default_errors.warning

local content = require 'content'
local apply, search = content.apply, content.searchFor

local format = string.format
local find = table.find

local _type = type
local saves_f = '_save_%s'

local function update(type, path)
	local type1 = _type(type)
	if type1 ~= 'string' then
		return nil, format(normal, 1, update, 'string', type1)
	end

	local pathtr = default_path .. 'options.json'
	local to = search(pathtr, '_path_saves') or {}; to[type] = path

	return apply(pathtr, '_path_saves', to, 'module')
end

local function save(self, type, path)
	local type1, type2 = _type(type), _type(path)
	if type1 ~= 'string' then
		return nil, format(normal, 1, 'save', 'string', type1)
	elseif path and type2 ~= 'string' then
		return nil, format(normal, 2, 'save', 'string', type2)
	end

	local rtype = self._types[type]
	if not rtype or #rtype == 0 then
		return nil, format(warning, 'value', 'type', nil, 'save')
	end

	path = path or self:getPath('auto_saves')

	if apply(path .. type, format(saves_f, type), rtype, 'module') then
		return update(type, path)
	else
		return nil, format(warning, 'value', 'apply', nil, 'save')
	end
end

local function load(self, type, path)
	local type1, type2 = _type(type), _type(path)
	if type1 ~= 'string' then
		return nil, format(normal, 1, 'load', 'string', type1)
	elseif path and type2 ~= 'string' then
		return nil, format(normal, 2, 'load', 'string', type1)
	end

	local types = self._types or {}
	self._types = types

	path = path or self:getPath('auto_saves')
	local load = search(path .. type .. '.json', format(saves_f, type))

	if load then
		local correct_scope = type:sub(1, 1):upper() .. type:sub(2, #type -1)
		for n, ch in pairs(load) do
			if find(self, 'new'..correct_scope, 2) then
				self['new'..correct_scope](self, ch)
			elseif find(self, 'set'..correct_scope, 2) then
				self['set'..correct_scope](self, n, ch)
			else self._types[type] = load or self._types[type] break
			end
		end
	end

	return load and true
end

local read, copy = table.read, table.copy

local function readOnlyClient(client)
	return read({
		isInit = function(self)
			return client and client.user and true or false
		end,
		get = function(self)
			return self.isInit and client or nil
		end
	}, true, true)
end

local function setClient(self, client)
	local type1, type2 = type(self), type(client)
	if type1 ~= 'table' then
		return nil, format(normal, 1, 'setClient', 'table', type1)
	elseif type2 ~= 'table' then
		return nil, format(normal, 2, 'setClient', 'table', type2)
	end

	self.client = readOnlyClient(client)
	return self
end

local type_path = 'types/'
local channels, paths  = type_path .. 'channels', type_path .. 'paths'

local constructors = {
	channels = channels, paths = paths
}

local extra = require 'extra'

return setmetatable({
	save = save,
	load = load,
	setClient = setClient,
	package = function() return require './package' end
}, {
	__call = function(self, options)
		self._default_paths = default_paths; self._default_errors = default_errors

		self._types = {}
		for i, v in pairs(constructors) do
			require(v)(self); self._types[i] = {}
		end

		local saves = search(default_path .. 'options.json', '_path_saves') or {}
		if type(saves) == 'table' then
			for name, path in pairs(saves) do
				self:load(name, path)
			end
		end

		if self.client then
			self.client._init = self.client.isInit
		end

		for name, fn in pairs(extra) do self[name] = fn end

		self._path = self._types.paths.data_store_path or default_paths.data_store_path

		return self
	end,
	__newindex = function(self, key, value)
		if self[key] then
			return error(format('Cannot overwrite protected propertie: %s', key), 3)
		end

		return rawset(self, key, value)
	end
})