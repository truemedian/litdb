local function set(self, prop, index, value)
	local osean = self.osean

	if osean[prop] then
		osean[prop][index] = value
	else
		osean[prop] = {
			[index] = value
		}
	end

	return self
end

local function get(self, prop, index)
	prop = self.osean[prop]

	return prop and prop[index]
end

local function remove(self, prop, index)
	local osean = self.osean

	if osean[prop] then
		osean[prop][index] = nil
	end

	return self
end

local osean
osean = {
	iter = function()
		local index, value
		return function()
			index, value = next(osean, index)
			if type(value) == 'function' then index, value = next(osean, index) end
			return index, value
		end
	end
}

return {
	set = set,
	get = get,
	osean = setmetatable({}, {
		__index = osean,
		__newindex = function(_, key, value)
			local type2 = type(value)
			if osean[key] and type2 ~= 'nil' then
				return error('cannot overwrite a protected property', 3)
			end
			
			osean[key] = value
		end
	}),
	remove = remove,
}