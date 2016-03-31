local core = require('core')

local VoiceState = core.Object:extend()

function VoiceState:initialize(data, server)

	self.server = server -- parent object
	
	self.mute = data.mute -- boolean
	self.deaf = data.deaf -- boolean
	self.userId = data.userId -- string
	self.suppress = data.suppress -- boolean
	self.selfDeaf = data.selfDeaf -- boolean
	self.selfMute = data.selfMute -- boolean	
	self.sessionId = data.sessionId -- string
	self.channelId = data.channelId -- string

end

return VoiceState