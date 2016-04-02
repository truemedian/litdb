local timer = require('timer')

local User = require('./classes/user')
local Server = require('./classes/server')
local Channel = require('./classes/channel')
local Message = require('./classes/message')
local VoiceState = require('./classes/voicestate')
local PrivateChannel = require('./classes/privatechannel')

local events = {}

function events.ready(client, data)

	client.user = User:new(data.user, client) -- object
	client.sessionId = data.sessionId -- string
	client.heartbeatInterval = data.heartbeatInterval -- number

	for _, friendData in ipairs(data.relationships) do
		local user = client:getUserById(friendData.user.id)
		if not user then
			user = User:new(friendData, client)
			client.users[user.id] = user
		else
			user:update(friendData)
		end
		client.friends[user.id] = user
	end

	for _, friendData in ipairs(data.presences) do
		local user = client:getUserById(friendData.user.id)
		user:update(friendData)
	end

	for _, serverData in ipairs(data.guilds) do
		local server = Server:new(serverData, client)
		client.servers[server.id] = server
	end

	for _, privateChannelData in ipairs(data.privateChannels) do
		local privateChannel = PrivateChannel:new(privateChannelData, client)
		client.privateChannels[privateChannel.id] = privateChannel
	end

	-- client.readState = data.readState -- table, status in each channel
	-- client.userServerSettings = data.userGuildSettings -- table, settings per server
	-- client.userSettings = data.userSettings -- table, personal user settings

	coroutine.wrap(function()
		while true do
			timer.sleep(client.heartbeatInterval)
			client.ws:send({op = 1, d = os.time()})
		end
	end)()

	client:emit('ready')

end


function events.typingStart(client, data)

	local channel = client:getChannelById(data.channelId)
	local user = client:getUserById(data.userId)
	client:emit('typingStart', channel, user)

end

function events.presenceUpdate(client, data)

	local user = client:getUserById(data.user.id)

	if not user then
		local server = client:getServerById(data.guildId)
		user = User:new(data, server)
		-- client.users[user.id] = user
		-- server.members[user.id] = user
		-- don't want to save User because username is nil
	else
		user:update(data)
	end

	client:emit('presenceUpdate', user)

end

function events.userSettingsUpdate(client, data)
	-- client:emit('userSettingsUpdate', data)
end

function events.voiceStateUpdate(client, data)

	local server = client:getServerById(data.guildId)
	local voiceState = server.voiceStates[data.sessionId]

	if not voiceState then
		voiceState = VoiceState:new(data)
		server.voiceStates[voiceState.sessionId] = voiceState
		client:emit('voiceJoin', voiceState)
	elseif voiceState.channelId then
		voiceState:update(data)
		client:emit('voiceUpdate', voiceState)
	else
		server.voiceStates[voiceState.sessionId] = nil
		client:emit('voiceLeave', voiceState)
	end

end

function events.messageCreate(client, data)

	local channel = client:getChannelById(data.channelId)
	local message = Message:new(data, channel)
	channel.messages[message.id] = message
	client:emit('messageCreate', message)

end

function events.messageDelete(client, data)

	local message = client:getMessageById(data.id)
	if message then message.channel.messages[message.id] = nil end
	client:emit('messageDelete', message)

end

function events.messageUpdate(client, data)

	local message = channel:getMessageById(data.id)

	if not message then
		local channel = client:getChannelById(data.channelId)
		message = Message:new(data, channel)
		channel.messages[message.id] = message
	else
		message:update(data)
	end

	client:emit('messageUpdate', message)

end

function events.messageAck(client, data)

	local channel = client:getChannelById(data.channelId)
	local message = channel:getMessageById(data.messageId)
	client:emit('messageAcknowledge', channel, message)

end

function events.channelCreate(client, data)

	local server = client:getServerById(data.guildId)

	if data.isPrivate then
		local privateChannel = PrivateChannel:new(data, client)
		client.privateChannels[privateChannel.id] = privateChannel
		client:emit('channelCreate', privateChannel)
	else
		local channel = Channel:new(data, server)
		server.channels[channel.id] = channel
		client:emit('channelCreate', channel)
	end

end

function events.channelDelete(client, data)

	local server = client:getServerById(data.guildId)
	local channel = server:getChannelById(data.id)
	server.channels[channel.id] = nil
	client:emit('channelDelete', channel)

end

function events.channelUpdate(client, data)

	local server = client:getServerById(data.guildId)
	local channel = client:getChannelById(data.guildId)

	if not channel then
		channel = Channel:new(data, server)
		server.channels[channel.id] = channel
	else
		channel:update(data)
	end

	client:emit('channelUpdate', channel)

end

function events.guildBanAdd(client, data)
end

function events.guildBanRemove(client, data)
end

function events.guildCreate(client, data)
end

function events.guildDelete(client, data)
end

function events.guildUpdate(client, data)
end

function events.guildIntegrationsUpdate(client, data)
end

function events.guildMemberAdd(client, data)
end

function events.guildMemberRemove(client, data)
end

function events.guildMemberUpdate(client, data)
end

function events.guildRoleCreate(client, data)
end

function events.guildRoleDelete(client, data)
end

function events.guildRoleUpdate(client, data)
end

return events
