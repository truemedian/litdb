--[[lit-meta
	name = 'Corotyest/inspect'
	version = '1.3.0'
]]

-- upgraded, minor changes.

local getuserdata = debug.getuservalue
local sfind, format, rep , gsub = string.find, string.format, string.rep, string.gsub
local concat, sort = table.concat, table.sort

local colors = {
	['nil'] = '1;30',
	['string'] = '1;34',
	['thread'] = '1;35',
	['number'] = '1;33',
	['boolean'] = '1;36',
	['function'] = '1;31',
	['userdata'] = '0?'
}

local function isMethod(value)
	return type(value) == 'string' and sfind(value, '__', 1, true) == 1 or nil
end

local function getn(list)
	local num = 0
	for _ in pairs(list) do
		num = num + 1
	end
	return num
end

local function quote(str)
	local quote = sfind(str, '\'', 1, true)
	if quote then
		return format('"%s"', str), '\''
	elseif sfind(str, '"', 1, true) then
		return format('\'%s\'', str), '"'
	else
		return format('\'%s\'', str)
	end
end

local function join(sep, ...)
	if not ... then return nil end

	local base = {...}
	local response = { }
	for _, value in pairs(base) do
		response[#response + 1] = type(value) == 'string' and value or nil
	end

	return quote(concat(response, sep or ' ')), nil
end

local function setcolor(value, special)
	special = special or type(value)
	return '\27[' .. (colors[special] or '0') .. 'm' .. value .. '\27[0m'
end

local controls = {
	['\t'] = 't',
	['\r'] = 'r',
	['\f'] = 'f',
	['\\'] = '\\',
	['\a'] = 'a',
	["\'"] = "'",
	['\n'] = 'n',
	['\"'] = '"',
	['\v'] = 'v',
	['\b'] = 'b'
}

local function escape(value)
	return '\\' .. (controls[value] or '')
end

local function _format(self, value, options)
	local type1 = type(value)
	local usecolor = options and options.usecolor and options.usecolor == true

	if type1 == 'table' then
		local _, v = self.encode(value, options)
		return _ or v == 'last' and (options and options.recycle_udata and 'userdata: self' or 'table: self')
	elseif type1 == 'userdata' then
		if options then options.recycle_udata = true end
		local _, v = self.encode(getuserdata(value), options or {recycle_udata = true})
		return _ or v == 'last' and 'userdata: self'
	elseif type1 == 'number' then
		return usecolor and setcolor(value, type1) or value
	elseif type1 == 'string' then
		value = join(nil, gsub(tostring(value), '[%c\128-\255]', escape))
		return usecolor and setcolor(value, type1) or value
	elseif type1 == 'boolean' or type1 == 'nil' then
		return usecolor and setcolor(tostring(value), type1) or tostring(value)
	else
		value = join(nil, tostring(value))
		return usecolor and setcolor(value, type1) or value
	end
end

local function __get(index, options)
	local type1 = type(index)
	index = gsub(index, '[%c\\\128-\255]', escape)
	local form = _format(nil, index, options)
	if type1 == 'string' and sfind(gsub(index, '_', ''), '[%d%p%s]+') then
		return format('[%s]', form) or form
	else
		return (type1 == 'number' or tonumber(index)) and format('[%s]', form) or index
	end
end

local function field(self, index, value, options)
	local type1, type3 = type(index), type(options)
	if type1 ~= 'string' then
		if type1 ~= 'number' then return nil end
	elseif options and type3 ~= 'table' then
		return nil
	end

	local spaces = options and options.spaces == true
	local tabs = options and (spaces and ' ' or options.tabs ~= false and rep('\t', options and options.tabs or 1))

	local isplat = type1 == 'number'
	local plat = isplat and self.plat0 or type1 == 'string' and self.plat1 or self.plat1

	plat = format(plat, tabs or '', '%s', '%s')

	return isplat and format(plat, _format(self, value, options)) or
		format(plat, __get(index, options), _format(self, value, options))
end

local seen = { }

local function sortFn(_in, out)
	local value, value1 = _in[2], out[2]
	if type(value) == 'table' and not seen[value] then
		sort(value, sortFn); seen[value] = true
	end
	if type(value1) == 'table' and not seen[value1] then
		sort(value1, sortFn); seen[value] = true
	end

	if value then seen[value] = seen[value] and nil end; if value1 then seen[value1] = seen[value1] and nil end

	local index, index1 = _in[1], out[1]
	local i, i1 = type(index), type(index1)

	if i == 'number' then
		return i1 == 'number' and index < index1 or index1 and i1 ~= 'number' and index > #index1
	else
		return i1 ~= 'number' and (index and index1) and #index < #index1
	end
end

local function order(table, fn)
	local type1 = type(table)
	if type1 ~= 'table' then
		return nil
	elseif fn and type(fn) ~= 'function' then
		return nil, 'argument #2 for order is not a function'
	end

	local response = { }

	for index, value in pairs(table) do
		response[#response + 1] = { index, value }
	end

	sort(response, fn or sortFn)
	return next, response
end

-- pourpose only for pass `self`
local inspect = {
	getn = getn,
	join = join,
	order = order,
	plat0 = '%s%s',
	plat1 = '%s%s = %s',
	field = field,
	quote = quote,
	format = format,
	usecolors = true
}

local last

function inspect.encode(value, options)
	local type1, type2 = type(value), type(options)
	if type1 ~= 'table' then
		return _format(inspect, value, options)
	elseif options and type2 ~= 'table' then
		return nil, 'argument #2 must be table'
	end

	if last == value then last = nil; return nil, 'last' end
	last = value

	options = options or {} -- skip errors
	local tabs = not options.spaces and options.tabs
	options.tabs = tabs and tabs + 1 or tabs ~= false and 1; tabs = options.tabs

	local content = getn(value)
	if content == 0 then return options.usecolor == true and setcolor('{}', 'nil') or '{}' end

	local methods = { }
	local response = { }

	for _, data in order(value, options.sortFn) do
		local key, value = data[1], data[2]
		local field = field(inspect, key, value, options)

		if isMethod(key) then
			methods[#methods + 1] = field
		else
			response[#response + 1] = field
		end
	end

	local spaces = options and options.spaces == true

	local consumer = spaces and ' ' or tabs ~= nil and tabs ~= false and tabs ~= 1 and rep('\t', tabs - 1) or ''
	local concatenate = #response ~= 0 and (spaces and ' ' or '\n') or ''

	methods = #methods ~= 0 and (spaces and concat(methods, ', ') or concat(methods, ',\n')) or ''
	response = #response ~= 0 and (spaces and concat(response, ', ') or concat(response, ',\n')) or ''

	return format('{%s%s%s}', spaces and ' ' or '\n', format('%s%s%s',
		methods,
		response,
		concatenate
	), consumer)
end

local console = io.stdout

--- Writes directly to stdout, but in a beatiful format [, set inspect `usecolors` nil to write without colors] [, set inspect `spaces`
--- to use spaces instead tabs].
---@vararg any
function _G.show(...)
	for index = 1, select('#', ...) do
		console:write(inspect.encode(select(index, ...), { usecolor = inspect.usecolors, spaces = inspect.spaces }))
		console:write'\t'
	end
	console:write'\n'
end

inspect.show = show

--- Writes directly to stdout
---@vararg any
function inspect.print(...)
	for index = 1, select('#', ...) do
		local value = select(index, ...)
		console:write(tostring(value))
		console:write'\t'
	end
	console:write'\n'
end

return inspect