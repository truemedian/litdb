local los = require('los')
local core = require('core')

local utils = require('./utils')
local events = require('./events')
local endpoints = require('./endpoints')

local Websocket = require('./classes/websocket')

local request = utils.request
local camelify = utils.camelify

local Client = core.Emitter:extend()

function Client:initialize(email, password)

	self.headers = {
		['Content-Type'] = 'application/json',
		['User-Agent'] = 'Luvit Discord API'
	}

end

function Client:run(email, password)
	coroutine.wrap(function()
		self:login(email, password)
		self:websocketConnect()
	end)()
end

-- Authentication --

function Client:login(email, password)
	local body = {email = email, password = password}
	local token = request('POST', {endpoints.login}, self.headers, body).token
	self.headers['Authorization'] = token
	self.token = token
end

function Client:getUser() -- self.user
	return request('GET', {endpoints.me}, self.headers)
end

function Client:logout()
	local body = {token = self.token}
	return request('POST', {endpoints.logout}, self.headers, body)
end

-- Websocket --

function Client:getGateway()
	return request('GET', {endpoints.gateway}, self.headers).url
end

function Client:websocketConnect()

	local gateway = self:getGateway()
	self.ws = Websocket:new(gateway)
	
	self.ws:send({
		op = 2,
		d = {
			token = self.token,
			v = 3,
			properties = {
				['$os'] = los.type(),
				['$browser'] = 'discord',
				['$device'] = 'discord',
				['$referrer'] = '',
				['$referring_domain'] = ''
			},
			large_threadhold = 100,
			compress = false
		}
	})

	coroutine.wrap(function()
		while true do
			local payload = self.ws:receive()
			local event = camelify(payload.t)
			local data = camelify(payload.d)
			events[event](self, data)
		end
	end)()

end

-- Invites --

function Client:getInvite(code)
	return request('POST', {endpoints.invite, code}, self.headers, {})
end

function Client:acceptInvite(invite)
	local body = {validate = invite.code}
	return request('POST', {endpoints.channels, invite.channel.id, 'invites'}, self.headers, body)
end

function Client:acceptInviteByCode(code)
	local invite = self:getInvite(code)
	return self:acceptInvite(invite)
end

function Client:deleteInvite(invite)
	return request('DELETE', {endpoints.invite, invite.code}, self.headers)
end

function Client:getServerInvites(server)
	return request('GET', {endpoints.servers, server.id, 'invites'}, self.headers)
end

function Client:getChannelInvites(channel)
	return request('GET', {endpoints.channels, channel.id, 'invites'}, self.headers)
end

-- Servers --

function Client:createServer(name, regionId)
	local body = {name = name, region = regionId}
	return request('POST', {endpoints.servers}, self.headers, body)
end

function Client:getServers() -- self.servers
	return request('GET', {endpoints.me, 'guilds'}, self.headers)
end

function Client:getServerById(id)
	return self.servers[id]
end

function Client:getServerByName(name)
	for _, server in pairs(self.servers) do
		if server.name == name then
			return server
		end
	end
	return nil
end

function Client:setServerName(server, name)
	local body = {name = name}
	return request('PATCH', {endpoints.servers, server.id}, self.headers, body)
end

function Client:setServerRegion(server, regionId)
	local body = {name = server.name, region = regionId}
	return request('PATCH', {endpoints.servers, server.id}, self.headers, body)
end

function Client:leaveServer(server)
	return request('DELETE', {endpoints.me, 'guilds', server.id}, self.headers)
end

function Client:deleteServer(server)
	return request('DELETE', {endpoints.servers, server.id}, self.headers)
end

function Client:getBans(server)
	return request('GET', {endpoints.servers, server.id, 'bans'}, self.headers)
end

function Client:addBan(server, user) -- banUser?
	return request('PUT', {endpoints.servers, server.id, 'bans', user.id}, self.headers, {})
end

function Client:removeBan(server, user) -- unbanUser?
	return request('DELETE', {endpoints.servers, server.id, 'bans', user.id}, self.headers)
end

function Client:kickUser(server, user)
	return request('DELETE', {endpoints.servers, server.id, 'members', user.id}, self.headers)
end

-- Roles --

