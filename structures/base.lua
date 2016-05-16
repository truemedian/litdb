local class = require('../classes/class')

local base = class()

function base:__constructor (parent)
	self.parent = parent
end

function base:update (data)
	for k,v in pairs(data) do
		self[k] = v
	end
	self:onUpdate()
end

function base:onUpdate ()
end

return base