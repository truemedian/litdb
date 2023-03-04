--[[
	author = 'Corotyest'
	version = '1.0.0-bw'
]]

local self = {}

local utils = require 'utils'
local strlib = require './string' -- tablib, mathlib = require './table', require './math'

local insert = table.insert
local compare = utils.compare
local format, sfind, sub, split = string.format, string.find, string.sub, strlib.split

local error_format = 'bad argument #%s for %s (%s expected got %s)'

local types = 'nil/table/number/string/thread/boolean/function/userdata'


--- Copy a entire table base on `indexOnly` this is optional.
---@param list table
---@param tab? table
---@param indexOnly? boolean
---@return table
function self.copy(list, tab, indexOnly)
	local type1, type2 = type(list), type(tab)
	if type1 ~= 'table' then
		return error(format(error_format, 1, 'copy', 'table', type1))
	elseif type2 ~= 'table' then
		if not tab then
			tab = {}
		elseif not indexOnly and type2 == 'boolean' then
			indexOnly = true
		else
			return error(format(error_format, 2, 'copy', 'table', type2))
		end
	end

	for index, value in pairs(list) do
		local val = not indexOnly and value
		tab[indexOnly and #tab+1 or index] = (type(val) == 'table' and self.copy(val, nil, indexOnly)) or val or index
	end

	return tab
end

--- Tries to find `value` in table `list`, if `deep` is passed scan all fields of type table to find `value`.
---@param list table
---@param value any
---@param deep? boolean
---@return any
function self.find(list, value, deep)
	local type1, type2 = type(list), type(value)
	if type1 ~= 'table' then
		return error(format(error_format, 1, 'table.find', 'table', type1))
	elseif type2 == 'nil' then
		return error(format(error_format, 2, 'table.find', 'any', type2))
	end

	local are = type2 == 'string'
	local typeof = are and sfind(types, sub(value, 2)) and true

	for key, data in pairs(list) do
		local type3 = type(data)
		if typeof and compare(sub(value, 2), type3) then
			return data, key
		elseif compare(value, data) or compare(value, key) then
			return data, key
		elseif type3 == 'table' and deep then
			local data = { self.find(data, value, true) }

			local _has = self.getn(data) > 0
			if _has then
				insert(data, 2, key)
				return unpack(data)
			end
		end
	end

	return nil
end

--- Count indexes of table `list` (numbers and keys).
---@param list table
---@return number
function self.getn(list)
	local type1 = type(list)
	if type1 ~= 'table' then
		return error(format(error_format, 1, 'table.getn', 'table', type1))
	end

	local count = 0
	for _ in pairs(list) do
		count = count + 1
	end
	return count
end

--- Similar to `table.getn`, as diference goes on deep in table `list`.
---@param list table
---@return number
function self.deepn(list)
	local type1 = type(list)
	if type1 ~= 'table' then
		return error(format(error_format, 1, 'table.getn', 'table', type1))
	end

	local count = 0
	for _, v in pairs(list) do
		count = count + 1
		count = type(v) == 'table' and (count + self.deepn(v)) or count
	end
	return count
end

--- Make value readable only, as optional `docopy` for copy it and show it as strings.
---@param list any
---@param docopy? boolean
---@param auto_call? boolean
---@return table
function self.read(list, docopy, auto_call)
	list = type(list) == 'table' and list or {list}

	local copy = docopy and self.copy(list, nil, true) or {}

	return setmetatable(copy, {
		__index = function(_, key)
			local value = rawget(list, key)
			if type(value) == 'function' then
				return auto_call and value(list) or value
			else
				local env = list.env
				return value or env and env[key]
			end
		end
	})
end

--! This function has a dependencie: libs/string.split

--- Tries to find the best predication of string `s` in table `list`, if not found then return an error message.
---@param list table
---@param s string
---@return any, any
function self.search(list, s)
	local type1, type2 = type(list), type(s)
	if type1 ~= 'table' then
		return error(format(error_format, 1, 'table.search', 'table', type1))
	elseif type2 ~= 'string' then
		return error(format(error_format, 2, 'table.search', 'string', type2))
	end

	local split = split(s, '.')

	local num = self.getn(split)
	if num == 0 then
		return list[s]
	end

	local attach
	for n, value in pairs(split) do
		if n ~= num then
			local nvalue = tonumber(value)
			if not attach then
				attach = list[value] or list[nvalue]
			else
				attach = attach[value] or attach[nvalue]
			end
		else
			if not attach then
				attach = list
			end

			local _, n = self.find(attach, value)
			if not n then
				return nil, format('Not finded value %s in %s', value, attach)
			end

			return attach[value] or attach[n]
		end
	end
end

--- Sets a obligatory table based on `korv` in table `list`
---@param list table
---@param korv any
function self.set(list, korv)
	local type1 = type(list)
	if type1 ~= 'table' then
		return error(format(error_format, 1, 'table.set', 'table', type1))
	end

	local _, n = self.find(list, korv)
	if n then
		local v1, v2 = list[n], list[korv]
		if v1 and type(v1) ~= 'table' then
			list[n] = nil
			list[n] = {v1}
		elseif v2 and type(v2) ~= 'table' then
			list[korv] = nil
			list[korv] = {v2}
		end
	else
		list[korv] = {}
	end
end

--! This function has a dependencie: libs/string.split

function self.sinsert(list, s, value)
	local type1, type2, type3 = type(list), type(s), type(value)
	if type1 ~= 'table' then
		return error(format(error_format, 1, 'table.sinsert', 'table', type1))
	elseif type2 ~= 'string' and type3 == 'nil' then
		insert(list, s)
		return self.find(list, s) and true
	elseif value == 'remove' then
		value = nil
	end

	local split = split(s, false, '.')

	local num = self.getn(split)
	if num == 0 then
		list[s] = value
		return self.find(list, s) and true
	end

	local attach
	for n, str in pairs(split) do
		if n ~= num then
			if not attach then
				self.set(list, str); attach = list[str]
			else
				self.set(attach, str); attach = attach[str]
			end
		else
			attach = attach or list
			attach[str] = value

			return attach[str] == value and true or nil
		end
	end
end

function self.EOF(EOF)
	return EOF
end

return self