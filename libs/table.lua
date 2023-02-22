local self = {}
local compare = _G.compare

local format, sfind, sub = string.format, string.find, string.sub
local insert = table.insert

local error_format = 'bad argument #%s for %s (%s expected got %s)'

local types = 'nil/table/number/string/thread/boolean/function/userdata'
--- Copy a entire table base on `indexOnly` this is optional.
---@param self table
---@param self? table
---@param indexOnly? boolean
---@return table
function self.copy(self, list, indexOnly)
	local type1, type2 = type(self), type(list)
	if type1 ~= 'table' then
		return error(format(error_format, 1, 'copy', 'table', type1))
	elseif list and type2 ~= 'table' then
		if not indexOnly and type2 == 'boolean' then
			indexOnly = true
		else
			return error(format(error_format, 2, 'copy', 'table', type2))
		end
	end

	local tab = list or {}

	for index, value in pairs(self) do
		local v, type3 = not indexOnly and value, type(value) == 'table'
		tab[indexOnly and #tab+1 or index] = type3 and table.copy(value, nil, indexOnly) or v or index
	end

	return tab
end

--- Tries to find `value` in table `self`, if `deep` is passed scan all fields of type table to find `value`.
---@param self table
---@param value any
---@param deep? boolean
---@return any
function self.find(self, value, deep)
	local type1, type2 = type(self), type(value)
	if type1 ~= 'table' then
		return error(format(error_format, 1, 'table.find', 'table', type1))
	elseif type2 == 'nil' then
		return error(format(error_format, 2, 'table.find', 'any', type2))
	end

	local are = type2 == 'string'
	local typeof = are and sfind(types, sub(value, 2)) and true

	for key, data in pairs(self) do
		local type3 = type(data)
		if typeof and compare(sub(value, 2), type3) then
			return data, key
		elseif compare(value, data) or compare(value, key) then
			return data, key
		elseif type3 == 'table' and deep then
			local data = { table.find(data, value, true) }

			local _has = table.getn(data) > 0
			if _has then
				insert(data, 2, key)
				return unpack(data)
			end
		end
	end

	return nil
end

--- Count indexes of table `self` (numbers and keys).
---@param self table
---@return number
function self.getn(self)
	local type1 = type(self)
	if type1 ~= 'table' then
		return error(format(error_format, 1, 'table.getn', 'table', type1))
	end

	local count = 0
	for _ in pairs(self) do
		count = count + 1
	end
	return count
end

--- Similar to `table.getn`, as diference goes on deep in table `self`.
---@param self table
---@return number
function self.deepn(self)
	local type1 = type(self)
	if type1 ~= 'table' then
		return error(format(error_format, 1, 'table.getn', 'table', type1))
	end

	local count = 0
	for _, v in pairs(self) do
		count = count + 1
		count = type(v) == 'table' and (count + table.deepn(v)) or count
	end
	return count
end

--- Make value readable only, as optional `docopy` for copy it and show it as strings.
---@param meta any
---@param docopy? boolean
---@param auto_call? boolean
---@return table
function self.read(self, docopy, auto_call)
	self = type(self) == 'table' and self or {self}

	local copy = docopy and table.copy(self, nil, true) or {}

	return setmetatable(copy, {
		__index = function(_, key)
			local value = rawget(self, key)
			if type(value) == 'function' then
				return auto_call and value(self) or value
			else
				local env = self.env
				return value or env and env[key]
			end
		end
	})
end

--! This function has a dependencie: libs/string.split

--- Tries to find the best predication of string `s` in table `self`, if not return a error message.
---@param self table
---@param s string
---@return any
function self.search(self, s)
	local type1, type2 = type(self), type(s)
	if type1 ~= 'table' then
		return error(format(error_format, 1, 'table.search', 'table', type1))
	elseif type2 ~= 'string' then
		return error(format(error_format, 2, 'table.search', 'string', type2))
	end

	local split = string.split(s, '.')

	local num = table.getn(split)
	if num == 0 then
		return self[s]
	end

	local attach
	for n, value in pairs(split) do
		if n ~= num then
			if not attach then
				attach = self[value]
			else
				attach = attach[value]
			end
		else
			if attach then
				local _, n = table.find(attach, value)
				if not n then
					return nil, format('Not finded value %s in %s', value, attach)
				end

				return attach[value] or attach[n]
			end
		end
	end
end

--- Sets a obligatory table based on `korv` in table `self`
---@param self table
---@param korv any
function self.set(self, korv)
	local type1 = type(self)
	if type1 ~= 'table' then
		return error(format(error_format, 1, 'table.set', 'table', type1))
	end

	local _, n = table.find(self, korv)
	if n then
		local v1, v2 = self[n], self[korv]
		if v1 and type(v1) ~= 'table' then
			self[n] = nil; self[n] = {v1}
		elseif v2 and type(v2) ~= 'table' then
			self[korv] = nil; self[korv] = {v2}
		end
	else
		self[korv] = {}
	end
end

--! This function has a dependencie: libs/string.split

function self.sinsert(self, s, value)
	local type1, type2, type3 = type(self), type(s), type(value)
	if type1 ~= 'table' then
		return error(format(error_format, 1, 'table.sinsert', 'table', type1))
	elseif type2 ~= 'string' and type3 == 'nil' then
		insert(self, s); return table.find(self, s) and true
	elseif value == 'remove' then
		value = nil
	end

	local split = string.split(s, '.')
	local num = table.getn(split)

	if num == 0 then
		self[s] = value
		return table.find(self, s) and true
	end

	local attach
	for n, str in pairs(split) do
		str = tonumber(str) or str
		if n ~= num then
			if not attach then
				table.set(self, str); attach = self[str]
			else
				table.set(attach, str); attach = attach[str]
			end
		else
			if attach then
				attach[str] = value

				return attach[str] == value and true or nil
			end

			return nil
		end
	end
end

function self.EOF(EOF)
	return EOF
end

return self