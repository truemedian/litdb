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

	self.users = {}
	self.friends = {}
	self.servers = {}
	self.privateChannels = {}

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
			-- p(event)
		end
	end)()

end

-- Invites --

-- function Client:getInvite(code)
	-- return request('POST', {endpoints.invite, code}, self.headers, {})
-- end

-- function Client:acceptInvite(invite) -- Invite:accept()
	-- local body = {validate = invite.code}
	-- return request('POST', {endpoints.channels, invite.channel.id, 'invites'}, self.headers, body)
-- end

-- function Client:deleteInvite(invite) -- Invite:delete()
	-- return request('DELETE', {endpoints.invite, invite.code}, self.headers)
-- end

-- function Client:getChannelInvites(channel) -- Channel:getInvites()
	-- return request('GET', {endpoints.channels, channel.id, 'invites'}, self.headers)
-- end

-- Servers --

function Client:createServer(name, regionId)
	local body = {name = name, region = regionId}
	request('POST', {endpoints.servers}, self.headers, body)
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

function Client:getRegions()
	return request('GET', {endpoints.voice, 'regions'}, self.headers)
end

-- Users --

function Client:getUserById(id)
	return self.users[id]
end

function Client:getUserByName(name)
	for _, user in pairs(self.users) do
		if user.username == name then
			return user
		end
	end
	return nil
end

-- Roles --

function Client:getRoleById(id) -- Server:getRoleById(id)
	for _, server in pairs(self.servers) do
		local role = server.roles[id]
		if role then return role end
	end
	return nil
end

function Client:getRoleByName(name) -- Server:getRoleByName(name)
	for _, server in pairs(self.servers) do
		for _, role in pairs(server.roles) do
			if role.name == name then
				return role
			end
		end
	end
	return nil
end

-- Channels --

function Client:getChannelById(id) -- Server:getChannelById(id)
	local privateChannel = self.privateChannels[id]
	if privateChannel then return privateChannel end
	for _, server in pairs(self.servers) do
		local channel = server.channels[id]
		if channel then return channel end
	end
	return nil
end

function Client:getChannelByName(name) -- Server:getChannelByName(name)
	for _, server in pairs(self.servers) do
		for _, channel in pairs(server.channels) do
			if channel.name == name then
				return channel
			end
		end
	end
	return nil
end

function Client:getTextChannelByName(name) -- Server:getTextChannelByName(name)
	for _, server in pairs(self.servers) do
		for _, channel in pairs(server.channels) do
			if channel.type == 'text' and channel.name == name then
				return channel
			end
		end
	end
	return nil
end

function Client:getVoiceChannelByName(name) -- Server:getVoiceChannelByName(name)
	for _, server in pairs(self.servers) do
		for _, channel in pairs(server.channels) do
			if channel.type == 'voice' and channel.name == name then
				return channel
			end
		end
	end
	return nil
end

function Client:getPrivateChannelByName(name)
	for _, privateChannel in pairs(self.privateChannels) do
		if privateChannel.recipient.username == name then
			return privateChannel
		end
	end
	return nil
end

-- Messages --

function Client:getMessageById(id) -- Server:getMessageById(id), Channel:getMessageById(id)
	for _, server in pairs(self.servers) do
		for _, channel in pairs(server.channels) do
			local message = channel.messages[id]
			if message then return message end
		end
	end
	return nil
end

return Client
