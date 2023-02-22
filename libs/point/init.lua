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

	for key, name in next, options or {} do
		new[key] = not new[key] and name or nil
	end

	local slot = setmetatable(core, {
		__index = function(core, key)
			return new[key] or self[key]
		end,
		__newindex = function(_, k, v)
			if not new[k] then new[k] = v end
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