local endpoints = require('../endpoints')
local request = require('../utils').request

local Channel = require('core').Object:extend()

function Channel:initialize(data, server)

	self.server = server
	self.client = server.client

	self.id = data.id -- string
	self.name = data.name -- string
	self.type = data.type -- string
	self.topic = data.topic -- string
	self.bitrate = data.bitrate -- number
	self.position = data.position -- number
	self.isPrivate = data.isPrivate -- boolean
	self.lastMessageId = data.lastMessageId -- string
	self.permissionOverwrites = data.permissionOverwrites -- table (need to objectify)

	self.messages = {}

end

function Channel:update(data)

	self.name = data.name
	self.topic = data.topic
	self.bitrate = data.bitrate
	self.position = data.position
	self.permissionOverwrites = data.permissionOverwrites -- table (need to objectify)

end

function Channel:setName(name)
	local body = {name = name, position = self.position, topic = self.topic}
	request('PATCH', {endpoints.channels, self.id}, self.client.headers, body)
end

function Channel:setTopic(topic)
	local body = {name = self.name, position = self.position, topic = topic}
	request('PATCH', {endpoints.channels, self.id}, self.client.headers, body)
end

function Channel:setPosition(position) -- moveUp/Down?
	local body = {name = self.name, position = position, topic = self.topic}
	request('PATCH', {endpoints.channels, self.id}, self.client.headers, body)
end

function Channel:delete(channel)
	request('DELETE', {endpoints.channels, self.id}, self.client.headers)
end

function Channel:broadcastTyping()
	request('POST', {endpoints.channels, self.id, 'typing'}, self.client.headers, {})
end

function Channel:sendMessage(content)
	local body = {content = content}
	request('POST', {endpoints.channels, self.id, 'messages'}, self.client.headers, body)
end

function Channel:getMessageById(id) -- Client:getMessageById(id), Server:getMessageById(id)
	return self.messages[id]
end

return Channel
