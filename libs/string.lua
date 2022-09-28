---Extensions to the Lua standard string library.
---@module extensions.string
---@alias ext_string
local byte, char, find, gsub, len = string.byte, string.char, string.find, string.gsub, string.len
local match, rep, sub, upper = string.match, string.rep, string.sub, string.upper

local concat, insert = table.concat, table.insert
local ceil, floor, min, random = math.ceil, math.floor, math.min, math.random

local ext_string = {}

for k, v in pairs(string) do
	ext_string[k] = v
end

---Returns whether or not the string ends with `pattern`. Use `plain` if you want to match `pattern` literally.
---@param str string
---@param pattern string
---@param[opt] plain boolean
---@return boolean
function ext_string.endswith(str, pattern, plain)
	if plain then
		return string.sub(str, - #pattern) == pattern
	else
		if pattern:sub(-1) == '$' then
			pattern = pattern .. '$'
		end

		return not not string.find(str, pattern, 1)
	end
end

local pattern_special = [[^$()%.[]*+-?]]
local pattern_match = '[' .. pattern_special:gsub('.', '%%%1') .. ']'

---Returns a new string with all Lua Pattern special characters escaped.
---@param str string
---@return string
function ext_string.patternescape(str)
	return (gsub(str, pattern_match, '%%%1'))
end

---Returns whether or not the string starts with `pattern`. Use `plain` if you want to match `pattern` literally.
---@param str string
---@param pattern string
---@param[opt] plain boolean
---@return boolean
function ext_string.startswith(str, pattern, plain)
	return find(str, pattern, 1, plain) == 1
end

---Returns a new string with all leading and trailing whitespace removed.
---A pattern may be provided to instead strip using that pattern.
---@param str string
---@param pattern? string
---@return string
function ext_string.trim(str, pattern)
	pattern = pattern or '%s'
	assert(#pattern > 0)

	return match(str, '^' .. pattern .. '*(.-)' .. pattern .. '*$')
end

---Returns a new string with the left padded with `pattern` or spaces until the string is `final_len` characters long.
---@param str string
---@param final_len number
---@param[opt] pattern string
---@return string
function ext_string.padright(str, final_len, pattern)
	pattern = pattern or ' '
	return rep(pattern, (final_len - #str) / #pattern) .. str
end

---Returns a new string with both sides padded with `pattern` or spaces until the string is `final_len` characters long.
---@param str string
---@param final_len number
---@param[opt] pattern string
---@return string
function ext_string.padcenter(str, final_len, pattern)
	pattern = pattern or ' '
	local pad = 0.5 * (final_len - #str) / #pattern
	return rep(pattern, floor(pad)) .. str .. rep(pattern, ceil(pad))
end

---Returns a new string with the right padded with `pattern` or spaces until the string is `final_len` characters long.
---@param str string
---@param final_len number
---@param[opt] pattern string
---@return string
function ext_string.padleft(str, final_len, pattern)
	pattern = pattern or ' '
	return str .. rep(pattern, (final_len - #str) / #pattern)
end

---Returns a table of all elements of the string split on `delim`. Use `plain` if the delimiter provided is not a pattern.
---@param str string
---@param[opt] delim string
---@param[opt] plain boolean
---@return table
function ext_string.split(str, delim, plain)
	local ret = {}

	if not str or str == '' then
		return ret
	end

	if not delim or delim == '' then
		for i = 1, #str do
			ret[i] = byte(str, i)
		end

		return ret
	end

	local p = 1
	while true do
		local i, j = find(str, delim, p, plain)
		if not i then
			break
		end

		insert(ret, sub(str, p, i - 1))
		p = j + 1
	end

	insert(ret, sub(str, p))
	return ret
end

---Returns a string of `final_len` random characters in the byte-range of `[mn, mx]`. By default `mn = 0` and `mx = 255`.
---@param final_len number
---@param[opt] mn number
---@param[opt] mx number
---@return string
function ext_string.random(final_len, mn, mx)
	local ret = {}
	mn = mn or 0
	mx = mx or 255

	for _ = 1, final_len do
		insert(ret, char(random(mn, mx)))
	end

	return concat(ret)
end

---Returns the Levenshtein distance between the two strings. This is often referred as "edit distance".
---[Wikipedia "Levenshtein Distance"](https://en.wikipedia.org/wiki/Levenshtein_distance)
---@param str1 string
---@param str2 string
---@return number
function ext_string.levenshtein(str1, str2)
	if str1 == str2 then
		return 0
	end

	local len1 = len(str1)
	local len2 = len(str2)

	if len1 == 0 then
		return len2
	elseif len2 == 0 then
		return len1
	end

	local matrix = {}
	for i = 0, len1 do
		matrix[i] = { [0] = i }
	end

	for j = 0, len2 do
		matrix[0][j] = j
	end

	for i = 1, len1 do
		for j = 1, len2 do
			local cost = byte(str1, i) == byte(str2, j) and 0 or 1
			matrix[i][j] = min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j - 1] + cost)
		end
	end

	return matrix[len1][len2]
end

---Returns the Damerau-Levenshtein distance between the two strings. This is often referred as "edit distance".
---[Wikipedia "Damerau-Levenshtein Distance"](https://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance)
---@param str1 string
---@param str2 string
---@return number
function ext_string.dameraulevenshtein(str1, str2)
	if str1 == str2 then
		return 0
	end

	local len1 = len(str1)
	local len2 = len(str2)

	if len1 == 0 then
		return len2
	elseif len2 == 0 then
		return len1
	end

	local matrix = {}
	for i = 0, len1 do
		matrix[i] = { [0] = i }
	end

	for j = 0, len2 do
		matrix[0][j] = j
	end

	for i = 1, len1 do
		for j = 1, len2 do
			local cost = byte(str1, i) == byte(str2, j) and 0 or 1
			matrix[i][j] = min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j - 1] + cost)
			if i > 1 and j > 1 and byte(str1, i) == byte(str2, j - 1) and byte(str1, i - 1) == byte(str2, j) then
				matrix[i][j] = min(matrix[i][j], matrix[i - 2][j - 2] + 1)
			end
		end
	end

	return matrix[len1][len2]
end

---Returns true if the subsequence can be found inside `str`.
---For example: `ggl` is a subsequence of `GooGLe`. (uppercase letters signify which letters form the subsequence).
---@param subseq string
---@param str string
---@return boolean
function ext_string.subsequencematch(subseq, str)
	local matches = 0

	for i = 1, len(str) do
		if byte(subseq, matches + 1) == byte(str, i) then
			matches = matches + 1
		end
	end

	return matches == len(subseq)
end

return ext_string
