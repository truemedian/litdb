local Object = require('./object')
local request = require('../utils').request
local endpoints = require('../endpoints')

class('User', Object)

function User:__init(data, client)

	Object.__init(self, data.id, client)

	self.avatar = data.avatar or ''
	self.username = data.username
	self.discriminator = data.discriminator

	-- don't call update, it gets confused

end

function User:ban(server) -- Server:banUser(user)
	-- do they need to be a member?
	request('PUT', {endpoints.servers, server.id, 'bans', self.id}, self.client.headers, {})
end

function User:unban(server) -- Server:unbanUser(user)
	-- what if they are not banned?
	request('DELETE', {endpoints.servers, server.id, 'bans', self.id}, self.client.headers)
end

function User:kick(server) -- Server:kickUser(user)
	request('DELETE', {endpoints.servers, server.id, 'members', self.id}, self.client.headers)
end

function User:update(data)
	self.avatar = data.avatar or ''
	self.username = data.username
	self.discriminator = data.discriminator
end

function User:getAvatarUrl()
	if not self.avatar then return nil end
	return string.format('https://discordapp.com/api/users/%s/avatars/%s.jpg', self.id, self.avatar)
end

return User
