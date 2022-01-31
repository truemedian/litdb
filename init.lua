--- Tries to compare self with integrants of `...` if varag is more than 1 returns table.
---@param self any
---@vararg any
---@return boolean/table
local function compare(self, ...)
	if not self then return nil, string.format(
		'bad argument #%s for %s (%s expected got %s)', 1, 'compare', 'any', nil) end
	local n = select('#', ...)
	if n == 0 then
		return nil, string.format(
			'bad argument #%s for %s (%s expected got %s)', 'varag', 'compare', 'any', 'nil')
	elseif n == 1 then
		return rawequal(self, select(n, ...)) or self == select(n, ...)
	else
		local response = {}
		for _n = 1, n do
			local value = select(_n, ...); response[value] = compare(self, value)
		end
		return response
	end
end

_G.compare = compare
local ext = setmetatable({
	table = require './libs/table',
	string = require './libs/string',
	math = require './libs/math',
}, {__call = function(self)
	for _, v in pairs(self) do
		v()
	end
end})

for n, m in pairs(ext) do
	setmetatable(m, {__call = function(self)
		for k, v in pairs(self) do
			_G[n][k] = v
		end
	end})
end

return ext