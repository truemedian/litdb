local Object = require('./object')
local request = require('../utils').request
local endpoints = require('../endpoints')

class('User', Object)

function User:initialize(data, parent)

	local user = data.user or data.recipient or data.author
	Object.initialize(self, data.id or user.id, parent.client or parent)

	self.memberData = {}
	self:update(data, parent)

end

function User:update(data, parent)

	local user = data.user or data.recipient or data.author

	self.avatar = data.avatar or user and user.avatar or self.avatar -- or ''
	self.username = data.username or user.username or self.username
	self.discriminator = data.discriminator or user.discriminator

	self.email = data.email or self.email -- client user only
	self.verified = data.verified or self.verified -- client user only

	self.status = data.status or self.status or 'offline'
	self.isFriend = data.type == 1 or self.isFriend
	self.gameName = data.game and data.game.name or self.gameName
	self.lastModified = data.lastModified or self.lastModified

	if data.joinedAt then
		self.memberData[parent.id] = self.memberData[parent.id] or {}
		self.memberData[parent.id].deaf = data.deaf
		self.memberData[parent.id].mute = data.mute
		self.memberData[parent.id].joinedAt = data.joinedAt
	end

	if data.roles then
		self.memberData[parent.id] = self.memberData[parent.id] or {}
		self.memberData[parent.id].roles = data.roles
	end

end

function User:getAvatarUrl()
	if not self.avatar then return nil end
	return string.format('https://discordapp.com/api/users/%s/avatars/%s.jpg', self.id, self.avatar)
end

function User:getServers() -- rather than save servers per user
	if not self.isMember then return end
	local servers = {}
	for id in pairs(self.memberData) do
		servers[id] = self.client:getServerById(id)
	end
	return servers
end

function User:getMessages() -- rather than save messages per user
	if not self.isAuthor then return end
	local servers = self:getServers()
	local messages = {}
	for _, server in pairs(servers) do
		for _, channel in pairs(server.channels) do
			for _, message in pairs(channel.messages) do
				if message.author.id == self.id then
					messages[message.id] = message
				end
			end
		end
	end
	return messages
end

return User
