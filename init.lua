---examples: `local colors = enum({RED = 0xFF0000});` `local red = colors.RED;` `local name = colors(0xFF0000);
---@param name string|table
---@param tbl table|nil
---@return table enum
local function enum(name, tbl)
    if type(name) == "table" then
        tbl = name
        name = nil
    end
    local str = name and string.format("<enum '%s'>", name) or "enum"
    name = name or "enum"
	local call = {}
	for k, v in pairs(tbl) do
		if call[v] ~= nil then
			return error(string.format('enum clash for %q and %q', k, call[v]))
		end
		call[v] = k
	end
    local length = 0
    for _,_ in pairs(tbl) do
        length = length + 1
    end
	return setmetatable({}, {
		__call = function(_, k)
			if call[k] ~= nil then
				return call[k]
			else
				return error('invalid enumeration: ' .. tostring(k))
			end
		end,
		__index = function(_, k)
			if tbl[k] ~= nil then
				return tbl[k]
			else
				return error('invalid enumeration: ' .. tostring(k))
			end
		end,
		__pairs = function()
			return next, tbl
		end,
		__ipairs = function()
			return error('cannot use ipairs on an enumeration')
		end,
		__newindex = function()
			return error('cannot overwrite enumeration')
		end,
		__len = function()
			return length
		end,
		__tostring = function()
			return "enum"
		end,
		__name = "enum"
	})
end

return enum