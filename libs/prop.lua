--[[
	author = 'Corotyest'
	version = '1.0.2bw'
]]

local function getn(table)
	local n = 0
	for _ in pairs(table) do
		n = n +1
	end
	return n
end

local function newProp()
	local props = { }
	local clean = { }

	local function add(key, name)
		local value = clean[key] or { }
		value[#value+1] = name

		clean[key] = value
	end

	function props.holder(key)
		local clean = clean[key] or clean

		local index, value
		return function(...)
			index, value = next(clean, index)
			return index, value
		end
	end

	function props:iter()
		local holder = self.holder()
		return function()
			local index = holder()
			return index, self:rawget(index)
		end
	end

	function props:rawset(key, value)
		local n = getn(clean) + 1
		self[n] = value
		add(key, n)
	end

	function props:rawget(key)
		local holder = clean[key]
		return holder and self[holder[#holder]]
	end

	function props:remove(key, name, unhold)
		clean[key][name] = nil

		if unhold then
			props[name] = nil
		end
	end

	function props:sanitize(key)
		for name, unhold in self.holder(key) do
			self:remove(key, name, unhold and true)
		end

		return self
	end

	local meta = {
		__len = function()
			return #props
		end,
		__index = function(_, key)
			return props[key]
		end,
		__newindex = function(_, key, value)
			if props[key] ~= nil then
				return error('cannot overwrite a protected value', 2)
			end

			return rawset(props, key, value)
		end,

		__pairs = function(self)
			return function(_, index)
				return next(props, index)
			end, self, nil
		end
	}

	meta.__metatable = { }

	function props:setName(value)
		if type(value) ~= 'string' then
			return nil
		end

		function meta:__tostring()
			return value
		end
	end

	return setmetatable({}, meta)
end

return newProp