local classes = require('../classes')
local class = classes.new
local base = require('./base')

local Message = class(base)

function Message:onUpdate ()
	if self.channel then
		self.channel = self.parent.channels:get('id', self.channel_id)
	end
	if self.author then
		self.author = self.parent.users:get('id', self.author.id)
	end
end

function Message:reply (content)
	if not self.is_private then
		content = '<@!'..self.author.id..'> '..content
	end
	return self.parent:sendMessage(self.channel, content)
end

return Message