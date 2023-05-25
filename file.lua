--[[lit-meta
	name = 'Corotyest/inspect'
	version = '2.1.0'
]]

local console = io.output()

local userdata = debug.getuservalue
local concat, sort = table.concat, table.sort
local format, sfind, rep, gsub = string.format, string.find, string.rep, string.gsub

local function getn(self)
	local response = 0
	for _ in pairs(self) do
		response = response + 1
	end
	return response
end

local function quote(value)
	local type1 = type(value)
	if type1 ~= 'string' then
		value = tostring(value)
		-- return value
	end

	local quote = sfind(value, '\'', 1, true)
	if quote then
		return format('"%s"', value), '\''
	elseif sfind(value, '"', 1, true) then
		return format('\'%s\'', value), '"'
	else
		return format('\'%s\'', value)
	end
end

local function getIndex(value)
	local type1 = type(value)
	if type1 == 'number' or type1 == 'string' and sfind(gsub(value, '_', ''), '[%c%p%s]+') then
		return format('[%s]', type1 ~= 'number' and quote(value) or value)
	end

	return value
end

local form = '%s = %s'
local function formatIndex(index, value, tabLevel)
	-- value = type(value) ~= 'string' and tostring(value) or quote(value)
	return (tabLevel and rep('\t', tabLevel) or '') .. format(form, getIndex(index), tostring(value))
end

local function isMethod(value)
	return type(value) == 'string' and sfind(value, '__', 1, true) == 1
end

local seen = {}

local function sortFn(state, compare)
	if type(state) == 'function' or type(compare) == 'function' then
		return
	end


	local value, value1 = state[2], compare[2]
	if type(value) == 'table' and not seen[value] then
		seen[value] = true
		sort(value, sortFn)
	end
	if type(value1) == 'table' and not seen[value1] then
		seen[value] = true
		sort(value1, sortFn)
	end

	if value then seen[value] = seen[value] and nil end
	if value1 then seen[value1] = seen[value1] and nil end

	local index, index1 = state[1], compare[1]
	local i, i1 = type(index), type(index1)

    if i == 'number' then
		return i1 == 'number' and index < index1 or index1 and i1 ~= 'number' and index > #index1
	else
		return i1 ~= 'number' and (index and index1) and #index < #index1
	end
end

local function order(table, fn)
	local response = { }

	for index, value in pairs(table) do
		response[#response + 1] = { index, value }
	end

	sort(response, fn or sortFn)
	return next, (response)
end

local function cycled(value, type)
	return quote(format('cycled: %s', type))
end

local cycle = nil
local function encode(value, tabs, spaces)
	local type1 = type(value)
    if type1 ~= 'table' then
		if type1 ~= 'userdata' then
			return quote(tostring(value))
        end

		value = userdata(value)
	end

	if cycle == value then
		return nil, 'last'
	end

	cycle = value
	local n = getn(value)
	if n == 0 then
		return '{}'
	end

	local jumpIn, dualSeparator = not spaces and '\n' or ' ', (',%s'):format(spaces and '  ' or '\n')

	tabs = not spaces and tabs or 1
	local methods = { }
	local response = { }

	for _, data in order(value) do
		local key, value = data[1], data[2]

		local type2 = type(value)

		local encoded, status = encode(value, not spaces and tabs + 1, spaces)
		if encoded == cycle then
			status = 'last'
		end
        encoded = status ~= 'last' and encoded or status == 'last' and cycled(value, type2)

        if not encoded then
			goto continue
		end

		local field = formatIndex(key, encoded, not spaces and tabs)
		if isMethod(key) then
			methods[#methods + 1] = field
		else
			response[#response + 1] = field
		end

		::continue::
	end

--  first separator ↓
	return format('{%s%s%s%s}',
		jumpIn,
		format('%s%s%s', concat(methods, dualSeparator), #methods ~= 0 and jumpIn or '', concat(response, dualSeparator)),
		jumpIn,
		tabs ~= 1 and rep('\t', tabs - 1) or ''
	)
end

local function highPrint(...)
    local base = { ... }
	for _, value in pairs(base) do
        console:write(encode(value))
		console:write '\t'
    end
	console:write '\n'
end

return setmetatable({
    getn = getn,
	sort = sort,
    quote = quote,
	cycled = cycled,
	encode = encode,
    isMethod = isMethod,
    formatIndex = formatIndex,

    console = console,
	inspect = highPrint,
	highPrint = highPrint,
}, {
	__call = function(_, ...)
		return encode(...)
	end
})