return function(...)

	local class, bases = {}, {...}
	for _, base in ipairs(bases)  do
		for k, v in pairs(base) do
			class[k] = v
		end
	end

	class.__index = class
	class.__bases = bases

	-- local function initBases(class, obj, ...)
	-- 	for _, base in ipairs(class.__bases) do
	-- 		if type(base.__init) == 'function' then
	-- 			base.__init(obj, ...)
	-- 			initBases(base, obj, ...)
	-- 		end
	-- 	end
	-- end

	setmetatable(class, {
		__call = function(class, ...)
			local obj = setmetatable({}, class)
			-- initBases(class, obj, ...)
			if type(obj.__init) == 'function' then
				obj:__init(...)
			end
			return obj
		end
	})

	return class

end
