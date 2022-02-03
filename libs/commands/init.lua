local modules = {}
local where = './music/libs/commands/'

local function resolve(what, name)
	local type1 = type(what)
	if type1 ~= 'table' then
		if type1 == 'function' then
			return resolve(
				setmetatable({ name }, {
					__call = what
				})
			)
		else
			return nil
		end
	else
		local meta = getmetatable(what)
		meta = meta and meta.__call
		if meta then return what else return nil end
	end
end

require 'fs'.readdir(where, function(_, files)
	if _ then return nil end
	for i,v in pairs(files) do
		if not v:find('init') then
			v = v:gsub('.lua', '')
			local id = #modules + 1
			local slot = resolve(require(where..v),v)
			slot._parent = function() return modules end

			modules[id] = slot
		end
	end
end)

return modules