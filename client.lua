local los = require('los')
local md5 = require('md5')
local core = require('core')
local timer = require('timer')
local utils = require('./utils')
local events = require('./events')
local package = require('./package')
local endpoints = require('./endpoints')
local Server = require('./classes/server')
local Websocket = require('./classes/websocket')
local request = utils.request
local camelify = utils.camelify

local Client = core.Emitter:extend()

function Client:initialize(email, password)

	self.users = {}
	self.friends = {}
	self.servers = {}
	self.maxMessages = 100 -- per channel
	self.privateChannels = {}

	self.headers = {
		['Content-Type'] = 'application/json',
		['User-Agent'] = string.format('DiscordBot (%s, %s)', package.homepage, package.version)
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

	local filename = md5.sumhexa(email)
	local cache, token = io.open(filename, 'r')
	if not cache then
		local body = {email = email, password = password}
		token = request('POST', {endpoints.login}, self.headers, body).token
		local cache = io.open(filename, 'w'):write(token):close()
	else
		token = cache:read()
	end

	self.headers['Authorization'] = token
	self.token = token

end

function Client:logout()
	local body = {token = self.token}
	request('POST', {endpoints.logout}, self.headers, body)
end

-- Profile --

function Client:setUsername(newUsername, password)
	local body = {
		avatar = self.user.avatar,
		email = self.user.email,
		username = newUsername,
		password = password
	}
	request('PATCH', {endpoints.me}, self.headers, body)
end

function Client:setAvatar(newAvatar, password)
	local body = {
		avatar = newAvatar, -- base64
		email = self.user.email,
		username = self.user.username,
		password = password
	}
	request('PATCH', {endpoints.me}, self.headers, body)
end

function Client:setEmail(newEmail, password)
	local body = {
		avatar = self.user.avatar,
		email = newEmail,
		username = self.user.username,
		password = password
	}
	request('PATCH', {endpoints.me}, self.headers, body)
end

function Client:setPassword(newPassword, password)
	local body = {
		avatar = self.user.avatar,
		email = self.user.email,
		username = self.user.username,
		password = password,
		new_password = newPassword
	}
	request('PATCH', {endpoints.me}, self.headers, body)
end

-- Websocket --

function Client:getGateway()
	return request('GET', {endpoints.gateway}, self.headers).url
end

function Client:websocketConnect()

	local gateway = self:getGateway()
	self.websocket = Websocket(gateway)
	self.websocket:op2(self.token)

	self:eventHandler()

end

function Client:eventHandler()

	coroutine.wrap(function()
		while true do
			local payload = self.websocket:receive()
			local event = camelify(payload.t)
			local data = camelify(payload.d)
			if not events[event] then error(event) end
			events[event](data, self)
		end
	end)()
	-- need to handle websocket disconnection

end

function Client:keepAliveHandler(interval)

	coroutine.wrap(function(interval)
		while true do
			timer.sleep(interval)
			self.websocket:op1()
		end
	end)(interval)
	-- need to handle websocket disconnection

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
	local data = request('POST', {endpoints.servers}, self.headers, body)
	return Server(data, self) -- not the same object that is cached
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

-- Messages --

function Client:getMessageById(id) -- Server:getMessageById(id), Channel:getMessageById(id)
	for _, server in pairs(self.servers) do
		for _, channel in pairs(server.channels) do
			if channel.type == 'text' then
				local message = channel.messages[id]
				if message then return message end
			end
		end
	end
	return nil
end

return Client
