--[[lit-meta
	name = 'Corotyest/format'
	author = 'Corotyest'
	version = '1.0.0bw'
]]

--[=[
	This module has the commission of encode functions as strings so you can make these portable, and to decode
	the functions that were encoded with this system.
]=]

local dump = string.dump

local last, dlast = nil, nil

--- Encodes any of `value` that contains a function in to a `string`. <br>
--- Return the encoded `value` inside of a passed `table` or directly as `string`.
---@param value any
---@return string | any
local function encode(value)
	local _type = type(value)
	if _type ~= 'table' then
		return _type == 'function' and dump(value, true) or value
	end

	if last == value then
		return value
	end

	last = value

	local response = { }

	for key, value in pairs(value) do
		local type1 = type(value)
		if type1 == 'table' then
			response[key] = encode(value)
		elseif type1 == 'function' then
			response[key] = dump(value, true) -- encode(value)
		else
			response[key] = value
		end -- readable reasons
	end

	return response
end

--- Decode any `value` that passed through the first argument (*if it is possible*). <br>
--- Return it as a function.
---@param value any
---@param env table?
---@return function | table
local function decode(value, env)
	local _type = type(value)

	if _type ~= 'table' then
		return _type == 'string' and load(value, nil, 'b', env) or value
	end

	if dlast == value then
		return value
	end

	dlast = value

	local response = { }

	for key, value in pairs(value) do
		local type1 = type(value)
		if type1 == 'table' then
			response[key] = decode(value, env)
		elseif type1 == 'string' then
			local data, error_msg = load(value, nil, 'b', env)
			if error_msg and error_msg:find('wrong mode') then
				response[key] = value
			else
				response[key] = data or error_msg
			end
		else
			response[key] = value
		end
	end

	return response
end

return {
	dump = dump,
	encode = encode,
	decode = decode
}