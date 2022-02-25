local dump = string.dump

local last, dlast = nil, nil

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
			response[key] = dump(value, true)
		else
			response[key] = value
		end -- readable reasons
	end

	return response
end

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
			local success, error = load(value, nil, 'b', env)
			if not success and error:find('wrong mode') then
				response[key] = value
			else
				response[key] = success or error
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