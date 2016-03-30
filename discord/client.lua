local los = require('los')
local core = require('core')
local timer = require('timer')

local utils = require('./utils')
local events = require('./events')
local endpoints = require('./endpoints')

local User = require('./classes/user')
local Server = require('./classes/server')
local Friend = require('./classes/friend')
local Websocket = require('./classes/websocket')

local request = utils.request
local camelify = utils.camelify

local Client = core.Emitter:extend()

function Client:initialize(email, password)

	self.user = nil
	self.servers = {}
	self.friends = {}

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
			assert(payload and payload.op == 0)
			self:websocketEvent(payload)
		end
	end)()

end

function Client:websocketEvent(payload)

	local event = camelify(payload.t)
	local data = camelify(payload.d)
	
	if event == 'ready' then
		
		self.user = User:new(data.user) -- table -> object
		self.sessionId = data.sessionId -- string
		self.heartbeatInterval = data.heartbeatInterval -- number
		
		for _, serverData in ipairs(data.guilds) do
			local server = Server:new(serverData)
			self.servers[server.id] = server
		end
		
		for _, friendData in ipairs(data.relationships) do
			local friend = Friend:new(friendData)
			self.friends[friend.id] = friend
		end
		
		for _, friendData in ipairs(data.presences) do
			local friend = self.friends[friendData.user.id]
			friend:update(friendData)
		end
		
		-- self.readState = data.readState -- table, status in each channel
		-- self.privateChannels = data.privateChannels -- table, direct messages
		-- self.userGuildSettings = data.userGuildSettings -- table, settings per server
		-- self.userSettings = data.userSettings -- table, personal user settings

		coroutine.wrap(function()
			while true do
				timer.sleep(self.heartbeatInterval)
				self.ws:send({op = 1, d = os.time()})
			end
		end)()
	
	end
	
	self:emit(camelify(event))

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

function Client:getServerById(id) -- self.servers[id]
	local servers = self:getServers()
	for _, v in ipairs(servers) do
		if v.id == id then
			return v
		end
	end
	return nil
end

function Client:getServerByName(name)
	local servers = self:getServers()
	for _, v in ipairs(servers) do
		if v.name == name then
			return v
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

function Client:getRoles(server) -- self.servers[server.id].roles
	return request('GET', {endpoints.servers, server.id, 'roles'}, self.headers)
end

function Client:getRoleByName(server, name)
	local roles = self:getRoles(server)
	for _, v in ipairs(roles) do
		if v.name == name then
			return v
		end
	end
	return nil
end

function Client:getRoleById(server, id) -- self.servers[server.id].roles[id]
	local roles = self:getRoles(server)
	for _, v in ipairs(roles) do
		if v.id == id then
			return v
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

function Client:moveRoleUp(server, role)
	assert(role.name ~= '@everyone', 'Cannot move role @everyone')
	local roles = self:getRoles(server)
	table.sort(roles, function(a, b) return a.position > b.position end)
	for i, v in ipairs(roles) do
		if v.id == role.id then
			if i > 1 then
				roles[i].position = v.position + 1
				roles[i - 1].position = v.position - 1
			end
			break
		end
	end
	return request('PATCH', {endpoints.servers, server.id, 'roles'}, self.headers, roles)
end

function Client:moveRoleDown(server, role)
	assert(role.name ~= '@everyone', 'Cannot move role @everyone')
	local roles = self:getRoles(server)
	table.sort(roles, function(a, b) return a.position > b.position end)
	for i, v in ipairs(roles) do
		if v.id == role.id then
			if i < #roles - 1 then
				roles[i].position = v.position - 1
				roles[i + 1].position = v.position + 1
			end
			break
		end
	end
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

function Client:getChannels(server) -- self.servers[server.id].channels
	return request('GET', {endpoints.servers, server.id, 'channels'}, self.headers)
end

function Client:getChannelById(server, id) -- self.servers[server.id].channels[id] or self.channels[id]; server object necessary?
	local channels = self:getChannels(server)
	for _, v in ipairs(channels) do
		if v.id == id then
			return v
		end
	end
	return nil
end

function Client:getTextChannelByName(server, name) -- server object not necessary if cache is used and if multiple names are avoided
	local channels = self:getChannels(server)
	for _, v in ipairs(channels) do
		if v.type == 'text' and v.name == name then
			return v
		end
	end
	return nil
end

function Client:getVoiceChannelByName(server, name)
	local channels = self:getChannels(server)
	for _, v in ipairs(channels) do
		if v.type == 'voice' and v.name == name then
			return v
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

function Client:getMessages(channel) -- self.channels
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
