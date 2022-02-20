--[[lit-meta
	name = 'Corotyest/inspect'
	version = '0.1.0-1'
]]

local format, rep = string.format, string.rep
local getn = table.getn

local types = {
	['nil'] = true,
	['table'] = true,
	['number'] = true,
	['boolean'] = true,
	['userdata'] = true,
	['function'] = true,
}

local function _format(v)
	local type = type(v)
	local _str = tostring(v)

	if types[type] then
		return _str
	elseif type == 'string' then
		return format('\'%s\'', _str)
	else
		return format('[%s].new(%s)', type, _str)
	end
end

local function encode(_, list, tabs)
	local n = getn(list)

	local response = ''
	tabs = tabs or 1

	for _index, _value in next, list do
		local isTable = type(_value) == 'table'

		tabs = tabs .. format('%s[%s] = %s\n',
			rep('\t', tabs),
			_format(_index),
			not isTable and _format(_value) or encode(nil, _value, tabs + 1)
		)
	end

	return format('{%s}', format('%s%s%s',
		n~=0 and '\n' or '',
		response,
		n~=0 and rep('\t', tabs - 1) or ''))
end

return setmetatable({
	types = types,
	format = _format,
	encode = encode
}, {
	__call = encode
})