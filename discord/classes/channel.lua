local core = require('core')

local Channel = core.Object:extend()

function Channel:initialize(data, server)

	self.server = server -- parent object

	self.id = data.id -- string
	self.name = data.name -- string
	self.type = data.type -- string
	self.topic = data.topic -- string
	self.bitrate = data.bitrate -- number
	self.position = data.position -- number
	self.lastMessageId = data.lastMessageId -- string
	self.permissionOverwrites = data.permissionOverwrites -- table (need to objectify)

end

return Channel