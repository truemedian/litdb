local core = require 'core'
local slots = { }

local function getStoreSlot(self, name, options)
	local type1, type2 = type(self), type(name)
	if type1 ~= 'table' then
		return nil, 'argument #self is not a table'
	elseif type2 ~= 'string' then
		return nil, 'argument #1 is not a string'
	elseif self.isA(name) then
		return slots[name]
	end

	slots[name] = true
	local new = { name = name }

	options = options or { }
	for name, value in pairs(core) do
		if options[name] == nil then
			options[name] = value
		end
	end

	for key, name in next, options do
		new[key] = not new[key] and name or nil
	end

	local slot = setmetatable(new, {
		__index = function(_, key)
			return rawget(new, key) or self[key]
		end,
		__tostring = function()
			return 'Slot @' .. name
		end
	})

	return slot
end

local function isA(object)
	return slots[object and object.name or object]
end

return {
	isA = isA,
	getStoreSlot = getStoreSlot,
}