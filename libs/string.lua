local self = {}

local random = math.random
local format, sfind, lower, sub, match = string.format, string.find, string.lower, string.sub, string.match
local gmatch, char = string.gmatch, string.char
local remove, insert, concat = table.remove, table.insert, table.concat

local error_format = 'bad argument #%s for %s (%s expected got %s)'

local compare = _G.compare

--- Compare string `self` with string `pattern`; you can give diferent [, `level`] for those comparisions:
--- 0 or 'equal' to compare equality of `self` and `pattern`,
--- 1 or 'lwreq' to compare lowered values of `self` and `pattern`,
--- 2 or 'find' to find `pattern` in `self` considered as magic,
--- 3 or 'lwrfind' to find lowered `pattern` in lowered `self`.
---@param self string
---@param pattern string
---@param level? number/string
---@return boolean
function self.compare(self, pattern, level)
	local type1, type2 = type(self), type(pattern)
	if type1 ~= 'string' then
		return error(format(error_format, 1, 'string.compare', 'string', type1))
	elseif type2 == 'nil' or type2 == 'function' then
		return error(format(error_format, 2, 'string.compare', 'string/number/table', type2))
	end

	pattern = tostring(pattern)
	if not level or level == 0 or level == 'equal' then
		return compare(self, pattern)
	elseif level == 1 or level == 'lwreq' then
		return compare(lower(self), lower(pattern))
	elseif level == 2 or level == 'find' then
		return sfind(self, pattern) and true or nil
	elseif level == 3 or level == 'lwrfind' then
		return sfind(lower(self), lower(pattern)) and true or nil
	end

	return nil
end

local function got_sing(s, word, sing)
	local start, last = sfind(s, word)
	if not start and not last then return nil end

	local str = sub(s, last + 1):gsub('^[%d%s]+', '')
	return sub(str, 1, 1) == sing, str
end

local function slot(s, word, sing, rem_chars)
	local got_sing, str = got_sing(s, word, sing)
	if not got_sing then
		return nil
	else
		local val = sub(str, 2)
		if not rem_chars then val = val:gsub('[%p%s]+$', ''):gsub('^[%s%p]+', '') end
		return val
	end
end

local function remove_(s, word, sing, rem_chars)
	local sn = sfind(s, word .. '%s+' .. sing) or sfind(s, word .. sing)
	local value = sn and sub(s, 0, sn - 1) or s
	return not rem_chars and value:gsub('[%p%s]+$', '') or value
end

--- Tries to extract the values located in `extract` followed by the `sing` or '=', a optional field of extract
--- is keywords, insert it as first index and erases if matches some of it values.
---@param self string
---@param extract table
---@param sign? string
---@return table
function self.extract(self, extract, sing)
	local type1, type2, type3 = type(self), type(extract), type(sign)
	if type1 ~= 'string' then
		return error(format(error_format, 1, 'string.extract', 'string', type1))
	elseif type2 ~= 'table' then
		return error(format(error_format, 2, 'string.extract', 'table', type2))
	elseif sing and type3 ~= 'string' then
		return error(format(error_format, 3, 'string.extract', 'string', type3))
	end

	sing = sing or '='

	local keywords
	for index, value in pairs(extract) do
		if type(value) == 'table' then
			if index ~= 1 then return nil, 'To remove keywords the index expected is 1.' end
			keywords = value; remove(value, 1)
		end
	end

	local base, response = {extract, keywords}, {}

	local function autocomplete(key)
		local slot = slot(self, key, sing)
		for _, base in pairs(base) do
			if type(base) == 'table' then
				for _, _key in pairs(base) do
					if type(_key) == 'string' and _key ~= key then
						slot = slot and remove_(slot, _key, sing) or slot
					end
				end
			end
		end
		return slot
	end

	for _, index in pairs(extract) do
		if type(index) == 'string' then
			response[index] = autocomplete(index)
		end
	end

	return response
end

--- Generates a new random string in base of length `len`, minimum `mn` and maximum `mx`.
---@param len number
---@param mn number
---@param mx number
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

--- Tries to split string `self` in base to `...`.
---@param self string
---@vararg string
---@return table
function self.split(self, ...)
	local type1 = type(self)
	if type1 ~= 'string' then
		return error(format(error_format, 1, 'string.split', 'string', type1))
	elseif not ... then
		return error(format(error_format, 'varag', 'string.split', 'any', nil))
	end

	local sformat = format('([^%q]+)', concat({...}, '%'))

	local response = {}
	for split in gmatch(self, sformat) do response[#response + 1] = split end
	return response
end

--- Tries to trim string `self`.
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