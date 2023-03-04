--[[
	author = 'Corotyest'
	version = '1.0.0-bw'
]]

local self = {}

-- local strlib, tablib, mathlib = nil, require './table', require './math'
local utils = require 'utils'
local compare, resolve = utils.compare, utils.resolve

local random = math.random
local insert, concat = table.insert, table.concat
local format, sfind, lower, sub, match = string.format, string.find, string.lower, string.sub, string.match
local gmatch, char = string.gmatch, string.char

local error_format = 'bad argument #%s for %s (%s expected got %s)'


--- Compares the string `self` with the string `pattern`; you can give diferent [, `level`] for those comparisions: <br>
--- → nil, 0 or 'equal' to compare equality of `self` and `pattern`, <br>
--- → 1 or 'lwreq' to compare lowered values of `self` and `pattern`, <br>
--- → 2 or 'find' to find `pattern` in `self` considered as magic, <br>
--- → 3 or 'lwrfind' to find lowered `pattern` in lowered `self`. <br>
---@param self string
---@param pattern string
---@param init? number @only works with levels upper to 1
---@param level? number | string
---@return true | nil
function self.compare(self, pattern, init, level)
	local type1, type2 = type(self), type(pattern)
	if type1 ~= 'string' then
		return error(format(error_format, 1, 'string.compare', 'string', type1))
	elseif type2 == 'nil' or type2 == 'function' then
		return error(format(error_format, 2, 'string.compare', 'string/number/table', type2))
	end

	pattern = resolve(pattern, 'string')
	local ptrn = type2 == 'string' and lower(pattern)
	if not level or level == 0 or level == 'equal' then
		return compare(self, pattern)
	elseif level == 1 or level == 'lwreq' then
		return compare(lower(self), lower(pattern))
	elseif ptrn and (level == 2 or level == 'find') then
		return sfind(self, pattern, init) and true or nil
	elseif ptrn and (level == 3 or level == 'lwrfind') then
		return sfind(lower(self), lower(pattern), init) and true or nil
	end

	return nil
end

--- Remaking this documentation.

--- Possibly add those local functions to the `string` library.

local extractForm = '%s[%s]*[%s]'

local function join(f, ...)
	local base = {...}
	if #base == 0 then
		return nil
	elseif not f then
		f = '%%%s'
	end

	local str = ''
	for _, value in pairs(base) do
		str = str .. (type(value) == 'table' and join(f, unpack(value)) or format(f, value))
	end
	return str
end

local function revoke(s, track, symbol, ignore)
	for i, value in pairs(track) do
		if i ~= ignore and value ~= ignore then
			local _, start, f = s:extract(value, symbol)
			if f and start then
				s = sub(s, 1, start - 1)
			end
		end
	end

	return s
end


function self.extract(self, extract, symbol, init, trim)
	local type1, type2, type3 = type(self), type(extract), type(symbol)
	if type1 ~= 'string' then
		return error(format(error_format, 1, 'string.extract', 'string', type1))
	elseif type2 ~= 'string' and type2 ~= 'table' then
		return error(format(error_format, 2, 'string.extract', 'string/table', type2))
	elseif symbol and (type3 ~= 'string' and type3 ~= 'table') then
		return error(format(error_format, 3, 'string.extract', 'string/table?', type3))
	end

	if type2 == 'table' and #extract == 0 then
		return nil, 'argument #2 is a `table` but has no index values.'
	elseif type3 == 'table' and #symbol == 0 then
		return nil, 'argument #3 is a `table` but has no index values.'
	end

	symbol = join(nil, symbol) or '%='

	if type2 == 'string' then
		local s, f = sfind(self, format(extractForm, extract, '%s', symbol), init)
		local value = f and sub(self, f + 1)
		return value and (trim == true and value:trim() or value), s, f
	end

	local extracts = { }
	for _, value in ipairs(extract) do
		if type(value) == 'string' then
			local content = self:extract(value, symbol, nil, trim)
			content = revoke(content, extract, symbol, value)
			extracts[value] = trim == true and content:trim() or content
		end
	end

	return extracts
end

--- Generates a new random string in base of length `len` (width), minimum `mn` and maximum `mx` character of the string.
--- Returns the *"pseudo"* string.
---@param len number
---@param mn? number
---@param mx? number
---@return string
function self.random(len, mn, mx)
	local type1, type2, type3 = type(len), type(mn), type(mx)
	if type1 ~= 'number' then
		return error(format(error_format, 1, 'string.random', 'number', type1))
	elseif mn and type2 ~= 'number' then
		return error(format(error_format, 2, 'string.random', 'number', type1))
	elseif mx and type3 ~= 'number' then
		return error(format(error_format, 3, 'string.random', 'number', type1))
	end

	local ret = {}
	mn = mn or 0
	mx = mx or 255
	for _ = 1, len do
		insert(ret, char(random(mn, mx)))
	end

	return concat(ret)
end

--- Cuts the string `self` as the passed through vararg `...` and return the *split* in a `table`.
---@param self string
---@vararg string
---@return table
function self.split(self, can, ...)
	local type1, type2 = type(self), type(can)
	if type1 ~= 'string' then
		return error(format(error_format, 1, 'string.split', 'string', type1))
	elseif type2 ~= 'string' and not ... then
		return error(format(error_format, 'vararg', 'string.split', 'any', nil))
	end

	local base = {...}
	if type2 == 'string' then base[#base + 1] = can end
	local sformat = format('([^%%%s]+)', concat(base, '%'))

	local response = {}
	for split in gmatch(self, sformat) do
		if (type2 == 'boolean' and can == false) or split ~= self then
			response[#response + 1] = split
		end
	end
	return response
end

--- Cuts the spaces that the string `self` got in, and return string.
---@param self string
---@return string
function self.trim(self)
	local type1 = type(self)
	if type1 ~= 'string' then
		return error(format(error_format, 1, 'string.trim', 'string', type1))
	end

	return match(self, '^%s*(.-)%s*$')
end

function self.EOF(EOF)
	return EOF
end

return self