function Client:getRoles(server) -- server.roles
	return request('GET', {endpoints.servers, server.id, 'roles'}, self.headers)
end

function Client:getRoleById(id)
	for _, server in pairs(self.servers) do
		local role = server.roles[id]
		if role then return role end
	end
	return nil
end

function Client:getRoleByName(name)
	for _, server in pairs(self.servers) do
		for _, role in pairs(server.roles) do
			if role.name == name then
				return role
			end
		end
	end
	return nil
end

function Client:createRole(server, data)
	return request('POST', {endpoints.servers, server.id, 'roles'}, self.headers, data)
end

function Client:updateRole(server, role, data) -- split into set methods
	return request('PATCH', {endpoints.servers, server.id, 'roles', role.id}, self.headers, data)
end

function Client:moveRoleUp(role)
	-- need to re-write
	return request('PATCH', {endpoints.servers, server.id, 'roles'}, self.headers, roles)
end

function Client:moveRoleDown(role)
	-- need to re-write
	return request('PATCH', {endpoints.servers, server.id, 'roles'}, self.headers, roles)
end

-- Channels --

function Client:createTextChannel(server, name)
	local body = {name = name, type = 'text'}
	return request('POST', {endpoints.servers, server.id, 'channels'}, self.headers, body)
end

function Client:createVoiceChannel(server, name)
	local body = {name = name, type = 'voice'}
	return request('POST', {endpoints.servers, server.id, 'channels'}, self.headers, body)
end

function Client:getChannels(server) -- server.channels
	return request('GET', {endpoints.servers, server.id, 'channels'}, self.headers)
end

function Client:getChannelById(id)
	for _, server in pairs(self.servers) do
		local channel = server.channels[id]
		if channel then return channel end
	end
	return nil
end

function Client:getTextChannelByName(name) -- add option server arg
	for _, server in pairs(self.servers) do
		for _, channel in pairs(server.channels) do
			if channel.type == 'text' and channel.name == name then
				return channel
			end
		end
	end
	return nil
end

function Client:getVoiceChannelByName(name) -- add optional server arg
	for _, server in pairs(self.servers) do
		for _, channel in pairs(server.channels) do
			if channel.type == 'voice' and channel.name == name then
				return channel
			end
		end
	end
	return nil
end

function Client:setChannelName(channel, name)
	local body = {name = name, position = channel.position, topic = channel.topic}
	return request('PATCH', {endpoints.channels, channel.id}, self.headers, body)
end

function Client:setChannelTopic(channel, topic)
	local body = {name = channel.name, position = channel.position, topic = topic}
	return request('PATCH', {endpoints.channels, channel.id}, self.headers, body)
end

function Client:setChannelPosition(channel, position) -- move channel up/down?
	local body = {name = channel.name, position = position, topic = topic}
	return request('PATCH', {endpoints.channels, channel.id}, self.headers, body)
end

function Client:deleteChannel(channel)
	return request('DELETE', {endpoints.channels, channel.id}, self.headers)
end

function Client:broadcastTyping(channel)
	return request('POST', {endpoints.channels, channel.id, 'typing'}, self.headers, {})
end

-- Messages --

function Client:getMessages(channel) -- channel.messages
	return request('GET', {endpoints.channels, channel.id, 'messages'}, self.headers)
end

function Client:sendMessage(channel, content)
	local body = {content = content}
	return request('POST', {endpoints.channels, channel.id, 'messages'}, self.headers, body)
end

function Client:setMessage(message, content)
	local body = {content = content}
	return request('PATCH', {endpoints.channels, message.channel_id, 'messages', message.id}, self.headers, body)
end

function Client:deleteMessage(message)
	return request('DELETE', {endpoints.channels, message.channel_id, 'messages', message.id}, self.headers)
end

function Client:acknowledgeMessage(message)
	return request('POST', {endpoints.channels, message.channel_id, 'messages', message.id, 'ack'}, self.headers, {})
end

-- Voice --

function Client:getServerRegions()
	return request('GET', {endpoints.voice, 'regions'}, self.headers)
end

function Client:moveVoiceUser(user, channel)
	local body = {channel_id = channel.id}
	return request('PATCH', {endpoints.servers, channel.guild_id, 'members', user.id}, self.headers, body)
end

return Client
