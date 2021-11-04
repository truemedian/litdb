--[[lit-meta
  name = "Corotyest/lua-extentions"
  version = "1.0.0"
  description = "A simple couple of functions to ease access."
  tags = {"mem", "fast", "easy"}
  license = "MIT"
  author = { name = "Corotyest" }
]]

local format, sfind, sub, gmatch, lower = string.format, string.find, string.sub, string.gmatch, string.lower
local match, char = string.match, string.char
local random = math.random
local insert, remove, concat = table.insert, table.remove, table.concat

local error_format = 'Incorrect argument #%s for %s (%s expected got %s)'

local table, string = {}, {}

-- Compare raw val1 with val2 or metamethod __eq.
-- @param val1 any
-- @param val2 any
-- @return boolean
local function compare(val1, val2)
    if not val1 or not val2 then
        return nil
    end

    return (rawequal(val1, val2) or val1 == val2) and true or nil
end

-- Tries to trim string `s`.
-- @param s string
-- @return string
function string.trim(s)
    local type1 = type(s)
    if type1 ~= 'string' then
        return error(format(error_format, 1, 'string.trim', 'string', type1))
    end

	return match(s, '^%s*(.-)%s*$')
end

-- Tries to split string `s` with base `enpha` and `...`: if `enpha` are a string, otherwise uses it for index
-- duplicated values (exceding the last value by 1).
-- @param s string
-- @param enpha? boolean
-- @param ... varag
-- @return response : table
function string.split(s, enpha, ...)
    local type1 = type(s)
    if type1 ~= 'string' then
        return error(format(error_format, 1, 'string.split', 'string', type1))
    elseif not (...) and not enpha then
        return error(format(error_format, '...', 'string.split', 'any', nil))
    end

    local find = table.find

    local base = {...}
    if type(enpha) == 'string' then
        base = {enpha, unpack(base)}
        enpha = nil
    end

    base = concat(base, '%')
    local sformat = format('([^%q]+)', base)

    local response = {}
    for split in gmatch(s, sformat) do
        local num = find(response, split)
        if not num then
            insert(response, split)
        else
            if enpha then
                local quantity = rawget(response, split) or 1
                remove(response, num)
                response[split] = quantity + 1
            else
                insert(response, split)
            end
        end
    end

    return response
end

-- Tries to compare string `s` with `pattern` depending in `level`:
-- 0 or "equal" to compare equality of `s` and `pattern`,
-- 1 or "lwreq" to compare lowered values of `s` and `pattern`,
-- 2 or "find" to find `pattern` in `s` considered as magic,
-- 3 or "lwrfind" to find lowered `pattern` in lowered `s`.
-- @param s string
-- @param pattern string
-- @return boolean
function string.compare(s, pattern, level)
    local type1, type2 = type(s), type(pattern)
    if type1 ~= 'string' then
        return error(format(error_format, 1, 'string.compare', 'string', type1))
    elseif type2 == 'nil' or type2 == 'function' then
        return error(format(error_format, 2, 'string.compare', 'string/number/table', type2))
    end

    local ptrn = tostring(pattern)
    if not level or level == 0 or level == 'equal' then
        return compare(s, ptrn)
    elseif level == 1 or level == 'lwreq' then
        return compare(lower(s), lower(ptrn))
    elseif level == 2 or level == 'find' then
        return sfind(s, ptrn) and true or nil
    elseif level == 3 or level == 'lwrfind' then
        return sfind(lower(s), lower(ptrn)) and true or nil
    end

    return nil, 'value are not part of string (in string.compare).'
end

