local self = {}

--- Returns the minimum value of the max value of n.
---@param n number
---@param mn number
---@param mx number
---@return number
function self.clamp(n, mn, mx)
	return math.min(math.max(n, mn), mx)
end

function self.EOF(EOF)
	return EOF
end

return self