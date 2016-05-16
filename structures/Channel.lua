local class = require('../classes/class')
local base = require('./base')

local Channel = class(base)

function Channel:onUpdate ()
	self.isVoice = (not self.topic and not self.last_message_id)
end

return Channel