-- Tries to trim `word` followed by `sign` from string `s` and returns the result string.
-- @param s string
-- @param word string
-- @param sign string 
-- @return value
function string.slot(s, word, sign)
    local type1, type2, type3 = type(s), type(word), type(sign)
    if type1 ~= 'string' then
        return nil, format(error_format, 1, 'slot', 'string', type2)
    elseif type2 ~= 'string' then
        return nil, format(error_format, 2, 'slot', 'string', type2)
    elseif type3 ~= 'string' then
        return nil, format(error_format, 2, 'slot', 'string', type2)
    end

    local _, word = sfind(s, word)
    if not word then return nil end; word = sub(s, word + 1)

    local format = format('(%%%s+)', sign)
    local _, format = sfind(word, format)
    if not format then return nil end

    local res = sub(word, format + 1, #word):gsub('^%s+', '')
    return res
end

local slot = string.slot

local function strip(s, remove)
    local f = sfind(s, remove)
    return f and sub(s, 0, f - 1):gsub('%s+$', '')
end

-- Tries to extract- values from table `extract` as optional add a table at the first value of `extract`
-- to remove unwanted values. (the sign is optional and is used to the recognize values, default is =)
-- @param s string
-- @param extract table
-- @param sign? string 
-- @return response : table
function string.extract(s, extract, sign)
    local type1, type2, type3 = type(s), type(extract), type(sign)
    if type1 ~= 'string' then
        return error(format(error_format, 1, 'string.extract', 'string', type1))
    elseif type2 ~= 'table' then
        return error(format(error_format, 2, 'string.extract', 'table', type2))
    elseif sign and type3 ~= 'string' then
        return error(format(error_format, 3, 'string.extract', 'string', type3))
    end

    sign = sign or '='

    local tint, keywords = table.find(extract, '%table'), nil

    if tint and tint ~= 1 then
        return nil, 'table of keywords need be the first index.'
    elseif tint then
        keywords = extract[tint]; remove(extract, tint)
    end

    local base, response = {extract, keywords}, {}

    local function autoc(k)
        local ds = slot(s, k, sign)
        for _, b in pairs(base) do
            if type(b) == 'table' then
                for _, key in pairs(b) do
                    if type(key) == 'string' and key ~= k then
                        ds = strip(ds, key) or ds
                    end
                end
            end
        end
        return ds
    end

    for _, index in pairs(extract) do
        if type(index) == 'string' then
            response[index] = autoc(index)
        end
    end

    return response
end

local scompare = string.compare

local function count(table, value, level)
    local type1, type2 = type(table), type(value)
    if type1 ~= 'table' then
        return nil, (format(error_format, 1, 'table.count', 'table', type1))
    elseif type2 == 'nil' then
        return nil, (format(error_format, 2, 'table.count', 'any', type2))
    end

    local n, are = 1, type2 == 'string'

    for index, head in pairs(table) do
        local type3, type4 = are and type(index) == 'string', are and type(head) == 'string'
        if type3 and scompare(index, value) then
            return n
        elseif type4 and scompare(head, value) then
            return n
        elseif compare(index, value) or compare(head, value) then
            return n
        end
        n = n + 1
    end

    return nil, 'value are not part of table (in table.count).'
end

-- Generates a new random string in base of length `len`, minimum `mn` and maximum `mx`.
-- @param len number
-- @param mn number 
-- @param mx number
-- @return string
function string.random(len, mn, mx)
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

local count = table.count or count

local types = 'nil/table/number/string/thread/boolean/function/userdata'

-- Tries to find `value` in table `list`. If are any coincidence then return it index as a number (count all indexes)
-- The function use `string.compare` so you can use the level for the comparision in optional parameter `level`.
-- You can make use of `value` to find values type in `list` doing any character at the start of it string; otherwise returns nil.
-- @param list table
-- @param value any
-- @param level? number
-- @return error
-- @return index : number
function table.find(list, value, level)
    local type1, type2 = type(list), type(value)
    if type1 ~= 'table' then
        return error(format(error_format, 1, 'table.find', 'table', type1))
    elseif type2 == 'nil' then
        return error(format(error_format, 2, 'table.find', 'any', type1)) 
    end

    local are = type2 == 'string'
    local typeof = are and sfind(types, sub(value, 2)) and true

    for key, v in pairs(list) do
        local type3, type4 = type(key), type(v)

        local aren = type == 'number'
        if typeof and compare(sub(value, 2), type4) then
            return aren and key or count(list, key, level)
        elseif compare(value, key) or compare(value, v) then
            return aren and key or count(list, value, level)
        elseif are then
            type3, type4 = type3 == 'string', type4 == 'string'
            if type3 and scompare(value, key) then
                return aren and key or count(list, value, level)
            elseif type4 and scompare(value, v) then
                return aren and key or count(list, value, level)
            end 
        end
    end

    return nil, 'value are not a part of table (in table.find).'
end

-- Count indexes of table `list` (numbers and keys).
-- @param list table
-- @return number
function table.getn(list)
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

-- Similar to `table.getn`, as diference goes on deep in table `list`.
-- @param list table
-- @return number
function table.deepn(list)
    local type1 = type(list)
    if type1 ~= 'table' then
        return error(format(error_format, 1, 'table.getn', 'table', type1))
    end

    local count = 0
    for _, v in pairs(list) do
        count = count + 1
        count = type(v) == 'table' and (count + table.deepn(v)) or count
    end

    return count
end

-- Sets a obligatory table based on `korv` in table `list`
-- @param list table
-- @param korv any
function table.set(list, korv)
    local type1 = type(list)
    if type1 ~= 'table' then
        return error(format(error_format, 1, 'table.set', 'table', type1))
    end

    local n = table.find(list, korv)
    if n then
        local v1, v2 = list[n], list[korv]
        if v1 and type(v1) ~= 'table' then
            list[n] = nil; list[n] = {v1}
        elseif v2 and type(v2) ~= 'table' then
            list[korv] = nil; list[korv] = {v2}
        end
    else 
        list[korv] = {}
    end
end

-- Tries to insert `value` in table `list` in base to `s`. If `s` are not a string and are not `value` Tries
-- to insert `s` in table `list`, (optional `value` may be "remove" to convert it to nil). If sucess full insert
-- returns true.
-- @param list table
-- @param s string
-- @param s any
-- @param value? any
-- @param value? 'remove'
-- @return boolean
function table.sinsert(list, s, value)
    local type1, type2, type3 = type(list), type(s), type(value)
    if type1 ~= 'table' then
        return error(format(error_format, 1, 'table.sinsert', 'table', type1))
    elseif type2 ~= 'string' and type3 == 'nil' then
        insert(list, s); return table.find(list, s) and true
    elseif value == 'remove' then
        value = nil
    end

    local split = string.split(s, '.')
    local num = table.getn(split)

    if num == 0 then
        list[s] = value
        return table.find(list, s) and true
    end

    local attach
    for n, str in pairs(split) do
        str = tonumber(str) or str
        if n ~= num then
            if not attach then
                table.set(list, str); attach = list[str]
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

-- Looks for string `s` (that was splited) in table `list`, if in split are nothing returned search `list[s]`.
-- @param list table
-- @param s string
-- @return value
function table.search(list, s)
    local type1, type2 = type(list), type(s)
    if type1 ~= 'table' then
        return error(format(error_format, 1, 'table.search', 'table', type1))
    elseif type2 ~= 'string' then
        return error(format(error_format, 2, 'table.search', 'string', type2))
    end

    local split = string.split(s, '.')

    local num = table.get(split)
    if num == 0 then
        return list[s]
    end

    local attach
    for n, value in pairs(split) do
        if n ~= num then
            if not attach then
                attach = list[value]
            else
                attach = attach[value]
            end
        else
            if attach then
                n = table.find(attach, value)
                if not n then
                    return nil, format('Not finded value %s in %s', value, attach)
                end

                return attach[value] or attach[n]
            end
        end
    end
end

-- Copy a entire table base on `indexOnly` is optional, optional parameter two `table`.
-- @param self table
-- @param table? table 
-- @param indexOnly? boolean
-- @return table
function table.copy(self, table, indexOnly)
    local type1, type2 = type(self), type(table)
    if type1 ~= 'table' then
        return error(format(error_format, 1, 'copy', 'table', type1))
    elseif table and type2 ~= 'table' then
        if not indexOnly and type2 == 'boolean' then
            indexOnly = true
        else
            return error(format(error_format, 2, 'copy', 'table', type2))
        end
    end

    table = table or {}

    for index, value in pairs(self) do
        local i, v, type3 = not indexOnly and index, not indexOnly and value, type(value) == 'table'
        table[i or #table+1] = type3 and table.copy(value, nil, indexOnly) or v or index
    end

    return table
end

-- Make value readable only, as optiona `docopy` for copy it and show it as strings.
-- @param meta any
-- @param docopy? boolean
-- @return metatable
function table.read(meta, docopy)
    meta = type(meta) == 'table' and meta or {meta}

    local copy = docopy and table.copy(meta, nil, true) or {}

    return setmetatable(copy, {
        __index = function(self, key)
            local value = rawget(meta, key)
            if type(value) == 'function' then
                return value(self)
            else
                local env = meta.env
                return value or env and env[key]
            end
        end
    })
end

--MATH WON'T THROWN ERROR AS BEING NEUTRAL
function math.clamp(n, mn, mx)
    return math.min(math.max(n, mn), mx)
end

local ext = setmetatable({
	table = table,
	string = string,
	math = math,
}, {__call = function(self)
	for _, v in pairs(self) do
		v()
	end
end})

for n, m in pairs(ext) do
	setmetatable(m, {__call = function(self)
		for k, v in pairs(self) do
			_G[n][k] = v
		end
	end})
end

-- Turn on extentions (globally).
return ext