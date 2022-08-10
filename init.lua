--- Tries to compare self with integrants of `...`; if varag is more than 1 returns table.
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

return setmetatable({
	math = require './libs/math',
	table = require './libs/table',
	string = require './libs/string',
}, {
	__call = function(self, notGlobal)
		if self._active then return self end

		for key, tab in pairs(self) do
			if not _G[key] and not notGlobal then
				_G[key] = tab
			elseif _G[key] and not notGlobal then
				for name, fn in pairs(tab) do
					_G[key][name] = fn
				end
			else
				local lib = _G[key] or { }
				for k, v in pairs(lib) do
					tab[k] = v
				end
			end
		end

		return self
	end
})