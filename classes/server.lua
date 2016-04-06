local Role = require('./role')
local User = require('./user')
local Object = require('./object')
local request = require('../utils').request
local endpoints = require('../endpoints')
local VoiceState = require('./voicestate')
local ServerTextChannel = require('./servertextchannel')
local ServerVoiceChannel = require('./servervoicechannel')

class("Server", Object)

function Server:initialize(data, client)

	Object.initialize(self, data.id, client)

	self.large = data.large -- boolean
	self.joinedAt = data.joinedAt -- string
	self.memberCount = data.memberCount -- number

	if self.large then client.websocket:op8(self.id) end

	self.roles = {}
	self.members = {}
	self.channels = {}
	self.voiceStates = {}

	self:update(data)

	for _, memberData in ipairs(data.members) do
		local user = client:getUserById(memberData.user.id)
		if not user then
			user = User(memberData, self)
			client.users[user.id] = user
		else
			user:update(memberData, self)
		end
		self.members[user.id] = user
	end

	for _, memberData in ipairs(data.presences) do
		local user = self.members[memberData.user.id]
		if user then -- sometimes no user, large servers?
			user:update(memberData, self)
		end
	end

	for _, channelData in ipairs(data.channels) do
		local channel
		if channelData.type == 'text' then
			channel = ServerTextChannel(channelData, self)
		elseif channelData.type == 'voice' then
			channel = ServerVoiceChannel(channelData, self)
		end
		self.channels[channel.id] = channel
	end

	for _, voiceData in ipairs(data.voiceStates) do
		local voiceState = VoiceState(voiceData, self)
		self.voiceStates[voiceState.sessionId] = voiceState
	end

end

function Server:update(data)

	self.name = data.name -- string
	self.icon = data.icon -- string
	self.region = data.regionId -- string
	self.ownerId = data.ownerId -- string
	self.afkTimeout = data.afkTimeout -- number
	self.afkChannelId = data.afkChannelId -- string
	self.embedEnabled = data.embedChannelId-- boolean
	self.embedChannelId = data.embedChannelId -- string
	self.verificationLevel = data.verificationLevel -- number

	self.emojis = data.emojis -- table, not sure what to do with this
	self.features = data.features -- table, not sure what to do with this

	for _, roleData in ipairs(data.roles) do
		local role = Role(roleData, self)
		self.roles[role.id] = role
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
	local data = request('POST', {endpoints.servers, self.id, 'channels'}, self.client.headers, body)
	return ServerTextChannel(data, self) -- not the same object that is cached
end

function Server:createVoiceChannel(name)
	local body = {name = name, type = 'voice'}
	local data = request('POST', {endpoints.servers, self.id, 'channels'}, self.client.headers, body)
	return ServerVoiceChannel(data, self) -- not the same object that is cached
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

function Server:getTextChannelByName(name)
	for _, channel in pairs(self.channels) do
		if channel.type == 'text' and channel.name == name then
			return channel
		end
	end
	return nil
end

function Server:getVoiceChannelByName(name)
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
