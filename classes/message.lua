local core = require('core')

local User = require('./user')

local Message = core.Object:extend()

function Message:initialize(data, channel)

	self.channel = channel -- parent object
	
	self.id = data.id -- string
	self.mentionEveryone = data.mentionEveryone -- boolean
	self.nonce = data.nonce -- string
	self.mentions = data.mentions -- table
	self.embeds = data.embeds -- table
	self.timestamp = data.timestamp -- string
	self.content = data.content -- string
	self.channelId = data.channelId -- string
	self.attachments = data.attachents -- table
	self.author = User:new(data.author) -- object

end

return Message
