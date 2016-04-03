local User = require('./user')
local Deque = require('./deque')
local request = require('../utils').request
local endpoints = require('../endpoints')

local PrivateChannel = require('core').Object:extend()

function PrivateChannel:initialize(data, client)

	self.client = client

	self.id = data.id -- string
	self.isPrivate = data.isPrivate -- boolean
	self.lastMessageId = data.lastMessageId -- string

	local user = client:getUserById(data.recipient.id)
	if not user then
		user = User:new(data, self)
		client.users[user.id] = user
	else
		user:update(data, self)
	end
	self.recipient = user

	self.messages = {}
	self.deque = Deque:new()

end

function PrivateChannel:delete()
	request('DELETE', {endpoints.channels, self.id}, self.client.headers)
end

function PrivateChannel:broadcastTyping()
	request('POST', {endpoints.channels, self.id, 'typing'}, self.client.headers, {})
end

function PrivateChannel:sendMessage(content)
	local body = {content = content}
	request('POST', {endpoints.channels, self.id, 'messages'}, self.client.headers, body)
end

function PrivateChannel:getMessageById(id) -- Client:getMessageById(id), Server:getMessageById(id)
	return self.messages[id]
end

return PrivateChannel
