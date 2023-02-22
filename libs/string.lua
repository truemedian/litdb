local self = {}

local random = math.random
local format, sfind, lower, sub, match = string.format, string.find, string.lower, string.sub, string.match
local gmatch, char, gsub = string.gmatch, string.char, string.gsub
local remove, insert, concat = table.remove, table.insert, table.concat

local error_format = 'bad argument #%s for %s (%s expected got %s)'

local compare = _G.compare

--- Compare string `self` with string `pattern`; you can give diferent [, `level`] for those comparisions:
--- nil, 0 or 'equal' to compare equality of `self` and `pattern`,
--- 1 or 'lwreq' to compare lowered values of `self` and `pattern`,
--- 2 or 'find' to find `pattern` in `self` considered as magic,
--- 3 or 'lwrfind' to find lowered `pattern` in lowered `self`.
---@param self string
---@param pattern string
---@param init? number @only works with levels upper to 1
---@param level? number/string
---@return boolean
function self.compare(self, pattern, init, level)
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
		return sfind(self, pattern, init) and true or nil
	elseif level == 3 or level == 'lwrfind' then
		return sfind(lower(self), lower(pattern), init) and true or nil
	end

	return nil
end

-- extension functions for `string.extract`

-- detect if string `s` got `word` followed by `sing`, return the value after it
local function got_sing(s, word, sing)
	local start, last = sfind(s, word)
	if not start and not last then return nil end
	s = gsub(sub(s, last + 1), '^%s*', '')
	return sub(s, 1, 1) == sing, s
end

-- compact the removition of spaces and `sing`
local function slot(s, word, sing, trim)
	sing, s = got_sing(s, word, sing)
	if not sing then
		return nil
	else
		local value = sub(s, 2)
		if trim then value = self.trim(value) end
		return value
	end
end

-- removes unexpected `word` followed by `sing` of string `s`
local function remove_(s, word, sing, trim)
	local sn = sfind(s, word .. '%s*' .. sing)
	local value = sn and sub(s, 0, sn - 1) or s
	return trim and self.trim(value) or value
end

--- Tries to get the values in `self` contents in `extract` followed by `sing`, as optional is `trim` to remove all spaces in start
--- and the end of any value match.
---@param self string
---@param extract table
---@param sign? string
---@param trim? boolean
---@return table
function self.extract(self, extract, sing, trim)
	local type1, type2, type3 = type(self), type(extract), type(sing)
	if type1 ~= 'string' then
		return error(format(error_format, 1, 'string.extract', 'string', type1))
	elseif type2 ~= 'table' then
		return error(format(error_format, 2, 'string.extract', 'table', type2))
	elseif sing and type3 ~= 'string' then
		return error(format(error_format, 3, 'string.extract', 'string', type3))
	end

	sing = type(sing) == 'string' and sing or '='

	local fn
	local keywords = extract[1]; keywords = type(keywords) == 'table' and keywords
	for index, value in pairs(extract) do
		local type4 = type(value)
		if type4 ~= 'string' then
			if type4 == 'function' and not fn then fn = value end
			extract[index] = nil
		end
	end -- search for any field that is not a string

	local base, response = {extract, keywords}, {}

	-- match value `key`, but removing `extract` contents followed by `sing`
	local function autocomplete(key)
		local slot = slot(self, key, sing, trim)
		for _, base in pairs(base) do
			if type(base) == 'table' then
				for _, _key in pairs(base) do
					if type(_key) == 'string' and _key ~= key then
						slot = slot and remove_(slot, _key, sing, trim) or slot
					end
				end
			end
		end
		return slot
	end

	for hash, index in pairs(extract) do
		hash = type(hash) == 'string' and hash or index
		if type(index) == 'string' then
			local value = autocomplete(index)
			response[hash] = fn and fn(value, hash) or value
		end
	end

	return response
end

--- Generates a new random string in base of length `len`, char minimum `mn` and maximum `mx`.
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
		return error(format(error_format, 'vararg', 'string.split', 'any', nil))
	end

	local sformat = format('([^%%%s]+)', concat({...}, '%'))

	local response = {}
	for split in gmatch(self, sformat) do
		if split ~= self then
			response[#response + 1] = split
		end
	end
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