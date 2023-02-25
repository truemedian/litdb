local format = string.format
local badArg = 'bad argument #%s for %s (%s expected got %s)'

--- Tries to compare self with integrants of `...`; if varag is more than 1 returns table.
---@param self any
---@vararg any
---@return boolean | table
local function compare(self, ...)
	if not self then return nil, format(badArg, 1, 'compare', 'any', nil) end

	local n = select('#', ...)
	if n == 0 then
		return nil, format(badArg, 'varag', 'compare', 'any', 'nil')
	elseif n == 1 then
		local value = select(n, ...)
		return rawequal(self, value) or self == value
	else
		local response = {}
		for _n = 1, n do
			local value = select(_n, ...)
			response[value] = compare(self, value)
		end
		return response
	end
end


--- Verify if `v` is of type `rawType`, optionally you can pass more types in to vararg `...`.
---@param v any
---@param rawType any
---@vararg any
---@return boolean
local function istype(v, rawType, ...)
	if not ... then
		return compare(type(v), tostring(rawType))
	end

	local base = {rawType, ...}
	for _, value in pairs(base) do
		value = istype(v, value)
		if value then return true end
	end

	return false
end

local function has(str, has)
	if not istype(str, 'string', 'string') then
		return nil
	end

	return str:find(has)
end

---@return any
local function getmetamethod(v, method)
	if istype(v, 'table', 'userdata') then
		local meta = getmetatable(v)
		if not meta then
			return nil
		end

		if has(method, '__') ~= 1 then
			method = ('__' .. method)
		end

		return meta[method] or nil
	end

	return nil
end

local function getmetatype(v, type)
	local method = getmetamethod(v, has(type, 'to') ~= 1 and ('to' .. type) or type)

	if istype(method, 'function') then
		local value = method(v)
		return istype(value, type) and value or nil
	end
end

local function tonil(...)
	return nil
end

-- DO THESE FUNCTIONS "NEED TO" USE `istype`?

local rawtonumber = tonumber
local function tonumber(v)
	local type = type(v)
	if type == 'number' then
		return v
	elseif type == 'table' or type == 'userdata' then
		return getmetatype(v, 'number')
	else
		return rawtonumber(v)
	end
end

local function toboolean(v)
	local type = type(v)
	if type == 'boolean' then
		return v

	elseif type == 'number' then
		return (v == 1 and true) or (v == 0 and false) or nil
	elseif type == 'string' then
		return (v == 'true' and true) or (v == 'false' and false) or nil
	elseif type == 'table' or type == 'userdata' then
		return getmetatype(v, 'boolean')
	end

	return nil
end

local types = {
	['nil'] = tonil,
	-- table = totable,
	number = tonumber,
	string = tostring,
	boolean = toboolean,
	-- function = tofunction,
	-- userdata = touserdata,


	-- CFunction = tocfunction,
}

local function resolve(object, rawType)
	local totype = types[rawType or 'string']
	if not totype then
		return nil, format(badArg, 2, 'resolve', '[supported type]', rawType)
	elseif not istype(object, 'table', 'userdata') then
		return totype(object)
	end

	local hasMetaType = getmetamethod(object, ('to' .. rawType))
	if hasMetaType then
		return totype(object)
	end
end

local function complexResolve(object, rawType, ...)
	local response = { }
	if not ... then
		if istype(object, 'table') then
			if not getmetatable(object) then
				for index, value in pairs(object) do
					response[index] = complexResolve(value, rawType)
				end

				return response
			end
		end

		if istype(rawType, 'table') then
			for _, type in pairs(rawType) do
				local value = resolve(object, type)
				--p(value, object, type)
				response[#response+1] = value
			end
		end

		return response
	end

	local len = select('#', ...)
	if len == 1 or len%2 == 1 then
		object = {object, ...}
		return complexResolve(object, rawType)
	end

	local values = complexResolve(object, rawType)
	for key, type in pairs(values) do
		response[key] = type
	end

	local base = {...}
	for index, value in pairs(base) do
		if index%2 == 1 then
			response[#response+1] = resolve(value, base[index + 1] or rawType)
		end
	end

	return response
end

_G.compare, _G.resolve, _G.complexResolve = compare, resolve, complexResolve

return setmetatable({
	math = require './libs/math',
	table = require './libs/table',
	string = require './libs/string',
}, {
	__call = function(self, notGlobal)
		for key, tab in pairs(self) do
			if not _G[key] and not notGlobal then
				_G[key] = tab
			elseif _G[key] and not notGlobal then
				for name, fn in pairs(tab) do
					_G[key][name] = fn
				end
			else
				local lib = _G[key] or { }
				for k, v in pairs(lib) do
					tab[k] = v
				end
			end
		end

		return self
	end
})