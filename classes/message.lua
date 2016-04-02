local endpoints = require('../endpoints')
local request = require('../utils').request

local User = require('./user')

local Message = require('core').Object:extend()

function Message:initialize(data, channel)

	self.channel = channel
	self.server = channel.server
	self.client = channel.client

	self.id = data.id -- string
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
		user = User:new(data, self)
		channel.client.users[user.id] = user
	else
		user:update(data, self)
	end
	self.author = user

end

function Message:update(data)

	self.embeds = data.embeds
	self.content = data.content
	self.mentions = data.mentions
	self.attachments = data.attachents
	self.editedTimestamp = data.editedTimestamp
	self.mentionEveryone = data.mentionEveryone

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
