local endpoints = require('../endpoints')
local request = require('../utils').request
local User = require('./user')
local Object = require('./object')

local Message = class(Object)

function Message:__init(data, channel)

	Object.__init(self, data.id, channel.client)

	self.channel = channel
	self.server = channel.server

	self.nonce = data.nonce -- string
	self.embeds = data.embeds -- table
	self.content = data.content -- string
	self.mentions = data.mentions -- table
	self.timestamp = data.timestamp -- string
	self.channelId = data.channelId -- string
	self.attachments = data.attachents -- table
	self.mentionEveryone = data.mentionEveryone -- boolean

	local user = channel.client:getUserById(data.author.id)
	if not user then
		user = User(data, self)
		channel.client.users[user.id] = user
	else
		user:update(data, self)
	end
	self.author = user

end

function Message:update(data)

	self.embeds = data.embeds
	self.content = data.content or self.content
	self.mentions = data.mentions or self.mentions
	self.attachments = data.attachents or self.attachments
	self.editedTimestamp = data.editedTimestamp or self.editedTimestamp
	self.mentionEveryone = data.mentionEveryone or self.mentionEveryone

end

function Message:setContent(content)
	local body = {content = content}
	request('PATCH', {endpoints.channels, self.channelId, 'messages', self.id}, self.client.headers, body)
end

function Message:delete()
	request('DELETE', {endpoints.channels, self.channelId, 'messages', self.id}, self.client.headers)
end

function Message:acknowledge()
	request('POST', {endpoints.channels, self.channelId, 'messages', self.id, 'ack'}, self.client.headers, {})
end

return Message
