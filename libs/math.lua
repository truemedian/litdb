--[[
	author = 'Corotyest'
	version = '1.0.0-bw'
]]

local self = {}

local format = string.format
local min, max = math.min, math.max

local error_format = 'bad argument #%s for %s (%s expected got %s)'


--- Returns the minimum value of the maximum value of n.
---@param n number
---@param mn number
---@param mx number
---@return number
function self.clamp(n, mn, mx)
	local type1, type2, type3 = type(n), type(mn), type(mx)
	if type1 ~= 'number' then
		return error(format(error_format, 1, 'math.clamp', 'number', type1), 2)
	elseif type2 ~= 'number' then
		return error(format(error_format, 2, 'math.clamp', 'number', type2), 2)
	elseif type3 ~= 'number' then
		return error(format(error_format, 3, 'math.clamp', 'number', type3), 2)
	end

	return min(max(n, mn), mx)
end

function self.EOF(EOF)
	return EOF
end

return self