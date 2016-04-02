local endpoints = require('../endpoints')
local request = require('../utils').request

local Role = require('./role')
local User = require('./user')
local Channel = require('./channel')
local VoiceState = require('./voicestate')

local Server = require('core').Object:extend()

function Server:initialize(data, client)

	self.client = client

	self.id = data.id -- string
	self.name = data.name -- string
	self.icon = data.icon -- string
	self.large = data.large -- boolean
	self.region = data.region -- string
	self.ownerId = data.ownerId -- string
	self.joinedAt = data.joinedAt -- string
	self.afkTimeout = data.afkTimeout -- number
	self.memberCount = data.memberCount -- number
	self.afkChannelId = data.afkChannelId -- string
	self.verificationLevel = data.verificationLevel -- number

	self.emojis = data.emojis -- table, not sure what to do with this
	self.features = data.features -- table, not sure what to do with this

	self.roles = {}
	self.members = {}
	self.channels = {}
	self.voiceStates = {}

	for _, roleData in ipairs(data.roles) do
		local role = Role:new(roleData, self)
		self.roles[role.id] = role
	end

	for _, memberData in ipairs(data.members) do
		local user = client:getUserById(memberData.user.id)
		if not user then
			user = User:new(memberData, self)
			client.users[user.id] = user
		else
			user:update(memberData, self)
		end
		self.members[user.id] = user
	end

	for _, memberData in ipairs(data.presences) do
		local user = self.members[memberData.user.id]
		user:update(memberData)
	end

	for _, channelData in ipairs(data.channels) do
		local channel = Channel:new(channelData, self)
		self.channels[channel.id] = channel
	end

	for _, voiceData in ipairs(data.voiceStates) do
		local voiceState = VoiceState:new(voiceData, self)
		self.voiceStates[voiceState.sessionId] = voiceState
	end

end

function Server:setName(name)
	local body = {name = name}
	request('PATCH', {endpoints.servers, self.id}, self.client.headers, body)
end

function Server:setRegion(regionId)
	local body = {name = self.name, region = regionId}
	request('PATCH', {endpoints.servers, self.id}, self.client.headers, body)
end

function Server:leave()
	request('DELETE', {endpoints.me, 'guilds', self.id}, self.client.headers)
end

function Server:delete()
	request('DELETE', {endpoints.servers, self.id}, self.client.headers)
end

function Server:getBans()
	local banData = request('GET', {endpoints.servers, self.id, 'bans'}, self.client.headers)
	-- cache on ready event?
	-- return raw ban data, table of banned Users, or table of Ban objects?
end

function Server:getInvites()
	local inviteData = request('GET', {endpoints.servers, self.id, 'invites'}, self.client.headers)
	-- cache on ready event?
	-- return raw invite data or Invite objects?
end

function Server:banUser(user) -- User:ban(server)
	request('PUT', {endpoints.servers, self.id, 'bans', user.id}, self.client.headers, {})
end

function Server:unbanUser(user) -- User:unban(server)
	request('DELETE', {endpoints.servers, self.id, 'bans', user.id}, self.client.headers)
end

function Server:kickUser(user) -- User:kick(server)
	request('DELETE', {endpoints.servers, self.id, 'members', user.id}, self.client.headers)
end

function Server:getRoleById(id) -- Client:getRoleById(id)
	local role = self.roles[id]
	if role then return role end
	return nil
end

function Server:getRoleByName(name) -- Client:getRoleByName(name)
	for _, role in pairs(self.roles) do
		if role.name == name then
			return role
		end
	end
	return nil
end

function Server:createRole(data)
	request('POST', {endpoints.servers, self.id, 'roles'}, self.client.headers, data)
	-- need to figure out proper data format
end

function Server:createTextChannel(name)
	local body = {name = name, type = 'text'}
	request('POST', {endpoints.servers, self.id, 'channels'}, self.client.headers, body)
end

function Server:createVoiceChannel(name)
	local body = {name = name, type = 'voice'}
	request('POST', {endpoints.servers, self.id, 'channels'}, self.client.headers, body)
end

function Server:getChannelById(id) -- Client:getChannelById(id)
	local channel = self.channels[id]
	if channel then return channel end
	return nil
end

function Server:getChannelByName(name) -- Client:getChannelByName(name)
	for _, channel in pairs(self.channels) do
		if channel.name == name then
			return channel
		end
	end
	return nil
end

function Server:getTextChannelByName(name) -- Client:getTextChannelByName(name)
	for _, channel in pairs(self.channels) do
		if channel.type == 'text' and channel.name == name then
			return channel
		end
	end
	return nil
end

function Server:getVoiceChannelByName(name) -- Client:getVoiceChannelByName(name)
	for _, channel in pairs(self.channels) do
		if channel.type == 'voice' and channel.name == name then
			return channel
		end
	end
	return nil
end

function Server:getMemberById(id) -- Client:getUserById(id)
	local member = self.members[id]
	if member then return member end
	return nil
end

function Server:getMemberByName(name) -- Client:getUserByName(name)
	for _, member in pairs(self.members) do
		if member.username == name then
			return member
		end
	end
	return nil
end

function Server:getMessageById(id) -- Client:getMessageById(id), Channel:getMessageById(id)
	for _, channel in pairs(self.channels) do
		local message = channel.messages[id]
		if message then return message end
	end
	return nil
end

return Server
